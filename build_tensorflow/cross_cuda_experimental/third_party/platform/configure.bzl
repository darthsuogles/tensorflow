load(
    "@bazel_tools//tools/cpp:lib_cc_configure.bzl",
    "get_cpu_value",
    "resolve_labels",
)

_RESTART_ENV = "PLATFORM_RESTART_FLAG"

_TF_CROSS_COMPILATION = "TF_CROSS_COMPILATION"

_CROSS_NVCC_HOST_COMPILER_PATH = "CROSS_NVCC_HOST_COMPILER_PATH"

_CROSS_NVCC_TARGET_COMPILER_PATH = "CROSS_NVCC_TARGET_COMPILER_PATH"

def _platform_autoconf_impl(repository_ctx):
    print("ctx.os.name", repository_ctx.os.name)
    print("ctx.attr", repository_ctx.attr)

    # This rule gives the host platform's CPU information
    # https://github.com/bazelbuild/bazel/blob/master/tools/cpp/lib_cc_configure.bzl#L177
    print("cpu value:", get_cpu_value(repository_ctx))

    repository_ctx.file("empty/BUILD", """
genrule(name = "secret",
        cmd = "echo amisabc > $(@)",
        outs = ["words"],
        visibility = ["//visibility:public"])
""")

platform_configure = repository_rule(
    environ = [
        _TF_CROSS_COMPILATION,
        _CROSS_NVCC_HOST_COMPILER_PATH,
        _CROSS_NVCC_TARGET_COMPILER_PATH,
        _RESTART_ENV,
    ],
    implementation = _platform_autoconf_impl,
)
