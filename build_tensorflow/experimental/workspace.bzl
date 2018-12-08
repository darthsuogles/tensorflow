load("//gpu_tools:cuda_configure.bzl", "cuda_configure")
load("//templates:aarch64_configure.bzl", "aarch64_configure")
load("@io_bazel_rules_closure//closure:defs.bzl", "filegroup_external")
load("//third_party/tensorrt:tensorrt_configure.bzl", "tensorrt_configure")
load("//third_party/mkl:build_defs.bzl", "mkl_repository")
load("//third_party/git:git_configure.bzl", "git_configure")
load("//third_party/py:python_configure.bzl", "python_configure")
load("//third_party/sycl:sycl_configure.bzl", "sycl_configure")
load("//third_party/systemlibs:syslibs_configure.bzl", "syslibs_configure")
load("//third_party:repo.bzl", "tf_http_archive", "third_party_http_archive")
load("//third_party/clang_toolchain:cc_configure_clang.bzl", "cc_download_clang_toolchain")
load("//third_party/flatbuffers:workspace.bzl", flatbuffers = "repo")
load("//third_party/highwayhash:workspace.bzl", highwayhash = "repo")
load("//third_party/icu:workspace.bzl", icu = "repo")
load("//third_party/jpeg:workspace.bzl", jpeg = "repo")
load("//third_party/nasm:workspace.bzl", nasm = "repo")
load("//third_party/kissfft:workspace.bzl", kissfft = "repo")

def initialize_third_party():
    """ Load third party repositories.  See above load() statements. """
    flatbuffers()
    highwayhash()
    icu()
    kissfft()
    jpeg()
    nasm()

# Sanitize a dependency so that it works correctly from code that includes
# TensorFlow as a submodule.
def clean_dep(dep):
    return str(Label(dep))

