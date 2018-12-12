licenses(["restricted"])  # MPL2, portions GPL v3, LGPL v3, BSD-like

package(default_visibility = ["//visibility:public"])

config_setting(
    name = "aarch64",
    values = {
        "cpu": "aarch64",
    },
    visibility = ["//visibility:public"],
)

alias(
    name = "cuda",
    actual = select({
        "aarch64": "//aarch64/cuda:cuda",
        "//conditions:default": "//x86_64/cuda:cuda",
    }),
)

alias(
    name = "cuda_headers",
    actual = select({
        "aarch64": "//aarch64/cuda:cuda_headers",
        "//conditions:default": "//x86_64/cuda:cuda_headers",
    }),
)

# cc_library(
#     name = "cupti_headers",
#     hdrs = [
#         "cuda/cuda_config.h",
#         ":cuda-extras",
#     ],
#     includes = [
#         ".",
#         "cuda/extras/CUPTI/include/",
#     ],
#     visibility = ["//visibility:public"],
# )

# cc_library(
#     name = "cupti_dsos",
#     data = select({
#         ":aarch64": [
#             "aarch64/cuda/lib/%{cupti_lib}",
#         ],
#         "//conditions:default": ["x86_64/cuda/lib/%{cupti_lib}"],
#     }),
#     includes = [
#         ".",
#         "cuda/include",
#     ],
#     visibility = ["//visibility:public"],
# )

# cc_library(
#     name = "libdevice_root",
#     data = [":cuda-nvvm"],
#     visibility = ["//visibility:public"],
# )

# %{cuda_include_genrules}
