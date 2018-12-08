config_setting(
    name = "darwin",
    values = {"cpu": "darwin"},
    visibility = ["//visibility:public"],
)

config_setting(
    name = "windows",
    values = {"cpu": "x64_windows"},
    visibility = ["//visibility:public"],
)

config_setting(
    name = "no_tensorflow_py_deps",
    define_values = {"no_tensorflow_py_deps": "true"},
    visibility = ["//visibility:public"],
)

config_setting(
    name = "linux_x86_64",
    values = {"cpu": "k8"},
    visibility = ["//visibility:public"],
)

# config_setting(
#     name = "linux_ppc64le",
#     values = {"cpu": "ppc"},
#     visibility = ["//visibility:public"],
# )

# config_setting(
#     name = "linux_s390x",
#     values = {"cpu": "s390x"},
#     visibility = ["//visibility:public"],
# )

config_setting(
    name = "debug",
    values = {
        "compilation_mode": "dbg",
    },
    visibility = ["//visibility:public"],
)

config_setting(
    name = "optimized",
    values = {
        "compilation_mode": "opt",
    },
    visibility = ["//visibility:public"],
)

config_setting(
    name = "freebsd",
    values = {"cpu": "freebsd"},
    visibility = ["//visibility:public"],
)

config_setting(
    name = "with_default_optimizations",
    define_values = {"with_default_optimizations": "true"},
    visibility = ["//visibility:public"],
)

config_setting(
    name = "with_xla_support",
    define_values = {"with_xla_support": "true"},
    visibility = ["//visibility:public"],
)

config_setting(
    name = "with_gdr_support",
    define_values = {"with_gdr_support": "true"},
    visibility = ["//visibility:public"],
)

config_setting(
    name = "with_verbs_support",
    define_values = {"with_verbs_support": "true"},
    visibility = ["//visibility:public"],
)

# Crosses between framework_shared_object and a bunch of other configurations
# due to limitations in nested select() statements.
config_setting(
    name = "framework_shared_object",
    define_values = {
        "framework_shared_object": "true",
    },
    visibility = ["//visibility:public"],
)

config_setting(
    name = "using_cuda_clang",
    define_values = {
        "using_cuda_clang": "true",
    },
)

config_setting(
    name = "using_cuda_clang_with_dynamic_build",
    define_values = {
        "using_cuda_clang": "true",
        "framework_shared_object": "true",
    },
)

# Setting to use when loading kernels dynamically
config_setting(
    name = "dynamic_loaded_kernels",
    define_values = {
        "dynamic_loaded_kernels": "true",
    },
    visibility = ["//visibility:public"],
)

config_setting(
    name = "using_cuda_nvcc",
    define_values = {
        "using_cuda_nvcc": "true",
    },
)

config_setting(
    name = "using_cuda_nvcc_with_dynamic_build",
    define_values = {
        "using_cuda_nvcc": "true",
        "framework_shared_object": "true",
    },
)

config_setting(
    name = "with_mpi_support",
    values = {"define": "with_mpi_support=true"},
    visibility = ["//visibility:public"],
)

config_setting(
    name = "override_eigen_strong_inline",
    values = {"define": "override_eigen_strong_inline=true"},
    visibility = ["//visibility:public"],
)

# This flag is set from the configure step when the user selects with nGraph option.
# By default it should be false
config_setting(
    name = "with_ngraph_support",
    values = {"define": "with_ngraph_support=true"},
    visibility = ["//visibility:public"],
)

# This flag specifies whether TensorFlow 2.0 API should be built instead
# of 1.* API. Note that TensorFlow 2.0 API is currently under development.
config_setting(
    name = "api_version_2",
    define_values = {"tf_api_version": "2"},
)

package_group(
    name = "internal",
    packages = [
        #"-//third_party/tensorflow/python/estimator",
        #"//learning/meta_rank/...",
        "//tensorflow/...",
        #"//tensorflow_estimator/contrib/...",
        #"//tensorflow_fold/llgtm/...",
        #"//tensorflow_text/...",
        #"//third_party/py/tensor2tensor/...",
    ],
)
