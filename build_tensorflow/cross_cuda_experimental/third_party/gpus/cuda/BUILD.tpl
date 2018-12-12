licenses(["restricted"])  # MPL2, portions GPL v3, LGPL v3, BSD-like

package(default_visibility = ["//visibility:public"])

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
    name = "aarch64",
    values = {
        "cpu": "aarch64"
    },
    visibility = ["//visibility:public"],
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

cc_library(
    name = "cuda_headers",
    hdrs = [
        "cuda/cuda_config.h",
        %{cuda_headers}
    ],
    includes = [
        ".",
        "cuda/include",
        "cuda/include/crt",
    ],
    visibility = ["//visibility:public"],
)

cc_library(
    name = "cudart_static",
    srcs = select({
        ":aarch64": [
            "aarch64/cuda/lib/%{cudart_static_lib}",
        ],
        "//conditions:default": ["x86_64/cuda/lib/%{cudart_static_lib}"],
    }),
    includes = [
        ".",
        "cuda/include",
    ],
    linkopts = select({
        ":freebsd": [],
        "//conditions:default": ["-ldl"],
    }) + [
        "-lpthread",
        %{cudart_static_linkopt}
    ],
    visibility = ["//visibility:public"],
)

cc_library(
    name = "cuda_driver",
    srcs = select({
        ":aarch64": [
            "aarch64/cuda/lib/%{cuda_driver_lib}",
        ],
        "//conditions:default": ["x86_64/cuda/lib/%{cuda_driver_lib}"],
    }),
    includes = [
        ".",
        "cuda/include",
    ],
    visibility = ["//visibility:public"],
)

cc_library(
    name = "cudart",
    srcs = select({
        ":aarch64": [
            "aarch64/cuda/lib/%{cudart_lib}",
        ],
        "//conditions:default": ["x86_64/cuda/lib/%{cudart_lib}"],
    }),
    data = select({
        ":aarch64": [
            "aarch64/cuda/lib/%{cudart_lib}",
        ],
        "//conditions:default": ["x86_64/cuda/lib/%{cudart_lib}"],
    }),
    includes = [
        ".",
        "cuda/include",
    ],
    linkstatic = 1,
    visibility = ["//visibility:public"],
)

cc_library(
    name = "cublas",
    srcs = select({
        ":aarch64": [
            "aarch64/cuda/lib/%{cublas_lib}",
            "x86_64/cuda/lib/%{cublas_lib}",
        ],
        "//conditions:default": ["x86_64/cuda/lib/%{cublas_lib}"],
    }),
    data = select({
        ":aarch64": [
            "aarch64/cuda/lib/%{cublas_lib}",
            "x86_64/cuda/lib/%{cublas_lib}",
        ],
        "//conditions:default": ["x86_64/cuda/lib/%{cublas_lib}"],
    }),
    includes = [
        ".",
        "cuda/include",
    ],
    linkstatic = 1,
    visibility = ["//visibility:public"],
)

cc_library(
    name = "cusolver",
    srcs = select({
        ":aarch64": [
            "aarch64/cuda/lib/%{cusolver_lib}",
        ],
        "//conditions:default": ["x86_64/cuda/lib/%{cusolver_lib}"],
    }),
    data = select({
        ":aarch64": [
            "aarch64/cuda/lib/%{cusolver_lib}",
        ],
        "//conditions:default": ["x86_64/cuda/lib/%{cusolver_lib}"],
    }),
    includes = [
        ".",
        "cuda/include",
    ],
    linkopts = ["-lgomp"],
    linkstatic = 1,
    visibility = ["//visibility:public"],
)

cc_library(
    name = "cudnn",
    srcs = select({
        ":aarch64": [
            "aarch64/cuda/lib/%{cudnn_lib}",
        ],
        "//conditions:default": ["x86_64/cuda/lib/%{cudnn_lib}"],
    }),
    data = select({
        ":aarch64": [
            "aarch64/cuda/lib/%{cudnn_lib}",
        ],
        "//conditions:default": ["x86_64/cuda/lib/%{cudnn_lib}"],
    }),
    includes = [
        ".",
        "cuda/include",
    ],
    linkstatic = 1,
    visibility = ["//visibility:public"],
)

cc_library(
    name = "cudnn_header",
    includes = [
        ".",
        "cuda/include",
    ],
    visibility = ["//visibility:public"],
)

cc_library(
    name = "cufft",
    srcs = select({
        ":aarch64": [
            "aarch64/cuda/lib/%{cufft_lib}",
        ],
        "//conditions:default": ["x86_64/cuda/lib/%{cufft_lib}"],
    }),
    data = select({
        ":aarch64": [
            "aarch64/cuda/lib/%{cufft_lib}",
        ],
        "//conditions:default": ["x86_64/cuda/lib/%{cufft_lib}"],
    }),
    includes = [
        ".",
        "cuda/include",
    ],
    linkstatic = 1,
    visibility = ["//visibility:public"],
)

cc_library(
    name = "curand",
    srcs = select({
        ":aarch64": [
            "aarch64/cuda/lib/%{curand_lib}",
        ],
        "//conditions:default": ["x86_64/cuda/lib/%{curand_lib}"],
    }),
    data = select({
        ":aarch64": [
            "aarch64/cuda/lib/%{curand_lib}",
        ],
        "//conditions:default": ["x86_64/cuda/lib/%{curand_lib}"],
    }),
    includes = [
        ".",
        "cuda/include",
    ],
    linkstatic = 1,
    visibility = ["//visibility:public"],
)

cc_library(
    name = "cuda",
    visibility = ["//visibility:public"],
    deps = [
        ":cublas",
        ":cuda_headers",
        ":cudart",
        ":cudnn",
        ":cufft",
        ":curand",
    ],
)

cc_library(
    name = "cupti_headers",
    hdrs = [
        "cuda/cuda_config.h",
        ":cuda-extras",
    ],
    includes = [
        ".",
        "cuda/extras/CUPTI/include/",
    ],
    visibility = ["//visibility:public"],
)

cc_library(
    name = "cupti_dsos",
    data = select({
        ":aarch64": [
            "aarch64/cuda/lib/%{cupti_lib}",
        ],
        "//conditions:default": ["x86_64/cuda/lib/%{cupti_lib}"],
    }),
    includes = [
        ".",
        "cuda/include",
    ],
    visibility = ["//visibility:public"],
)

cc_library(
    name = "libdevice_root",
    data = [":cuda-nvvm"],
    visibility = ["//visibility:public"],
)

%{cuda_include_genrules}
