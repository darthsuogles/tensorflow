load(
    "//tools:rules.bzl",
    "tf_cc_binary",
    "tf_cc_shared_object",
)

config_setting(
    name = "aarch64",
    values = {
        "cpu": "aarch64",
    },
    visibility = ["//visibility:public"],
)

config_setting(
    name = "k8",
    values = {
        "cpu": "k8",
    },
    visibility = ["//visibility:public"],
)

config_setting(
    name = "x86_64",
    values = {
        "cpu": "k8",
    },
    visibility = ["//visibility:public"],
)

alias(
    name = "cuda_headers",
    actual = "@local_config_cuda//cuda:cuda_headers",
)

cc_library(
    name = "salut_lib",
    srcs = ["salut_lib.cc"],
    deps = [
        ":cuda_headers",
    ],
)

cc_binary(
    name = "salut_platform_depedent",
    srcs = ["salut.cc"],
    deps = [
        ":cuda_headers",
        "@local_config_cuda//cuda",
    ] + select({
        "aarch64": ["//src/platform:aarch64"],
        "//conditions:default": ["//src/platform:x86_64"],
    }),
)

cc_binary(
    name = "hw_cublas",
    srcs = ["hw_cublas.cc"],
    deps = [
        ":cuda_headers",
        "@local_config_cuda//cuda",
    ],
)

genrule(
    name = "inspect",
    srcs = [
        "@local_config_platform//empty:secret",
    ],
    outs = ["show_secret_words"],
    cmd = "cat $(location @local_config_platform//empty:secret) | tee $(@)",
)
