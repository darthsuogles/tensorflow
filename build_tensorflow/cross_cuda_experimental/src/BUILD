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

cc_library(
    name = "salut_lib",
    srcs = ["salut_lib.cc"],
    deps = [
        "@local_config_cuda//cuda:cuda_headers",
    ],
)

cc_binary(
    name = "salut",
    srcs = ["salut.cc"],
    data = [
        "@local_config_platform//empty:secret",
    ],
    deps = [
        "@local_config_cuda//cuda:cuda_headers",
    ],
)

cc_binary(
    name = "salut_platform_depedent",
    srcs = ["salut.cc"],
    deps = select({
        "aarch64": ["//src/platform:aarch64"],
        "//conditions:default": ["//src/platform:x86_64"],
    }),
)

genrule(
    name = "inspect",
    srcs = [
        "@local_config_platform//empty:secret",
    ],
    outs = ["show_secret_words"],
    cmd = "cat $(location @local_config_platform//empty:secret) | tee $(@)",
)
