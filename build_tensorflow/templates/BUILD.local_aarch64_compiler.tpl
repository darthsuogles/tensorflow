package(default_visibility = ["//visibility:public"])

filegroup(
    name = "gcc",
    srcs = [
        "bin/$CROSSTOOL_NAME-gcc",
    ],
)

filegroup(
    name = "ar",
    srcs = [
        "bin/$CROSSTOOL_NAME-ar",
    ],
)

filegroup(
    name = "ld",
    srcs = [
        "bin/$CROSSTOOL_NAME-ld",
    ],
)

filegroup(
    name = "nm",
    srcs = [
        "bin/$CROSSTOOL_NAME-nm",
    ],
)

filegroup(
    name = "objcopy",
    srcs = [
        "bin/$CROSSTOOL_NAME-objcopy",
    ],
)

filegroup(
    name = "objdump",
    srcs = [
        "bin/$CROSSTOOL_NAME-objdump",
    ],
)

filegroup(
    name = "strip",
    srcs = [
        "bin/$CROSSTOOL_NAME-strip",
    ],
)

filegroup(
    name = "as",
    srcs = [
        "bin/$CROSSTOOL_NAME-as",
    ],
)

filegroup(
    name = "compiler_pieces",
    srcs = glob([
        "$CROSSTOOL_NAME/**",
        "libexec/**",
        "lib/gcc/$CROSSTOOL_NAME/**",
        "include/**",
    ]),
)

filegroup(
    name = "compiler_components",
    srcs = [
        ":ar",
        ":as",
        ":gcc",
        ":ld",
        ":nm",
        ":objcopy",
        ":objdump",
        ":strip",
    ],
)
