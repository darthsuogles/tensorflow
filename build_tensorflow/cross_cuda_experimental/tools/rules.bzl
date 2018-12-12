# -*- python -*-

load(
    "@local_config_cuda//cuda:build_defs.bzl",
    "cuda_default_copts",
    "if_cuda",
    "if_cuda_is_configured",
)

def register_extension_info(**kwargs):
    pass


def _make_search_paths(prefix, levels_to_root):
    return ",".join(
        [
            "-rpath,%s/%s" % (prefix, "/".join([".."] * search_level))
            for search_level in range(levels_to_root + 1)
        ],
    )

def _rpath_linkopts(name):
    # Search parent directories up to the TensorFlow root directory for shared
    # object dependencies, even if this op shared object is deeply nested
    # (e.g. tensorflow/contrib/package:python/ops/_op_lib.so). tensorflow/ is then
    # the root and tensorflow/libtensorflow_framework.so should exist when
    # deployed. Other shared object dependencies (e.g. shared between contrib/
    # ops) are picked up as long as they are in either the same or a parent
    # directory in the tensorflow/ tree.
    levels_to_root = native.package_name().count("/") + name.count("/")
    return [
        "-Wl,%s" % _make_search_paths("$$ORIGIN", levels_to_root),
    ]

def _linux_kernel_dso_name(kernel_build_target):
    """Given a build target, construct the dso name for linux."""
    parts = kernel_build_target.split(":")
    return "%s:libtfkernel_%s.so" % (parts[0], parts[1])

def if_dynamic_kernels(extra_deps, otherwise = []):
    return extra_deps

# Helper functions to add kernel dependencies to tf binaries when using dynamic
# kernel linking.
def tf_binary_dynamic_kernel_dsos(kernels):
    return if_dynamic_kernels(
        extra_deps = [_linux_kernel_dso_name(k) for k in kernels],
        otherwise = [],
    )

# Helper functions to add kernel dependencies to tf binaries when using static
# kernel linking.
def tf_binary_dynamic_kernel_deps(kernels):
    return if_dynamic_kernels(
        extra_deps = [],
        otherwise = kernels,
    )

def tf_binary_additional_srcs():
    return []

# LINT.IfChange
def tf_copts(android_optimization_level_override = "-O2", is_external = False):
    return (
        [
            "-DEIGEN_AVOID_STL_ARRAY",
            "-Iexternal/gemmlowp",
            "-Wno-sign-compare",
            "-fno-exceptions",
            "-ftemplate-depth=900",
        ] + [
            "-msse3"
        ] + [
            "-DTENSORFLOW_MONOLITHIC_BUILD"
        ] + [
            "-pthread"
        ]
    )


def tf_cc_shared_object(
        name,
        srcs = [],
        deps = [],
        data = [],
        linkopts = [],
        framework_so = tf_binary_additional_srcs(),
        kernels = [],
        **kwargs):
    native.cc_binary(
        name = name,
        srcs = srcs + framework_so,
        deps = deps + tf_binary_dynamic_kernel_deps(kernels),
        linkshared = 1,
        data = data + tf_binary_dynamic_kernel_dsos(kernels),
        linkopts = linkopts + _rpath_linkopts(name) + [
            "-Wl,-soname," + name.split("/")[-1],
        ],
        **kwargs
    )

register_extension_info(
    extension_name = "tf_cc_shared_object",
    label_regex_for_dep = "{extension_name}",
)

def tf_cc_binary(
        name,
        srcs = [],
        deps = [],
        data = [],
        linkopts = [],
        copts = tf_copts(),
        kernels = [],
        **kwargs):
    native.cc_binary(
        name = name,
        copts = copts,
        srcs = srcs + tf_binary_additional_srcs(),
        deps = deps + tf_binary_dynamic_kernel_deps(kernels),
        data = data + tf_binary_dynamic_kernel_dsos(kernels),
        linkopts = linkopts + _rpath_linkopts(name),
        **kwargs
    )

register_extension_info(
    extension_name = "tf_cc_binary",
    label_regex_for_dep = "{extension_name}.*",
)
