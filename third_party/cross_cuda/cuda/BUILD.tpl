licenses(["restricted"])  # MPL2, portions GPL v3, LGPL v3, BSD-like

package(default_visibility = ["//visibility:public"])

load(":build_defs.bzl", "gen_cuda_alias")

config_setting(
    name = "using_nvcc",
    values = {
        "define": "using_cuda_nvcc=true",
    },
)

config_setting(
    name = "using_clang",
    values = {
        "define": "using_cuda_clang=true",
    },
)

# Equivalent to using_clang && -c opt.
config_setting(
    name = "using_clang_opt",
    values = {
        "define": "using_cuda_clang=true",
        "compilation_mode": "opt",
    },
)

config_setting(
    name = "darwin",
    values = {"cpu": "darwin"},
    visibility = ["//visibility:public"],
)

config_setting(
    name = "freebsd",
    values = {"cpu": "freebsd"},
    visibility = ["//visibility:public"],
)

config_setting(
    name = "aarch64",
    values = {
        "cpu": "aarch64",
    },
    visibility = ["//visibility:public"],
)

gen_cuda_alias()