def tfx_workspace(path_prefix = "", tf_repo_name = ""):
    # Note that we check the minimum bazel version in WORKSPACE.
    cuda_configure(name = "local_config_cuda")
    tensorrt_configure(name = "local_config_tensorrt")
    aarch64_configure(name = "local_config_aarch64")
    cc_download_clang_toolchain(name = "local_config_download_clang")
    git_configure(name = "local_config_git")
    syslibs_configure(name = "local_config_syslibs")
    python_configure(name = "local_config_python")

    initialize_third_party()

    mkl_repository(
        name = "mkl_linux",
        build_file = clean_dep("//third_party/mkl:mkl.BUILD"),
        sha256 = "f00dc3b142a5be399bdeebd7e7ea369545a35d4fb84c86f98b6b048d72685295",
        strip_prefix = "mklml_lnx_2019.0.1.20180928",
        urls = [
            "https://mirror.bazel.build/github.com/intel/mkl-dnn/releases/download/v0.17-rc/mklml_lnx_2019.0.1.20180928.tgz",
            "https://github.com/intel/mkl-dnn/releases/download/v0.17-rc/mklml_lnx_2019.0.1.20180928.tgz",
        ],
    )

    tf_http_archive(
        name = "six_archive",
        build_file = clean_dep("//third_party:six.BUILD"),
        sha256 = "105f8d68616f8248e24bf0e9372ef04d3cc10104f1980f54d57b2ce73a5ad56a",
        strip_prefix = "six-1.10.0",
        system_build_file = clean_dep("//third_party/systemlibs:six.BUILD"),
        urls = [
            "https://mirror.bazel.build/pypi.python.org/packages/source/s/six/six-1.10.0.tar.gz",
            "https://pypi.python.org/packages/source/s/six/six-1.10.0.tar.gz",
        ],
    )

    tf_http_archive(
        name = "cython",
        build_file = clean_dep("//third_party:cython.BUILD"),
        delete = ["BUILD.bazel"],
        sha256 = "bccc9aa050ea02595b2440188813b936eaf345e85fb9692790cecfe095cf91aa",
        strip_prefix = "cython-0.28.4",
        system_build_file = clean_dep("//third_party/systemlibs:cython.BUILD"),
        urls = [
            "https://mirror.bazel.build/github.com/cython/cython/archive/0.28.4.tar.gz",
            "https://github.com/cython/cython/archive/0.28.4.tar.gz",
        ],
    )

    tf_http_archive(
        name = "bazel_toolchains",
        sha256 = "07dfbe80638eb1fe681f7c07e61b34b579c6710c691e49ee90ccdc6e9e75ebbb",
        strip_prefix = "bazel-toolchains-9a111bd82161c1fbe8ed17a593ca1023fd941c70",
        urls = [
            "https://mirror.bazel.build/github.com/bazelbuild/bazel-toolchains/archive/9a111bd82161c1fbe8ed17a593ca1023fd941c70.tar.gz",
            "https://github.com/bazelbuild/bazel-toolchains/archive/9a111bd82161c1fbe8ed17a593ca1023fd941c70.tar.gz",
        ],
    )

    tf_http_archive(
        name = "mkl_dnn",
        build_file = clean_dep("//third_party/mkl_dnn:mkldnn.BUILD"),
        sha256 = "b100f57af4a2b59a3a37a1ba38f77b644d2107d758a1a7f4e51310063cd21e73",
        strip_prefix = "mkl-dnn-733fc908874c71a5285043931a1cf80aa923165c",
        urls = [
            "https://mirror.bazel.build/github.com/intel/mkl-dnn/archive/733fc908874c71a5285043931a1cf80aa923165c.tar.gz",
            "https://github.com/intel/mkl-dnn/archive/733fc908874c71a5285043931a1cf80aa923165c.tar.gz",
        ],
    )

    tf_http_archive(
        name = "com_google_absl",
        build_file = clean_dep("//third_party:com_google_absl.BUILD"),
        sha256 = "3ad76de484192b2d5afd49d90492b5ed0bc59eb1a4e8e0deecc7a2a077a90251",
        strip_prefix = "abseil-cpp-f197d7c72a54064cfde5a2058f1513a4a0ee36fb",
        urls = [
            "https://mirror.bazel.build/github.com/abseil/abseil-cpp/archive/f197d7c72a54064cfde5a2058f1513a4a0ee36fb.tar.gz",
            "https://github.com/abseil/abseil-cpp/archive/f197d7c72a54064cfde5a2058f1513a4a0ee36fb.tar.gz",
        ],
    )

    tf_http_archive(
        name = "eigen_archive",
        build_file = clean_dep("//third_party:eigen.BUILD"),
        sha256 = "aae7a680d141c978301dfae2c7945c06039f65849fcf64269595a9cdbba82638",
        strip_prefix = "eigen-eigen-729d33d11c81",
        urls = [
            "https://mirror.bazel.build/bitbucket.org/eigen/eigen/get/729d33d11c81.tar.gz",
            "https://bitbucket.org/eigen/eigen/get/729d33d11c81.tar.gz",
        ],
    )

    tf_http_archive(
        name = "libxsmm_archive",
        build_file = clean_dep("//third_party:libxsmm.BUILD"),
        sha256 = "cd8532021352b4a0290d209f7f9bfd7c2411e08286a893af3577a43457287bfa",
        strip_prefix = "libxsmm-1.9",
        urls = [
            "https://mirror.bazel.build/github.com/hfp/libxsmm/archive/1.9.tar.gz",
            "https://github.com/hfp/libxsmm/archive/1.9.tar.gz",
        ],
    )

    tf_http_archive(
        name = "com_googlesource_code_re2",
        sha256 = "a31397714a353587413d307337d0b58f8a2e20e2b9d02f2e24e3463fa4eeda81",
        strip_prefix = "re2-2018-10-01",
        system_build_file = clean_dep("//third_party/systemlibs:re2.BUILD"),
        urls = [
            "https://mirror.bazel.build/github.com/google/re2/archive/2018-10-01.tar.gz",
            "https://github.com/google/re2/archive/2018-10-01.tar.gz",
        ],
    )

    tf_http_archive(
        name = "gemmlowp",
        sha256 = "b87faa7294dfcc5d678f22a59d2c01ca94ea1e2a3b488c38a95a67889ed0a658",
        strip_prefix = "gemmlowp-38ebac7b059e84692f53e5938f97a9943c120d98",
        urls = [
            "https://mirror.bazel.build/github.com/google/gemmlowp/archive/38ebac7b059e84692f53e5938f97a9943c120d98.zip",
            "https://github.com/google/gemmlowp/archive/38ebac7b059e84692f53e5938f97a9943c120d98.zip",
        ],
    )

    tf_http_archive(
        name = "farmhash_archive",
        build_file = clean_dep("//third_party:farmhash.BUILD"),
        sha256 = "6560547c63e4af82b0f202cb710ceabb3f21347a4b996db565a411da5b17aba0",
        strip_prefix = "farmhash-816a4ae622e964763ca0862d9dbd19324a1eaf45",
        urls = [
            "https://mirror.bazel.build/github.com/google/farmhash/archive/816a4ae622e964763ca0862d9dbd19324a1eaf45.tar.gz",
            "https://github.com/google/farmhash/archive/816a4ae622e964763ca0862d9dbd19324a1eaf45.tar.gz",
        ],
    )

    tf_http_archive(
        name = "png_archive",
        build_file = clean_dep("//third_party:png.BUILD"),
        patch_file = clean_dep("//third_party:png_fix_rpi.patch"),
        sha256 = "e45ce5f68b1d80e2cb9a2b601605b374bdf51e1798ef1c2c2bd62131dfcf9eef",
        strip_prefix = "libpng-1.6.34",
        system_build_file = clean_dep("//third_party/systemlibs:png.BUILD"),
        urls = [
            "https://mirror.bazel.build/github.com/glennrp/libpng/archive/v1.6.34.tar.gz",
            "https://github.com/glennrp/libpng/archive/v1.6.34.tar.gz",
        ],
    )

    tf_http_archive(
        name = "org_sqlite",
        build_file = clean_dep("//third_party:sqlite.BUILD"),
        sha256 = "ad68c1216c3a474cf360c7581a4001e952515b3649342100f2d7ca7c8e313da6",
        strip_prefix = "sqlite-amalgamation-3240000",
        system_build_file = clean_dep("//third_party/systemlibs:sqlite.BUILD"),
        urls = [
            "https://mirror.bazel.build/www.sqlite.org/2018/sqlite-amalgamation-3240000.zip",
            "https://www.sqlite.org/2018/sqlite-amalgamation-3240000.zip",
        ],
    )

    tf_http_archive(
        name = "gif_archive",
        build_file = clean_dep("//third_party:gif.BUILD"),
        sha256 = "34a7377ba834397db019e8eb122e551a49c98f49df75ec3fcc92b9a794a4f6d1",
        strip_prefix = "giflib-5.1.4",
        system_build_file = clean_dep("//third_party/systemlibs:gif.BUILD"),
        urls = [
            "https://mirror.bazel.build/ufpr.dl.sourceforge.net/project/giflib/giflib-5.1.4.tar.gz",
            "http://pilotfiber.dl.sourceforge.net/project/giflib/giflib-5.1.4.tar.gz",
        ],
    )

    tf_http_archive(
        name = "astor_archive",
        build_file = clean_dep("//third_party:astor.BUILD"),
        sha256 = "ff6d2e2962d834acb125cc4dcc80c54a8c17c253f4cc9d9c43b5102a560bb75d",
        strip_prefix = "astor-0.6.2",
        system_build_file = clean_dep("//third_party/systemlibs:astor.BUILD"),
        urls = [
            "https://mirror.bazel.build/pypi.python.org/packages/d8/be/c4276b3199ec3feee2a88bc64810fbea8f26d961e0a4cd9c68387a9f35de/astor-0.6.2.tar.gz",
            "https://pypi.python.org/packages/d8/be/c4276b3199ec3feee2a88bc64810fbea8f26d961e0a4cd9c68387a9f35de/astor-0.6.2.tar.gz",
        ],
    )

    tf_http_archive(
        name = "gast_archive",
        build_file = clean_dep("//third_party:gast.BUILD"),
        sha256 = "7068908321ecd2774f145193c4b34a11305bd104b4551b09273dfd1d6a374930",
        strip_prefix = "gast-0.2.0",
        system_build_file = clean_dep("//third_party/systemlibs:gast.BUILD"),
        urls = [
            "https://mirror.bazel.build/pypi.python.org/packages/5c/78/ff794fcae2ce8aa6323e789d1f8b3b7765f601e7702726f430e814822b96/gast-0.2.0.tar.gz",
            "https://pypi.python.org/packages/5c/78/ff794fcae2ce8aa6323e789d1f8b3b7765f601e7702726f430e814822b96/gast-0.2.0.tar.gz",
        ],
    )

    tf_http_archive(
        name = "termcolor_archive",
        build_file = clean_dep("//third_party:termcolor.BUILD"),
        sha256 = "1d6d69ce66211143803fbc56652b41d73b4a400a2891d7bf7a1cdf4c02de613b",
        strip_prefix = "termcolor-1.1.0",
        system_build_file = clean_dep("//third_party/systemlibs:termcolor.BUILD"),
        urls = [
            "https://mirror.bazel.build/pypi.python.org/packages/8a/48/a76be51647d0eb9f10e2a4511bf3ffb8cc1e6b14e9e4fab46173aa79f981/termcolor-1.1.0.tar.gz",
            "https://pypi.python.org/packages/8a/48/a76be51647d0eb9f10e2a4511bf3ffb8cc1e6b14e9e4fab46173aa79f981/termcolor-1.1.0.tar.gz",
        ],
    )

    tf_http_archive(
        name = "absl_py",
        sha256 = "95160f778a62c7a60ddeadc7bf2d83f85a23a27359814aca12cf949e896fa82c",
        strip_prefix = "abseil-py-pypi-v0.2.2",
        system_build_file = clean_dep("//third_party/systemlibs:absl_py.BUILD"),
        system_link_files = {
            "//third_party/systemlibs:absl_py.absl.flags.BUILD": "absl/flags/BUILD",
            "//third_party/systemlibs:absl_py.absl.testing.BUILD": "absl/testing/BUILD",
        },
        urls = [
            "https://mirror.bazel.build/github.com/abseil/abseil-py/archive/pypi-v0.2.2.tar.gz",
            "https://github.com/abseil/abseil-py/archive/pypi-v0.2.2.tar.gz",
        ],
    )

    tf_http_archive(
        name = "org_python_pypi_backports_weakref",
        build_file = clean_dep("//third_party:backports_weakref.BUILD"),
        sha256 = "8813bf712a66b3d8b85dc289e1104ed220f1878cf981e2fe756dfaabe9a82892",
        strip_prefix = "backports.weakref-1.0rc1/src",
        urls = [
            "https://mirror.bazel.build/pypi.python.org/packages/bc/cc/3cdb0a02e7e96f6c70bd971bc8a90b8463fda83e264fa9c5c1c98ceabd81/backports.weakref-1.0rc1.tar.gz",
            "https://pypi.python.org/packages/bc/cc/3cdb0a02e7e96f6c70bd971bc8a90b8463fda83e264fa9c5c1c98ceabd81/backports.weakref-1.0rc1.tar.gz",
        ],
    )

    # filegroup_external(
    #     name = "org_python_license",
    #     licenses = ["notice"],  # Python 2.0
    #     sha256_urls = {
    #         "7ca8f169368827781684f7f20876d17b4415bbc5cb28baa4ca4652f0dda05e9f": [
    #             "https://mirror.bazel.build/docs.python.org/2.7/_sources/license.rst.txt",
    #             "https://docs.python.org/2.7/_sources/license.rst.txt",
    #         ],
    #     },
    # )

    PROTOBUF_URLS = [
        "https://mirror.bazel.build/github.com/protocolbuffers/protobuf/archive/v3.6.1.2.tar.gz",
        "https://github.com/protocolbuffers/protobuf/archive/v3.6.1.2.tar.gz",
    ]
    PROTOBUF_SHA256 = "2244b0308846bb22b4ff0bcc675e99290ff9f1115553ae9671eba1030af31bc0"
    PROTOBUF_STRIP_PREFIX = "protobuf-3.6.1.2"

    tf_http_archive(
        name = "protobuf_archive",
        sha256 = PROTOBUF_SHA256,
        strip_prefix = PROTOBUF_STRIP_PREFIX,
        system_build_file = clean_dep("//third_party/systemlibs:protobuf.BUILD"),
        system_link_files = {
            "//third_party/systemlibs:protobuf.bzl": "protobuf.bzl",
        },
        urls = PROTOBUF_URLS,
    )

    # We need to import the protobuf library under the names com_google_protobuf
    # and com_google_protobuf_cc to enable proto_library support in bazel.
    # Unfortunately there is no way to alias http_archives at the moment.
    tf_http_archive(
        name = "com_google_protobuf",
        sha256 = PROTOBUF_SHA256,
        strip_prefix = PROTOBUF_STRIP_PREFIX,
        system_build_file = clean_dep("//third_party/systemlibs:protobuf.BUILD"),
        system_link_files = {
            "//third_party/systemlibs:protobuf.bzl": "protobuf.bzl",
        },
        urls = PROTOBUF_URLS,
    )

    tf_http_archive(
        name = "com_google_protobuf_cc",
        sha256 = PROTOBUF_SHA256,
        strip_prefix = PROTOBUF_STRIP_PREFIX,
        system_build_file = clean_dep("//third_party/systemlibs:protobuf.BUILD"),
        system_link_files = {
            "//third_party/systemlibs:protobuf.bzl": "protobuf.bzl",
        },
        urls = PROTOBUF_URLS,
    )

    tf_http_archive(
        name = "nsync",
        sha256 = "692f9b30e219f71a6371b98edd39cef3cbda35ac3abc4cd99ce19db430a5591a",
        strip_prefix = "nsync-1.20.1",
        system_build_file = clean_dep("//third_party/systemlibs:nsync.BUILD"),
        urls = [
            "https://mirror.bazel.build/github.com/google/nsync/archive/1.20.1.tar.gz",
            "https://github.com/google/nsync/archive/1.20.1.tar.gz",
        ],
    )

    tf_http_archive(
        name = "com_google_googletest",
        sha256 = "353ab86e35cea1cd386115279cf4b16695bbf21b897bfbf2721cf4cb5f64ade8",
        strip_prefix = "googletest-997d343dd680e541ef96ce71ee54a91daf2577a0",
        urls = [
            "https://mirror.bazel.build/github.com/google/googletest/archive/997d343dd680e541ef96ce71ee54a91daf2577a0.zip",
            "https://github.com/google/googletest/archive/997d343dd680e541ef96ce71ee54a91daf2577a0.zip",
        ],
    )

    tf_http_archive(
        name = "com_github_gflags_gflags",
        sha256 = "ae27cdbcd6a2f935baa78e4f21f675649271634c092b1be01469440495609d0e",
        strip_prefix = "gflags-2.2.1",
        urls = [
            "https://mirror.bazel.build/github.com/gflags/gflags/archive/v2.2.1.tar.gz",
            "https://github.com/gflags/gflags/archive/v2.2.1.tar.gz",
        ],
    )

    tf_http_archive(
        name = "pcre",
        build_file = clean_dep("//third_party:pcre.BUILD"),
        sha256 = "69acbc2fbdefb955d42a4c606dfde800c2885711d2979e356c0636efde9ec3b5",
        strip_prefix = "pcre-8.42",
        system_build_file = clean_dep("//third_party/systemlibs:pcre.BUILD"),
        urls = [
            "https://mirror.bazel.build/ftp.exim.org/pub/pcre/pcre-8.42.tar.gz",
            "http://ftp.exim.org/pub/pcre/pcre-8.42.tar.gz",
        ],
    )

    tf_http_archive(
        name = "swig",
        build_file = clean_dep("//third_party:swig.BUILD"),
        sha256 = "58a475dbbd4a4d7075e5fe86d4e54c9edde39847cdb96a3053d87cb64a23a453",
        strip_prefix = "swig-3.0.8",
        system_build_file = clean_dep("//third_party/systemlibs:swig.BUILD"),
        urls = [
            "https://mirror.bazel.build/ufpr.dl.sourceforge.net/project/swig/swig/swig-3.0.8/swig-3.0.8.tar.gz",
            "http://ufpr.dl.sourceforge.net/project/swig/swig/swig-3.0.8/swig-3.0.8.tar.gz",
            "http://pilotfiber.dl.sourceforge.net/project/swig/swig/swig-3.0.8/swig-3.0.8.tar.gz",
        ],
    )

    tf_http_archive(
        name = "curl",
        build_file = clean_dep("//third_party:curl.BUILD"),
        sha256 = "e9c37986337743f37fd14fe8737f246e97aec94b39d1b71e8a5973f72a9fc4f5",
        strip_prefix = "curl-7.60.0",
        system_build_file = clean_dep("//third_party/systemlibs:curl.BUILD"),
        urls = [
            "https://mirror.bazel.build/curl.haxx.se/download/curl-7.60.0.tar.gz",
            "https://curl.haxx.se/download/curl-7.60.0.tar.gz",
        ],
    )

    # WARNING: make sure ncteisen@ and vpai@ are cc-ed on any CL to change the below rule
    tf_http_archive(
        name = "grpc",
        sha256 = "1aa84387232dda273ea8fdfe722622084f72c16f7b84bfc519ac7759b71cdc91",
        strip_prefix = "grpc-69b6c047bc767b4d80e7af4d00ccb7c45b683dae",
        system_build_file = clean_dep("//third_party/systemlibs:grpc.BUILD"),
        urls = [
            "https://mirror.bazel.build/github.com/grpc/grpc/archive/69b6c047bc767b4d80e7af4d00ccb7c45b683dae.tar.gz",
            "https://github.com/grpc/grpc/archive/69b6c047bc767b4d80e7af4d00ccb7c45b683dae.tar.gz",
        ],
    )

    tf_http_archive(
        name = "com_github_nanopb_nanopb",
        build_file = "@grpc//third_party:nanopb.BUILD",
        sha256 = "8bbbb1e78d4ddb0a1919276924ab10d11b631df48b657d960e0c795a25515735",
        strip_prefix = "nanopb-f8ac463766281625ad710900479130c7fcb4d63b",
        urls = [
            "https://mirror.bazel.build/github.com/nanopb/nanopb/archive/f8ac463766281625ad710900479130c7fcb4d63b.tar.gz",
            "https://github.com/nanopb/nanopb/archive/f8ac463766281625ad710900479130c7fcb4d63b.tar.gz",
        ],
    )

    tf_http_archive(
        name = "linenoise",
        build_file = clean_dep("//third_party:linenoise.BUILD"),
        sha256 = "7f51f45887a3d31b4ce4fa5965210a5e64637ceac12720cfce7954d6a2e812f7",
        strip_prefix = "linenoise-c894b9e59f02203dbe4e2be657572cf88c4230c3",
        urls = [
            "https://mirror.bazel.build/github.com/antirez/linenoise/archive/c894b9e59f02203dbe4e2be657572cf88c4230c3.tar.gz",
            "https://github.com/antirez/linenoise/archive/c894b9e59f02203dbe4e2be657572cf88c4230c3.tar.gz",
        ],
    )

    # TODO(phawkins): currently, this rule uses an unofficial LLVM mirror.
    # Switch to an official source of snapshots if/when possible.
    tf_http_archive(
        name = "llvm",
        build_file = clean_dep("//third_party/llvm:llvm.autogenerated.BUILD"),
        sha256 = "34170a4aa07e434dd537d98a705dcf1b3901f73820fe1d6b9370e8c1c94e9157",
        strip_prefix = "llvm-0487bd8f42c8b38166ff825d56014d0ff49db604",
        urls = [
            "https://mirror.bazel.build/github.com/llvm-mirror/llvm/archive/0487bd8f42c8b38166ff825d56014d0ff49db604.tar.gz",
            "https://github.com/llvm-mirror/llvm/archive/0487bd8f42c8b38166ff825d56014d0ff49db604.tar.gz",
        ],
    )

    tf_http_archive(
        name = "lmdb",
        build_file = clean_dep("//third_party:lmdb.BUILD"),
        sha256 = "f3927859882eb608868c8c31586bb7eb84562a40a6bf5cc3e13b6b564641ea28",
        strip_prefix = "lmdb-LMDB_0.9.22/libraries/liblmdb",
        system_build_file = clean_dep("//third_party/systemlibs:lmdb.BUILD"),
        urls = [
            "https://mirror.bazel.build/github.com/LMDB/lmdb/archive/LMDB_0.9.22.tar.gz",
            "https://github.com/LMDB/lmdb/archive/LMDB_0.9.22.tar.gz",
        ],
    )

    tf_http_archive(
        name = "jsoncpp_git",
        build_file = clean_dep("//third_party:jsoncpp.BUILD"),
        sha256 = "c49deac9e0933bcb7044f08516861a2d560988540b23de2ac1ad443b219afdb6",
        strip_prefix = "jsoncpp-1.8.4",
        system_build_file = clean_dep("//third_party/systemlibs:jsoncpp.BUILD"),
        urls = [
            "https://mirror.bazel.build/github.com/open-source-parsers/jsoncpp/archive/1.8.4.tar.gz",
            "https://github.com/open-source-parsers/jsoncpp/archive/1.8.4.tar.gz",
        ],
    )

    tf_http_archive(
        name = "boringssl",
        sha256 = "1188e29000013ed6517168600fc35a010d58c5d321846d6a6dfee74e4c788b45",
        strip_prefix = "boringssl-7f634429a04abc48e2eb041c81c5235816c96514",
        system_build_file = clean_dep("//third_party/systemlibs:boringssl.BUILD"),
        urls = [
            "https://mirror.bazel.build/github.com/google/boringssl/archive/7f634429a04abc48e2eb041c81c5235816c96514.tar.gz",
            "https://github.com/google/boringssl/archive/7f634429a04abc48e2eb041c81c5235816c96514.tar.gz",
        ],
    )

    tf_http_archive(
        name = "zlib_archive",
        build_file = clean_dep("//third_party:zlib.BUILD"),
        sha256 = "c3e5e9fdd5004dcb542feda5ee4f0ff0744628baf8ed2dd5d66f8ca1197cb1a1",
        strip_prefix = "zlib-1.2.11",
        system_build_file = clean_dep("//third_party/systemlibs:zlib.BUILD"),
        urls = [
            "https://mirror.bazel.build/zlib.net/zlib-1.2.11.tar.gz",
            "https://zlib.net/zlib-1.2.11.tar.gz",
        ],
    )

    tf_http_archive(
        name = "fft2d",
        build_file = clean_dep("//third_party/fft2d:fft2d.BUILD"),
        sha256 = "52bb637c70b971958ec79c9c8752b1df5ff0218a4db4510e60826e0cb79b5296",
        urls = [
            "https://mirror.bazel.build/www.kurims.kyoto-u.ac.jp/~ooura/fft.tgz",
            "http://www.kurims.kyoto-u.ac.jp/~ooura/fft.tgz",
        ],
    )

    tf_http_archive(
        name = "snappy",
        build_file = clean_dep("//third_party:snappy.BUILD"),
        sha256 = "3dfa02e873ff51a11ee02b9ca391807f0c8ea0529a4924afa645fbf97163f9d4",
        strip_prefix = "snappy-1.1.7",
        system_build_file = clean_dep("//third_party/systemlibs:snappy.BUILD"),
        urls = [
            "https://mirror.bazel.build/github.com/google/snappy/archive/1.1.7.tar.gz",
            "https://github.com/google/snappy/archive/1.1.7.tar.gz",
        ],
    )

    tf_http_archive(
        name = "nccl_archive",
        build_file = clean_dep("//third_party:nccl/archive.BUILD"),
        sha256 = "19132b5127fa8e02d95a09795866923f04064c8f1e0770b2b42ab551408882a4",
        strip_prefix = "nccl-f93fe9bfd94884cec2ba711897222e0df5569a53",
        urls = [
            "https://mirror.bazel.build/github.com/nvidia/nccl/archive/f93fe9bfd94884cec2ba711897222e0df5569a53.tar.gz",
            "https://github.com/nvidia/nccl/archive/f93fe9bfd94884cec2ba711897222e0df5569a53.tar.gz",
        ],
    )

    tf_http_archive(
        name = "com_google_pprof",
        build_file = clean_dep("//third_party:pprof.BUILD"),
        sha256 = "e0928ca4aa10ea1e0551e2d7ce4d1d7ea2d84b2abbdef082b0da84268791d0c4",
        strip_prefix = "pprof-c0fb62ec88c411cc91194465e54db2632845b650",
        urls = [
            "https://mirror.bazel.build/github.com/google/pprof/archive/c0fb62ec88c411cc91194465e54db2632845b650.tar.gz",
            "https://github.com/google/pprof/archive/c0fb62ec88c411cc91194465e54db2632845b650.tar.gz",
        ],
    )

    tf_http_archive(
        name = "cub_archive",
        build_file = clean_dep("//third_party:cub.BUILD"),
        sha256 = "6bfa06ab52a650ae7ee6963143a0bbc667d6504822cbd9670369b598f18c58c3",
        strip_prefix = "cub-1.8.0",
        urls = [
            "https://mirror.bazel.build/github.com/NVlabs/cub/archive/1.8.0.zip",
            "https://github.com/NVlabs/cub/archive/1.8.0.zip",
        ],
    )

    tf_http_archive(
        name = "arm_neon_2_x86_sse",
        build_file = clean_dep("//third_party:arm_neon_2_x86_sse.BUILD"),
        sha256 = "213733991310b904b11b053ac224fee2d4e0179e46b52fe7f8735b8831e04dcc",
        strip_prefix = "ARM_NEON_2_x86_SSE-1200fe90bb174a6224a525ee60148671a786a71f",
        urls = [
            "https://mirror.bazel.build/github.com/intel/ARM_NEON_2_x86_SSE/archive/1200fe90bb174a6224a525ee60148671a786a71f.tar.gz",
            "https://github.com/intel/ARM_NEON_2_x86_SSE/archive/1200fe90bb174a6224a525ee60148671a786a71f.tar.gz",
        ],
    )

    tf_http_archive(
        name = "double_conversion",
        build_file = clean_dep("//third_party:double_conversion.BUILD"),
        sha256 = "2f7fbffac0d98d201ad0586f686034371a6d152ca67508ab611adc2386ad30de",
        strip_prefix = "double-conversion-3992066a95b823efc8ccc1baf82a1cfc73f6e9b8",
        system_build_file = clean_dep("//third_party/systemlibs:double_conversion.BUILD"),
        urls = [
            "https://mirror.bazel.build/github.com/google/double-conversion/archive/3992066a95b823efc8ccc1baf82a1cfc73f6e9b8.zip",
            "https://github.com/google/double-conversion/archive/3992066a95b823efc8ccc1baf82a1cfc73f6e9b8.zip",
        ],
    )

    tf_http_archive(
        name = "tbb",
        build_file = clean_dep("//third_party/ngraph:tbb.BUILD"),
        sha256 = "724686f90bcda78f13b76f297d964008737ccd6399328143c1c0093e73ae6a13",
        strip_prefix = "tbb-tbb_2018",
        urls = [
            "https://mirror.bazel.build/github.com/01org/tbb/archive/tbb_2018.zip",
            "https://github.com/01org/tbb/archive/tbb_2018.zip",
        ],
    )

    tf_http_archive(
        name = "ngraph",
        build_file = clean_dep("//third_party/ngraph:ngraph.BUILD"),
        sha256 = "2b28f9c9f063b96825a96d56d7f7978c9a1c55c9b25175c20dd49a8a77cb0305",
        strip_prefix = "ngraph-0.9.1",
        urls = [
            "https://mirror.bazel.build/github.com/NervanaSystems/ngraph/archive/v0.9.1.tar.gz",
            "https://github.com/NervanaSystems/ngraph/archive/v0.9.1.tar.gz",
        ],
    )

    tf_http_archive(
        name = "nlohmann_json_lib",
        build_file = clean_dep("//third_party/ngraph:nlohmann_json.BUILD"),
        sha256 = "9f3549824af3ca7e9707a2503959886362801fb4926b869789d6929098a79e47",
        strip_prefix = "json-3.1.1",
        urls = [
            "https://mirror.bazel.build/github.com/nlohmann/json/archive/v3.1.1.tar.gz",
            "https://github.com/nlohmann/json/archive/v3.1.1.tar.gz",
        ],
    )

    tf_http_archive(
        name = "ngraph_tf",
        build_file = clean_dep("//third_party/ngraph:ngraph_tf.BUILD"),
        sha256 = "89accbc702e68a09775f1011a99dd16561038fd1ce59d566d64450176abaae5c",
        strip_prefix = "ngraph-tf-0.7.0",
        urls = [
            "https://mirror.bazel.build/github.com/NervanaSystems/ngraph-tf/archive/v0.7.0.tar.gz",
            "https://github.com/NervanaSystems/ngraph-tf/archive/v0.7.0.tar.gz",
        ],
    )

    third_party_http_archive(
        name = "ortools_archive",
        build_file = "//third_party/ortools:BUILD.bazel",
        sha256 = "d025a95f78b5fc5eaa4da5f395f23d11c23cf7dbd5069f1f627f002de87b86b9",
        strip_prefix = "or-tools-6.7.2/src",
        urls = [
            "https://mirror.bazel.build/github.com/google/or-tools/archive/v6.7.2.tar.gz",
            "https://github.com/google/or-tools/archive/v6.7.2.tar.gz",
        ],
    )
