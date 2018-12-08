licenses(["notice"])  # 3-Clause BSD

config_setting(
    name = "build_with_mkl",
    define_values = {
        "build_with_mkl": "true",
    },
    visibility = ["//visibility:public"],
)

config_setting(
    name = "build_with_mkl_ml_only",
    define_values = {
        "build_with_mkl": "true",
        "build_with_mkl_ml_only": "true",
    },
    visibility = ["//visibility:public"],
)

config_setting(
    name = "build_with_mkl_lnx_x64",
    define_values = {
        "build_with_mkl": "true",
    },
    values = {
        "cpu": "k8",
    },
    visibility = ["//visibility:public"],
)

config_setting(
    name = "enable_mkl",
    define_values = {
        "enable_mkl": "true",
        "build_with_mkl": "true",
    },
    visibility = ["//visibility:public"],
)

load(
    "//third_party/mkl:build_defs.bzl",
    "if_mkl",
)

filegroup(
    name = "LICENSE",
    srcs = ["MKL_LICENSE"] + select({
        "@tfx_experimental//tensorflow:linux_x86_64": [
            "@mkl_linux//:LICENSE",
        ],
        "//conditions:default": [],
    }),
    visibility = ["//visibility:public"],
)

cc_library(
    name = "intel_binary_blob",
    visibility = ["//visibility:public"],
    deps = select({
        "@tfx_experimental//tensorflow:linux_x86_64": [
            "@mkl_linux//:mkl_headers",
            "@mkl_linux//:mkl_libs_linux",
        ],
        "//conditions:default": [],
    }),
)
