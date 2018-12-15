licenses(["restricted"])

package(default_visibility = ["//visibility:public"])

toolchain(
    name = "toolchain-linux-x86_64",
    exec_compatible_with = [
        "@bazel_tools//platforms:linux",
        "@bazel_tools//platforms:x86_64",
    ],
    target_compatible_with = [
        "@bazel_tools//platforms:linux",
        "@bazel_tools//platforms:x86_64",
    ],
    toolchain = ":cc-compiler-local",
    toolchain_type = "@bazel_tools//tools/cpp:toolchain_type",
)

toolchain(
    name = "toolchain-linux-aarch64",
    exec_compatible_with = [
        "@bazel_tools//platforms:linux",
        "@bazel_tools//platforms:aarch64",
    ],
    target_compatible_with = [
        "@bazel_tools//platforms:linux",
        "@bazel_tools//platforms:aarch64",
    ],
    toolchain = ":cc-compiler-aarch64",
    toolchain_type = "@bazel_tools//tools/cpp:toolchain_type",
)

cc_toolchain_suite(
    name = "toolchain",
    toolchains = {
        "local|compiler": ":cc-compiler-local",
        "aarch64|compiler": ":cc-compiler-aarch64",
    },
)

cc_toolchain(
    name = "cc-compiler-local",
    all_files = "%{cross_nvcc_host_linker_files}",
    compiler_files = ":empty",
    cpu = "local",
    dwp_files = ":empty",
    dynamic_runtime_libs = [":empty"],
    linker_files = "%{cross_nvcc_host_linker_files}",
    objcopy_files = ":empty",
    static_runtime_libs = [":empty"],
    strip_files = ":empty",
    # To support linker flags that need to go to the start of command line
    # we need the toolchain to support parameter files. Parameter files are
    # last on the command line and contain all shared libraries to link, so all
    # regular options will be left of them.
    supports_param_files = 1,
)

cc_toolchain(
    name = "cc-compiler-aarch64",
    all_files = "%{cross_nvcc_target_linker_files}",
    compiler_files = ":empty",
    cpu = "aarch64",
    dwp_files = ":empty",
    dynamic_runtime_libs = [":empty"],
    linker_files = "%{cross_nvcc_target_linker_files}",
    objcopy_files = ":empty",
    static_runtime_libs = [":empty"],
    strip_files = ":empty",
    supports_param_files = 1,
)

cc_toolchain(
    name = "cc-compiler-darwin",
    all_files = "%{cross_nvcc_host_linker_files}",
    compiler_files = ":empty",
    cpu = "darwin",
    dwp_files = ":empty",
    dynamic_runtime_libs = [":empty"],
    linker_files = "%{cross_nvcc_host_linker_files}",
    objcopy_files = ":empty",
    static_runtime_libs = [":empty"],
    strip_files = ":empty",
    supports_param_files = 0,
)

cc_toolchain(
    name = "cc-compiler-windows",
    all_files = "%{win_linker_files}",
    compiler_files = ":empty",
    cpu = "x64_windows",
    dwp_files = ":empty",
    dynamic_runtime_libs = [":empty"],
    linker_files = "%{win_linker_files}",
    objcopy_files = ":empty",
    static_runtime_libs = [":empty"],
    strip_files = ":empty",
    supports_param_files = 1,
)

filegroup(
    name = "empty",
    srcs = [],
)

filegroup(
    name = "linaro_linux_all_files",
    srcs = [
        "@local_arm_compiler//:compiler_pieces",
    ],
)

filegroup(
    name = "crosstool_host_wrapper_driver_is_not_gcc",
    srcs = [
        "clang/bin/crosstool_host_wrapper_driver_is_not_gcc",
    ],
)

filegroup(
    name = "crosstool_target_wrapper_driver_is_not_gcc",
    srcs = [
        "clang/bin/crosstool_target_wrapper_driver_is_not_gcc",
    ],
)
