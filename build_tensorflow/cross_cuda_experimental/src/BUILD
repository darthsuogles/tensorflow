load(
    "//tools:rules.bzl",
    "tf_cc_binary",
    "tf_cc_shared_object",
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

genrule(
    name = "inspect",
    srcs = [
        "@local_config_platform//empty:secret",
    ],
    outs = ["show_secret_words"],
    cmd = "cat $(location @local_config_platform//empty:secret) | tee $(@)",
)
