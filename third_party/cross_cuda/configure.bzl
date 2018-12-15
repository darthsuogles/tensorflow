# -*- Python -*-
"""Repository rule for CUDA autoconfiguration.

`cuda_configure` depends on the following environment variables:

  * `TF_NEED_CUDA`: Whether to enable building with CUDA.
  * `GCC_HOST_COMPILER_PATH`: The GCC host compiler path
  * `CUDA_TOOLKIT_PATH`: The path to the CUDA toolkit. Default is
    `/usr/local/cuda`.
  * `TF_CUDA_VERSION`: The version of the CUDA toolkit. If this is blank, then
    use the system default.
  * `TF_CUDNN_VERSION`: The version of the cuDNN library.
  * `CUDNN_INSTALL_PATH`: The path to the cuDNN library. Default is
    `/usr/local/cuda`.
  * `TF_CUDA_COMPUTE_CAPABILITIES`: The CUDA compute capabilities. Default is
    `3.5,5.2`.
  * `PYTHON_BIN_PATH`: The python binary path
"""

load(
    "@bazel_tools//tools/cpp:lib_cc_configure.bzl",
    "escape_string",
    "get_cpu_value",
    "get_env_var",
    "resolve_labels",
    "split_escaped",
    "which",
)

_TF_CROSS_COMPILATION = "TF_CROSS_COMPILATION"
_CROSS_NVCC_HOST_COMPILER_PATH = "CROSS_NVCC_HOST_COMPILER_PATH"
_CROSS_NVCC_TARGET_COMPILER_PATH = "CROSS_NVCC_TARGET_COMPILER_PATH"
_GCC_HOST_COMPILER_PATH = "GCC_HOST_COMPILER_PATH"
_CUDA_TOOLKIT_PATH = "CUDA_TOOLKIT_PATH"
_TF_CUDA_VERSION = "TF_CUDA_VERSION"
_TF_CUDNN_VERSION = "TF_CUDNN_VERSION"
_CUDNN_INSTALL_PATH = "CUDNN_INSTALL_PATH"
_TF_CUDA_COMPUTE_CAPABILITIES = "TF_CUDA_COMPUTE_CAPABILITIES"
_TF_CUDA_CONFIG_REPO = "TF_CUDA_CONFIG_REPO"
_PYTHON_BIN_PATH = "PYTHON_BIN_PATH"
_BUILD_WITH_RHEL_LINKER_BIN_FIX = "BUILD_WITH_RHEL_LINKER_BIN_FIX"

_cuda_defines_compiler_includes_placeholder_ = "_host_compiler_includes_placeholder_"

_VALID_CUDA_TARGET_ARCH = ["x86_64", "aarch64"]

_DEFAULT_CUDA_VERSION = ""
_DEFAULT_CUDNN_VERSION = ""
_DEFAULT_CUDA_TOOLKIT_PATH = "/usr/local/cuda"
_DEFAULT_CUDNN_INSTALL_PATH = "/usr/local/cuda"
_DEFAULT_CUDA_COMPUTE_CAPABILITIES = ["3.5", "5.2"]

# Lookup paths for CUDA / cuDNN libraries, relative to the install directories.
#
# Paths will be tried out in the order listed below. The first successful path
# will be used. For example, when looking for the cudart libraries, the first
# attempt will be lib64/cudart inside the CUDA toolkit.
CUDA_LIB_PATHS = [
    "lib64/",
    "lib64/stubs/",
    "lib/powerpc64le-linux-gnu/",
    "lib/x86_64-linux-gnu/",
    "lib/x64/",
    "lib/",
    "",
]

# Lookup paths for cupti.h, relative to the CUDA toolkit directory.
#
# On most systems, the cupti library is not installed in the same directory as
# the other CUDA libraries but rather in a special extras/CUPTI directory.
CUPTI_HEADER_PATHS = [
    "extras/CUPTI/include/",
    "include/cuda/CUPTI/",
    "include/",
]

# Lookup paths for the cupti library, relative to the
#
# On most systems, the cupti library is not installed in the same directory as
# the other CUDA libraries but rather in a special extras/CUPTI directory.
CUPTI_LIB_PATHS = [
    "extras/CUPTI/lib64/",
    "lib/powerpc64le-linux-gnu/",
    "lib/x86_64-linux-gnu/",
    "lib64/",
    "extras/CUPTI/libx64/",
    "extras/CUPTI/lib/",
    "lib/",
]

# Lookup paths for CUDA headers (cuda.h) relative to the CUDA toolkit directory.
CUDA_INCLUDE_PATHS = [
    "include/",
    "include/cuda/",
]

# Lookup paths for cudnn.h relative to the CUDNN install directory.
CUDNN_INCLUDE_PATHS = [
    "",
    "include/",
    "include/cuda/",
]

# Lookup paths for NVVM libdevice relative to the CUDA directory toolkit.
#
# libdevice implements mathematical functions for GPU kernels, and is provided
# in NVVM bitcode (a subset of LLVM bitcode).
NVVM_LIBDEVICE_PATHS = [
    "nvvm/libdevice/",
    "share/cuda/",
    "lib/nvidia-cuda-toolkit/libdevice/",
]

# Files used to detect the NVVM libdevice path.
NVVM_LIBDEVICE_FILES = [
    # CUDA 9.0 has a single file.
    "libdevice.10.bc",

    # CUDA 8.0 has separate files for compute versions 2.0, 3.0, 3.5 and 5.0.
    # Probing for one of them is sufficient.
    "libdevice.compute_20.10.bc",
]


def _get_python_bin(repository_ctx):
    """Gets the python bin path."""
    python_bin = repository_ctx.os.environ.get(_PYTHON_BIN_PATH)
    if python_bin != None:
        return python_bin
    python_bin_name = "python"
    python_bin_path = repository_ctx.which(python_bin_name)
    if python_bin_path != None:
        return str(python_bin_path)
    auto_configure_fail(
        "Cannot find python in PATH, please make sure " +
        "python is installed and add its directory in PATH, or --define " +
        "%s='/something/else'.\nPATH=%s" % (
            _PYTHON_BIN_PATH,
            repository_ctx.os.environ.get("PATH", ""),
        ))


# TODO(dzc): Once these functions have been factored out of Bazel's
# cc_configure.bzl, load them from @bazel_tools instead.
# BEGIN cc_configure common functions.
def find_cc(repository_ctx):
    """Find the C++ compiler."""
    # TODO(phi9t): support both host and target compilation
    cc_path_envvar = _GCC_HOST_COMPILER_PATH
    cc_name = "gcc"

    if cc_path_envvar in repository_ctx.os.environ:
        cc_name_from_env = repository_ctx.os.environ[cc_path_envvar].strip()
        if cc_name_from_env:
            cc_name = cc_name_from_env
    if cc_name.startswith("/"):
        # Absolute path, maybe we should make this supported by our which function.
        return cc_name
    cc = repository_ctx.which(cc_name)
    if cc == None:
        fail(("Cannot find {}, either correct your path or set the {}" +
              " environment variable").format(cc_name, cc_path_envvar))
    return cc


_INC_DIR_MARKER_BEGIN = "#include <...>"


def _cxx_inc_convert(path):
    """Convert path returned by cc -E xc++ in a complete path."""
    return path.strip()


def _normalize_include_path(repository_ctx, path):
    """Normalizes include paths before writing them to the crosstool.

    If path points inside the 'crosstool' folder of the repository, a relative
    path is returned.
    If path points outside the 'crosstool' folder, an absolute path is returned.
    """
    path = str(repository_ctx.path(path))
    crosstool_folder = str(repository_ctx.path(".").get_child("crosstool"))

    if path.startswith(crosstool_folder):
        # We drop the path to "$REPO/crosstool" and a trailing path separator.
        return path[len(crosstool_folder) + 1:]
    return path


def _get_cxx_inc_directories_impl(repository_ctx, cc, lang_is_cpp):
    """Compute the list of default C or C++ include directories."""
    if lang_is_cpp:
        lang = "c++"
    else:
        lang = "c"
    result = repository_ctx.execute([cc, "-E", "-x" + lang, "-", "-v"])
    index1 = result.stderr.find(_INC_DIR_MARKER_BEGIN)
    if index1 == -1:
        return []
    index1 = result.stderr.find("\n", index1)
    if index1 == -1:
        return []
    index2 = result.stderr.rfind("\n ")
    if index2 == -1 or index2 < index1:
        return []
    index2 = result.stderr.find("\n", index2 + 1)
    if index2 == -1:
        inc_dirs = result.stderr[index1 + 1:]
    else:
        inc_dirs = result.stderr[index1 + 1:index2].strip()

    return [
        _normalize_include_path(repository_ctx, _cxx_inc_convert(p))
        for p in inc_dirs.split("\n")
    ]


def get_cxx_inc_directories(repository_ctx, cc):
    """Compute the list of default C and C++ include directories."""

    # For some reason `clang -xc` sometimes returns include paths that are
    # different from the ones from `clang -xc++`. (Symlink and a dir)
    # So we run the compiler with both `-xc` and `-xc++` and merge resulting lists
    includes_cpp = _get_cxx_inc_directories_impl(repository_ctx, cc, True)
    includes_c = _get_cxx_inc_directories_impl(repository_ctx, cc, False)

    includes_cpp_set = depset(includes_cpp)
    return includes_cpp + [
        inc for inc in includes_c if inc not in includes_cpp_set
    ]


def auto_configure_fail(msg):
    """Output failure message when cuda configuration fails."""
    red = "\033[0;31m"
    no_color = "\033[0m"
    fail("\n%sCuda Configuration Error:%s %s\n" % (red, no_color, msg))


# END cc_configure common functions (see TODO above).


def _host_compiler_includes(repository_ctx, cc):
    """Generates the cxx_builtin_include_directory entries for gcc inc dirs.

    Args:
      repository_ctx: The repository context.
      cc: The path to the gcc host compiler.

    Returns:
      A string containing the cxx_builtin_include_directory for each of the gcc
      host compiler include directories, which can be added to the CROSSTOOL
      file.
    """
    inc_dirs = get_cxx_inc_directories(repository_ctx, cc)
    inc_entries = []
    for inc_dir in inc_dirs:
        inc_entries.append("  cxx_builtin_include_directory: \"%s\"" % inc_dir)
    return "\n".join(inc_entries)


def _cuda_include_path(repository_ctx, cuda_config, cc_compiler_fname):
    """Generates the cxx_builtin_include_directory entries for cuda inc dirs.

    Args:
      repository_ctx: The repository context.
      cc_compiler_fname: The path to the gcc host compiler.

    Returns:
      A string containing the cxx_builtin_include_directory for each of the gcc
      host compiler include directories, which can be added to the CROSSTOOL
      file.
    """
    nvcc_path = repository_ctx.path(
        "%s/bin/nvcc" % cuda_config.cuda_toolkit_path)
    result = repository_ctx.execute([
        nvcc_path,
        "-ccbin",
        cc_compiler_fname,
        "-v",
        "/dev/null",
        "-o",
        "/dev/null",
    ])
    target_dir = ""
    for one_line in result.stderr.splitlines():
        if one_line.startswith("#$ _TARGET_DIR_="):
            target_dir = (
                cuda_config.cuda_toolkit_path + "/" + one_line.replace(
                    "#$ _TARGET_DIR_=", "") + "/include")
    inc_entries = []
    if target_dir != "":
        inc_entries.append(
            "  cxx_builtin_include_directory: \"%s\"" % target_dir)
    default_include = cuda_config.cuda_toolkit_path + "/include"
    inc_entries.append(
        "  cxx_builtin_include_directory: \"%s\"" % default_include)
    return "\n".join(inc_entries)


def _enable_cuda(repository_ctx):
    if "TF_NEED_CUDA" in repository_ctx.os.environ:
        enable_cuda = repository_ctx.os.environ["TF_NEED_CUDA"].strip()
        return enable_cuda == "1"
    return False


def cuda_toolkit_path(repository_ctx):
    """Finds the cuda toolkit directory.

    Args:
      repository_ctx: The repository context.

    Returns:
      A speculative real path of the cuda toolkit install directory.
    """
    cuda_toolkit_path = _DEFAULT_CUDA_TOOLKIT_PATH
    if _CUDA_TOOLKIT_PATH in repository_ctx.os.environ:
        cuda_toolkit_path = repository_ctx.os.environ[
            _CUDA_TOOLKIT_PATH].strip()
    if not repository_ctx.path(cuda_toolkit_path).exists:
        auto_configure_fail("Cannot find cuda toolkit path.")
    return str(repository_ctx.path(cuda_toolkit_path).realpath)


def _cudnn_install_basedir(repository_ctx):
    """Finds the cudnn install directory."""
    cudnn_install_path = _DEFAULT_CUDNN_INSTALL_PATH
    if _CUDNN_INSTALL_PATH in repository_ctx.os.environ:
        cudnn_install_path = repository_ctx.os.environ[
            _CUDNN_INSTALL_PATH].strip()
    if not repository_ctx.path(cudnn_install_path).exists:
        auto_configure_fail("Cannot find cudnn install path.")
    return cudnn_install_path


def matches_version(environ_version, detected_version):
    """Checks whether the user-specified version matches the detected version.

    This function performs a weak matching so that if the user specifies only
    the
    major or major and minor versions, the versions are still considered
    matching
    if the version parts match. To illustrate:

        environ_version  detected_version  result
        -----------------------------------------
        5.1.3            5.1.3             True
        5.1              5.1.3             True
        5                5.1               True
        5.1.3            5.1               False
        5.2.3            5.1.3             False

    Args:
      environ_version: The version specified by the user via environment
        variables.
      detected_version: The version autodetected from the CUDA installation on
        the system.
    Returns: True if user-specified version matches detected version and False
      otherwise.
  """
    environ_version_parts = environ_version.split(".")
    detected_version_parts = detected_version.split(".")
    if len(detected_version_parts) < len(environ_version_parts):
        return False
    for i, part in enumerate(detected_version_parts):
        if i >= len(environ_version_parts):
            break
        if part != environ_version_parts[i]:
            return False
    return True


_NVCC_VERSION_PREFIX = "Cuda compilation tools, release "


def _cuda_version(repository_ctx, cuda_toolkit_path, cpu_value):
    """Detects the version of CUDA installed on the system.

    Args:
      repository_ctx: The repository context.
      cuda_toolkit_path: The CUDA install directory.

    Returns:
      String containing the version of CUDA.
    """

    # Run nvcc --version and find the line containing the CUDA version.
    nvcc_path = repository_ctx.path("%s/bin/nvcc" % cuda_toolkit_path)
    if not nvcc_path.exists:
        auto_configure_fail("Cannot find nvcc at %s" % str(nvcc_path))
    result = repository_ctx.execute([str(nvcc_path), "--version"])
    if result.stderr:
        auto_configure_fail("Error running nvcc --version: %s" % result.stderr)
    lines = result.stdout.splitlines()
    version_line = lines[len(lines) - 1]
    if version_line.find(_NVCC_VERSION_PREFIX) == -1:
        auto_configure_fail(
            "Could not parse CUDA version from nvcc --version. Got: %s" %
            result.stdout, )

    # Parse the CUDA version from the line containing the CUDA version.
    prefix_removed = version_line.replace(_NVCC_VERSION_PREFIX, "")
    parts = prefix_removed.split(",")
    if len(parts) != 2 or len(parts[0]) < 2:
        auto_configure_fail(
            "Could not parse CUDA version from nvcc --version. Got: %s" %
            result.stdout, )
    full_version = parts[1].strip()
    if full_version.startswith("V"):
        full_version = full_version[1:]

    # Check whether TF_CUDA_VERSION was set by the user and fail if it does not
    # match the detected version.
    environ_version = ""
    if _TF_CUDA_VERSION in repository_ctx.os.environ:
        environ_version = repository_ctx.os.environ[_TF_CUDA_VERSION].strip()
    if environ_version and not matches_version(environ_version, full_version):
        auto_configure_fail(
            ("CUDA version detected from nvcc (%s) does not match " +
             "TF_CUDA_VERSION (%s)") % (full_version, environ_version), )

    # We only use the version consisting of the major and minor version numbers.
    version_parts = full_version.split(".")
    if len(version_parts) < 2:
        auto_configure_fail(
            "CUDA version detected from nvcc (%s) is incomplete.")
    version = "%s.%s" % (version_parts[0], version_parts[1])
    return version


_DEFINE_CUDNN_MAJOR = "#define CUDNN_MAJOR"
_DEFINE_CUDNN_MINOR = "#define CUDNN_MINOR"
_DEFINE_CUDNN_PATCHLEVEL = "#define CUDNN_PATCHLEVEL"


def find_cuda_define(repository_ctx, header_dir, header_file, define):
    """Returns the value of a #define in a header file.

    Greps through a header file and returns the value of the specified #define.
    If the #define is not found, then raise an error.

    Args:
      repository_ctx: The repository context.
      header_dir: The directory containing the header file.
      header_file: The header file name.
      define: The #define to search for.

    Returns:
      The value of the #define found in the header.
    """

    # Confirm location of the header and grep for the line defining the macro.
    h_path = repository_ctx.path("%s/%s" % (header_dir, header_file))
    if not h_path.exists:
        auto_configure_fail(
            "Cannot find %s at %s" % (header_file, str(h_path)))
    result = repository_ctx.execute(
        # Grep one more lines as some #defines are splitted into two lines.
        ["grep", "--color=never", "-A1", "-E", define,
         str(h_path)], )
    if result.stderr:
        auto_configure_fail(
            "Error reading %s: %s" % (str(h_path), result.stderr))

    # Parse the version from the line defining the macro.
    if result.stdout.find(define) == -1:
        auto_configure_fail(
            "Cannot find line containing '%s' in %s" % (define, h_path))

    # Split results to lines
    lines = result.stdout.split("\n")
    num_lines = len(lines)
    for l in range(num_lines):
        line = lines[l]
        if define in line:  # Find the line with define
            version = line
            if l != num_lines - 1 and line[
                    -1] == "\\":  # Add next line, if multiline
                version = version[:-1] + lines[l + 1]
            break

    # Remove any comments
    version = version.split("//")[0]

    # Remove define name
    version = version.replace(define, "").strip()

    # Remove the code after the version number.
    version_end = version.find(" ")
    if version_end != -1:
        if version_end == 0:
            auto_configure_fail(
                "Cannot extract the version from line containing '%s' in %s" %
                (define, str(h_path)), )
        version = version[:version_end].strip()
    return version


def _cudnn_version(repository_ctx, cudnn_install_basedir, cpu_value):
    """Detects the version of cuDNN installed on the system.

    Args:
      repository_ctx: The repository context.
      cpu_value: The name of the host operating system.
      cudnn_install_basedir: The cuDNN install directory.

    Returns:
      A string containing the version of cuDNN.
    """
    cudnn_header_dir = _find_cudnn_header_dir(
        repository_ctx,
        cudnn_install_basedir,
    )
    major_version = find_cuda_define(
        repository_ctx,
        cudnn_header_dir,
        "cudnn.h",
        _DEFINE_CUDNN_MAJOR,
    )
    minor_version = find_cuda_define(
        repository_ctx,
        cudnn_header_dir,
        "cudnn.h",
        _DEFINE_CUDNN_MINOR,
    )
    patch_version = find_cuda_define(
        repository_ctx,
        cudnn_header_dir,
        "cudnn.h",
        _DEFINE_CUDNN_PATCHLEVEL,
    )
    full_version = "%s.%s.%s" % (major_version, minor_version, patch_version)

    # Check whether TF_CUDNN_VERSION was set by the user and fail if it does not
    # match the detected version.
    environ_version = ""
    if _TF_CUDNN_VERSION in repository_ctx.os.environ:
        environ_version = repository_ctx.os.environ[_TF_CUDNN_VERSION].strip()
    if environ_version and not matches_version(environ_version, full_version):
        cudnn_h_path = repository_ctx.path(
            "%s/include/cudnn.h" % cudnn_install_basedir)
        auto_configure_fail(
            ("cuDNN version detected from %s (%s) does not match " +
             "TF_CUDNN_VERSION (%s)") % (str(cudnn_h_path), full_version,
                                         environ_version), )

    # We only use the major version since we use the libcudnn libraries that are
    # only versioned with the major version (e.g. libcudnn.so.5).
    version = major_version
    return version


def compute_capabilities(repository_ctx):
    """Returns a list of strings representing cuda compute capabilities."""
    if _TF_CUDA_COMPUTE_CAPABILITIES not in repository_ctx.os.environ:
        return _DEFAULT_CUDA_COMPUTE_CAPABILITIES
    capabilities_str = repository_ctx.os.environ[_TF_CUDA_COMPUTE_CAPABILITIES]
    capabilities = capabilities_str.split(",")
    for capability in capabilities:
        # Workaround for Skylark's lack of support for regex. This check should
        # be equivalent to checking:
        #     if re.match("[0-9]+.[0-9]+", capability) == None:
        parts = capability.split(".")
        if len(parts) != 2 or not parts[0].isdigit() or not parts[1].isdigit():
            auto_configure_fail("Invalid compute capability: %s" % capability)
    return capabilities


def _lib_name(lib, cpu_value, version="", static=False):
    """Constructs the platform-specific name of a library.

    Args:
      lib: The name of the library, such as "cudart"
      cpu_value: The name of the host operating system.
      version: The version of the library.
      static: True the library is static or False if it is a shared object.

    Returns:
      The platform-specific name of the library.
    """
    if cpu_value not in ["linux", "k8", "aarch64"]:
        auto_configure_fail("Invalid cpu_value: %s" % cpu_value)

    if static:
        return "lib%s.a" % lib
    else:
        if version:
            version = ".%s" % version
        return "lib%s.so%s" % (lib, version)


def _find_cuda_lib(lib,
                   repository_ctx,
                   cpu_value,
                   target_arch,
                   basedir,
                   version="",
                   static=False):
    """Finds the given CUDA or cuDNN library on the system.

    Args:
      lib: The name of the library, such as "cudart"
      repository_ctx: The repository context.
      cpu_value: The name of the host operating system.
      target_arch: target system architecture: e.g. x86_64 or aarch64
      basedir: The install directory of CUDA or cuDNN.
      version: The version of the library.
      static: True if static library, False if shared object.

    Returns:
      Returns a struct with the following fields:
        file_name: The basename of the library found on the system.
        path: The full path to the library.
    """
    if not target_arch in _VALID_CUDA_TARGET_ARCH:
        _err_msg = "target arch: {} not supported: must be one of {}"
        auto_configure_fail(
            _err_msg.format(target_arch, _VALID_CUDA_TARGET_ARCH))

    file_name_with_version = _lib_name(lib, cpu_value, version, static)
    file_name_sans_version = _lib_name(lib, cpu_value, "", static)

    _stamp = '%s-linux' % target_arch
    _cuda_lib_relative_paths = [
        'targets/%s/lib/stubs/%s' % (_stamp, file_name_sans_version),
        'targets/%s/lib/%s' % (_stamp, file_name_with_version),
    ]
    for relative_path in _cuda_lib_relative_paths:
        path = repository_ctx.path("%s/%s" % (basedir, relative_path))
        if path.exists:
            print("cuda lib", target_arch, path)
            return struct(
                file_name=file_name_with_version, path=str(path.realpath))
    auto_configure_fail("Cannot find cuda library %s" % file_name_with_version)


def _find_cupti_header_dir(repository_ctx, cuda_config, target_arch):
    """Returns the path to the directory containing cupti.h

    On most systems, the cupti library is not installed in the same directory as
    the other CUDA libraries but rather in a special extras/CUPTI directory.

    Args:
      repository_ctx: The repository context.
      cuda_config: The CUDA config as returned by _get_cuda_config
      target_arch: The target platform architecture, e.g. x86_64 or aarch64

    Returns:
      The path of the directory containing the cupti header.
    """
    cuda_toolkit_path = cuda_config.cuda_toolkit_path
    for relative_path in CUPTI_HEADER_PATHS:
        if repository_ctx.path(
                "%s/%scupti.h" % (cuda_toolkit_path, relative_path)).exists:
            return ("%s/%s" % (cuda_toolkit_path, relative_path))[:-1]
    auto_configure_fail("Cannot find cupti.h under %s" % ", ".join(
        [cuda_toolkit_path + "/" + s for s in CUPTI_HEADER_PATHS]))


def _find_cupti_lib(repository_ctx, cuda_config, target_arch):
    """Finds the cupti library on the system.

    On most systems, the cupti library is not installed in the same directory as
    the other CUDA libraries but rather in a special extras/CUPTI directory.

    Args:
      repository_ctx: The repository context.
      cuda_config: The cuda configuration as returned by _get_cuda_config.
      target_arch: The target platform architecture, e.g. x86_64 or aarch64

    Returns:
      Returns a struct with the following fields:
        file_name: The basename of the library found on the system.
        path: The full path to the library.
    """
    file_name = _lib_name(
        "cupti",
        cuda_config.cpu_value,
        cuda_config.cuda_version,
    )
    _stamp = '%s-linux' % target_arch
    _cupti_lib_relative_paths = [
        'targets/%s/extras/CUPTI/lib64/' % _stamp,
    ] + CUPTI_LIB_PATHS
    cuda_toolkit_path = cuda_config.cuda_toolkit_path
    for relative_path in _cupti_lib_relative_paths:
        path = repository_ctx.path(
            "%s/%s%s" % (cuda_toolkit_path, relative_path, file_name), )
        print('cupti lib', str(path.realpath))
        if path.exists:
            return struct(file_name=file_name, path=str(path.realpath))

    auto_configure_fail("Cannot find cupti library %s" % file_name)


def _find_libs(repository_ctx, cuda_config, target_arch):
    """Returns the CUDA and cuDNN libraries on the system.

    Args:
      repository_ctx: The repository context.
      cuda_config: The CUDA config as returned by _get_cuda_config
      target_arch: The CUDA target architecture: e.g. x86_64 or aarch64

    Returns:
      Map of library names to structs of filename and path.
    """
    cpu_value = cuda_config.cpu_value
    return {
        "cuda":
        _find_cuda_lib("cuda", repository_ctx, cpu_value, target_arch,
                       cuda_config.cuda_toolkit_path),
        "cudart":
        _find_cuda_lib(
            "cudart",
            repository_ctx,
            cpu_value,
            target_arch,
            cuda_config.cuda_toolkit_path,
            cuda_config.cuda_version,
        ),
        "cudart_static":
        _find_cuda_lib(
            "cudart_static",
            repository_ctx,
            cpu_value,
            target_arch,
            cuda_config.cuda_toolkit_path,
            cuda_config.cuda_version,
            static=True,
        ),
        "cublas":
        _find_cuda_lib(
            "cublas",
            repository_ctx,
            cpu_value,
            target_arch,
            cuda_config.cuda_toolkit_path,
            cuda_config.cuda_version,
        ),
        "cusolver":
        _find_cuda_lib(
            "cusolver",
            repository_ctx,
            cpu_value,
            target_arch,
            cuda_config.cuda_toolkit_path,
            cuda_config.cuda_version,
        ),
        "curand":
        _find_cuda_lib(
            "curand",
            repository_ctx,
            cpu_value,
            target_arch,
            cuda_config.cuda_toolkit_path,
            cuda_config.cuda_version,
        ),
        "cufft":
        _find_cuda_lib(
            "cufft",
            repository_ctx,
            cpu_value,
            target_arch,
            cuda_config.cuda_toolkit_path,
            cuda_config.cuda_version,
        ),
        "cudnn":
        _find_cuda_lib(
            "cudnn",
            repository_ctx,
            cpu_value,
            target_arch,
            cuda_config.cudnn_install_basedir,
            cuda_config.cudnn_version,
        ),
        "cupti":
        _find_cupti_lib(repository_ctx, cuda_config, target_arch),
    }


def _find_cuda_include_path(repository_ctx, cuda_config, target_arch):
    """Returns the path to the directory containing cuda.h

    Args:
      repository_ctx: The repository context.
      cuda_config: The CUDA config as returned by _get_cuda_config
      target_arch: The CUDA target architecture, e.g. x86_64 or aarch64

    Returns:
      The path of the directory containing the CUDA headers.
    """
    cuda_toolkit_path = cuda_config.cuda_toolkit_path
    _cuda_include_relative_paths = [
        'targets/%s-linux/include/' % target_arch,
    ] + CUDA_INCLUDE_PATHS
    for relative_path in _cuda_include_relative_paths:
        if repository_ctx.path(
                "%s/%scuda.h" % (cuda_toolkit_path, relative_path)).exists:
            inc_path = ("%s/%s" % (cuda_toolkit_path, relative_path))[:-1]
            print('cuda include path', inc_path)
            return inc_path
    auto_configure_fail("Cannot find cuda.h under %s" % cuda_toolkit_path)


def _find_cudnn_header_dir(repository_ctx, cudnn_install_basedir):
    """Returns the path to the directory containing cudnn.h

    Args:
      repository_ctx: The repository context.
      cudnn_install_basedir: The cudnn install directory as returned by
        _cudnn_install_basedir.

    Returns:
      The path of the directory containing the cudnn header.
    """
    for relative_path in CUDA_INCLUDE_PATHS:
        if repository_ctx.path("%s/%scudnn.h" % (cudnn_install_basedir,
                                                 relative_path)).exists:
            return ("%s/%s" % (cudnn_install_basedir, relative_path))[:-1]
    if repository_ctx.path("/usr/include/cudnn.h").exists:
        return "/usr/include"
    auto_configure_fail("Cannot find cudnn.h under %s" % cudnn_install_basedir)


def _find_nvvm_libdevice_dir(repository_ctx, cuda_config):
    """Returns the path to the directory containing libdevice in bitcode format.

    Args:
      repository_ctx: The repository context.
      cuda_config: The CUDA config as returned by _get_cuda_config

    Returns:
      The path of the directory containing the CUDA headers.
    """
    cuda_toolkit_path = cuda_config.cuda_toolkit_path
    for libdevice_file in NVVM_LIBDEVICE_FILES:
        for relative_path in NVVM_LIBDEVICE_PATHS:
            if repository_ctx.path(
                    "%s/%s%s" % (cuda_toolkit_path, relative_path,
                                 libdevice_file)).exists:
                return ("%s/%s" % (cuda_toolkit_path, relative_path))[:-1]
    auto_configure_fail(
        "Cannot find libdevice*.bc files under %s" % cuda_toolkit_path)


def _cudart_static_linkopt(cpu_value):
    """Returns additional platform-specific linkopts for cudart."""
    return "" if cpu_value == "Darwin" else "\"-lrt\","


def _get_cuda_config(repository_ctx):
    """Detects and returns information about the CUDA installation on the system.

    Args:
      repository_ctx: The repository context.

    Returns:
      A struct containing the following fields:
        cuda_toolkit_path: The CUDA toolkit installation directory.
        cudnn_install_basedir: The cuDNN installation directory.
        cuda_version: The version of CUDA on the system.
        cudnn_version: The version of cuDNN on the system.
        compute_capabilities: A list of the system's CUDA compute capabilities.
        cpu_value: The name of the host operating system.
    """
    cpu_value = get_cpu_value(repository_ctx)
    toolkit_path = cuda_toolkit_path(repository_ctx)
    cuda_version = _cuda_version(repository_ctx, toolkit_path, cpu_value)
    cudnn_install_basedir = _cudnn_install_basedir(repository_ctx)
    cudnn_version = _cudnn_version(repository_ctx, cudnn_install_basedir,
                                   cpu_value)

    return struct(
        cuda_toolkit_path=toolkit_path,
        cudnn_install_basedir=cudnn_install_basedir,
        cuda_version=cuda_version,
        cudnn_version=cudnn_version,
        compute_capabilities=compute_capabilities(repository_ctx),
        cpu_value=cpu_value,
    )


def _get_extended_cuda_config(repository_ctx, cuda_config, target_arch):
    cuda_include_path = _find_cuda_include_path(repository_ctx, cuda_config,
                                                target_arch)
    cudnn_header_dir = _find_cudnn_header_dir(
        repository_ctx,
        cuda_config.cudnn_install_basedir,
    )
    cupti_header_dir = _find_cupti_header_dir(repository_ctx, cuda_config,
                                              target_arch)
    nvvm_libdevice_dir = _find_nvvm_libdevice_dir(repository_ctx, cuda_config)
    return struct(
        core=cuda_config,
        cuda_include_path=cuda_include_path,
        cudnn_header_dir=cudnn_header_dir,
        cupti_header_dir=cupti_header_dir,
        nvvm_libdevice_dir=nvvm_libdevice_dir,
    )


def _tpl(repository_ctx, target_arch, tpl, substitutions={}, out=None):
    if not out:
        out = tpl.replace(":", "/")
    if target_arch != None:
        out = '{}/{}'.format(target_arch, out)
    print('template output:', out)
    repository_ctx.template(
        out,
        Label("//third_party/cross_cuda/%s.tpl" % tpl),
        substitutions,
    )


def _file(repository_ctx, label):
    repository_ctx.template(
        label.replace(":", "/"),
        Label("//third_party/cross_cuda/%s.tpl" % label),
        {},
    )


def _execute(repository_ctx,
             cmdline,
             error_msg=None,
             error_details=None,
             empty_stdout_fine=False):
    """Executes an arbitrary shell command.

    Args:
      repository_ctx: the repository_ctx object
      cmdline: list of strings, the command to execute
      error_msg: string, a summary of the error if the command fails
      error_details: string, details about the error or steps to fix it
      empty_stdout_fine: bool, if True, an empty stdout result is fine,
        otherwise it's an error
    Return: the result of repository_ctx.execute(cmdline)
  """
    result = repository_ctx.execute(cmdline)
    if result.stderr or not (empty_stdout_fine or result.stdout):
        auto_configure_fail(
            "\n".join([
                error_msg.strip()
                if error_msg else "Repository command failed",
                result.stderr.strip(),
                error_details if error_details else "",
            ]), )
    return result


def _norm_path(path):
    """Returns a path with '/' and remove the trailing slash."""
    path = path.replace("\\", "/")
    if path[-1] == "/":
        path = path[:-1]
    return path


def symlink_genrule_for_dir(repository_ctx,
                            target_arch,
                            src_dir,
                            dest_dir,
                            genrule_name,
                            src_files=[],
                            dest_files=[]):
    """Returns a genrule to symlink a set of files.

    If src_dir is passed, files will be read from the given directory; otherwise
    we assume files are in src_files and dest_files
    """
    genrule_name = "%s-%s" % (genrule_name, target_arch)
    if src_dir != None:
        src_dir = _norm_path(src_dir)
        dest_dir = _norm_path(dest_dir)
        files = "\n".join(
            sorted(_read_dir(repository_ctx, src_dir).splitlines()))

        # Create a list with the src_dir stripped to use for outputs.
        dest_files = files.replace(src_dir, "").splitlines()
        src_files = files.splitlines()

    command = []
    # We clear folders that might have been generated previously to avoid
    # undesired inclusions
    for _dir in ["extras", "include", "lib", "nvvm"]:
        _dir_text = '$(@D)/{}'.format(_dir)
        _cmd_text = 'if [ -d "%s" ]; then rm "%s" -drf; fi' % (_dir_text,
                                                               _dir_text)
        command.append(_cmd_text)

    outs = []
    for src_fname, dest_fname in zip(src_files, dest_files):
        if not dest_fname:
            continue
        # If we have only one file to link we do not want to use the dest_dir, as
        # $(@D) will include the full path to the file.
        stripped_dest = (
            dest_dir + dest_fname) if len(dest_files) != 1 else dest_fname
        full_dest = '$(@D)/' + stripped_dest

        # Copy the headers to create a sandboxable setup.
        command.append('cp -f "%s" "%s"' % (src_fname, full_dest))
        outs.append('        "' + stripped_dest + '",')

    genrule = _genrule(
        src_dir,
        genrule_name,
        " && ".join(command),
        "\n".join(outs),
    )
    return genrule


def _genrule(src_dir, genrule_name, command, outs):
    """Returns a string with a genrule.

    Genrule executes the given command and produces the given outputs.
    """
    return ("genrule(\n" + '    name = "' + genrule_name + '",\n' +
            "    outs = [\n" + outs + "\n    ],\n" + '    cmd = """\n' +
            command + '\n   """,\n' + ")\n")


def _read_dir(repository_ctx, src_dir):
    """Returns a string with all files in a directory.

    Finds all files inside a directory, traversing subfolders and following
    symlinks. The returned string contains the full path of all files
    separated by line breaks.
    """
    return _execute(
        repository_ctx,
        ["find", src_dir, "-follow", "-type", "f"],
        empty_stdout_fine=True,
    ).stdout


def _flag_enabled(repository_ctx, flag_name):
    if flag_name in repository_ctx.os.environ:
        value = repository_ctx.os.environ[flag_name].strip()
        return value == "1"
    return False


def _cross_compilation_enabled(repository_ctx):
    return _flag_enabled(repository_ctx, _TF_CROSS_COMPILATION)


def _compute_cuda_extra_copts(repository_ctx, compute_capabilities):
    # Capabilities are handled in the "crosstool_wrapper_driver_is_not_gcc" for nvcc
    # TODO(csigg): Make this consistent with cuda clang and pass to crosstool.
    return str([])


def _setup_crosstool_wrapper(repository_ctx, target_arch, cuda_defines,
                             host_compiler_includes, cuda_config,
                             compiler_fname, nvcc_wrapper_fname):
    cuda_defines["%{host_compiler_path}"] = nvcc_wrapper_fname
    cuda_defines["%{host_compiler_warnings}"] = ""

    # nvcc has the system include paths built in and will automatically
    # search them; we cannot work around that, so we add the relevant cuda
    # system paths to the allowed compiler specific include paths.
    # cuda_defines["%{host_compiler_includes}"] = (
    cuda_defines[_cuda_defines_compiler_includes_placeholder_] = (
        host_compiler_includes + "\n" + _cuda_include_path(
            repository_ctx, cuda_config.core,
            compiler_fname) + "\n  cxx_builtin_include_directory: \"%s\"" %
        cuda_config.cupti_header_dir +
        "\n  cxx_builtin_include_directory: \"%s\"" %
        cuda_config.cudnn_header_dir)

    # For gcc, do not canonicalize system header paths; some versions of gcc
    # pick the shortest possible path for system includes when creating the
    # .d file - given that includes that are prefixed with "../" multiple
    # time quickly grow longer than the root of the tree, this can lead to
    # bazel's header check failing.
    cuda_defines["%{extra_no_canonical_prefixes_flags}"] = (
        "flag: \"-fno-canonical-system-headers\"")
    nvcc_path = str(
        repository_ctx.path(
            "%s/bin/nvcc" % cuda_config.core.cuda_toolkit_path))
    wrapper_defines = {
        "%{cpu_compiler}":
        str(compiler_fname),
        "%{cuda_version}":
        cuda_config.core.cuda_version,
        "%{nvcc_path}":
        nvcc_path,
        "%{gcc_host_compiler_path}":
        str(compiler_fname),
        "%{cuda_compute_capabilities}":
        ", ".join(
            ["\"%s\"" % c for c in cuda_config.core.compute_capabilities], ),
        "%{nvcc_tmp_dir}":
        "/tmp",
    }
    _tpl(
        repository_ctx,
        None,
        "crosstool:clang/bin/crosstool_wrapper_driver_is_not_gcc",
        wrapper_defines,
        "crosstool/" + nvcc_wrapper_fname,
    )


def _create_local_cuda_repository(repository_ctx, target_arch):
    """Creates the repository containing files set up to build with CUDA.

       target_arch: target architecture, e.g. x86_64, aarch64
    """
    cuda_config_ext = _get_extended_cuda_config(
        repository_ctx, _get_cuda_config(repository_ctx), target_arch)
    cuda_config = cuda_config_ext.core
    cuda_include_path = cuda_config_ext.cuda_include_path
    cudnn_header_dir = cuda_config_ext.cudnn_header_dir
    cupti_header_dir = cuda_config_ext.cupti_header_dir
    nvvm_libdevice_dir = cuda_config_ext.cupti_header_dir

    # Set up symbolic links for the cuda toolkit by creating genrules to do
    # symlinking. We create one genrule for each directory we want to track under
    # cuda_toolkit_path
    cuda_toolkit_path = cuda_config.cuda_toolkit_path
    genrules = [
        symlink_genrule_for_dir(
            repository_ctx,
            target_arch,
            cuda_include_path,
            "cuda/include",
            "cuda-include",
        )
    ]
    genrules.append(
        symlink_genrule_for_dir(
            repository_ctx,
            target_arch,
            nvvm_libdevice_dir,
            "cuda/nvvm/libdevice",
            "cuda-nvvm",
        ))
    genrules.append(
        symlink_genrule_for_dir(
            repository_ctx,
            target_arch,
            cupti_header_dir,
            "cuda/extras/CUPTI/include",
            "cuda-extras",
        ))

    cuda_libs = _find_libs(repository_ctx, cuda_config, target_arch)
    cuda_lib_src = []
    cuda_lib_dest = []
    for lib in cuda_libs.values():
        cuda_lib_src.append(lib.path)
        cuda_lib_dest.append("cuda/lib/%s" % lib.file_name)
    genrules.append(
        symlink_genrule_for_dir(
            repository_ctx,
            target_arch,
            None,
            "",
            "cuda-lib",
            cuda_lib_src,
            cuda_lib_dest,
        ))

    # Set up the symbolic links for cudnn if cndnn was not installed to
    # CUDA_TOOLKIT_PATH.
    included_files = _read_dir(repository_ctx, cuda_include_path).replace(
        cuda_include_path,
        "",
    ).splitlines()
    if "/cudnn.h" not in included_files:
        genrules.append(
            symlink_genrule_for_dir(
                repository_ctx,
                target_arch,
                None,
                "cuda/include/",
                "cudnn-include",
                [cudnn_header_dir + "/cudnn.h"],
                ["cudnn.h"],
            ))
    else:
        genrules.append(
            "filegroup(\n" +
            ('    name = "cudnn-include-{}",\n'.format(target_arch)) +
            "    srcs = [],\n" + ")\n", )

    # Set up BUILD file for cuda/
    _tpl(
        repository_ctx, None, "cuda:build_defs.bzl", {
            "%{cuda_is_configured}":
            "True",
            "%{cuda_extra_copts}":
            _compute_cuda_extra_copts(
                repository_ctx,
                cuda_config.compute_capabilities,
            ),
        })
    _tpl(
        repository_ctx, None, "cuda:BUILD.arch", {
            "%{cuda_driver_lib}":
            cuda_libs["cuda"].file_name,
            "%{cudart_static_lib}":
            cuda_libs["cudart_static"].file_name,
            "%{cudart_static_linkopt}":
            _cudart_static_linkopt(cuda_config.cpu_value, ),
            "%{cudart_lib}":
            cuda_libs["cudart"].file_name,
            "%{cublas_lib}":
            cuda_libs["cublas"].file_name,
            "%{cusolver_lib}":
            cuda_libs["cusolver"].file_name,
            "%{cudnn_lib}":
            cuda_libs["cudnn"].file_name,
            "%{cufft_lib}":
            cuda_libs["cufft"].file_name,
            "%{curand_lib}":
            cuda_libs["curand"].file_name,
            "%{cupti_lib}":
            cuda_libs["cupti"].file_name,
            "%{cuda_include_genrules}":
            "\n".join(genrules),
            "%{cuda_headers}":
            (('":cuda-include-%s",\n' % target_arch) +
             ('        ":cudnn-include-%s",' % target_arch)),
        },
        "{}/cuda/BUILD".format(target_arch)
    )

    # Set up crosstool/
    cc = find_cc(repository_ctx)
    cc_fullpath = cc

    host_cc_path_envvar = _CROSS_NVCC_HOST_COMPILER_PATH
    target_cc_path_envvar = _CROSS_NVCC_TARGET_COMPILER_PATH

    host_cc = cc_fullpath
    if host_cc_path_envvar in repository_ctx.os.environ:
        host_cc = repository_ctx.os.environ[host_cc_path_envvar].strip()

    target_cc = cc_fullpath
    if target_cc_path_envvar in repository_ctx.os.environ:
        target_cc = repository_ctx.os.environ[target_cc_path_envvar].strip()

    host_compiler_includes = _host_compiler_includes(repository_ctx,
                                                     cc_fullpath)
    cuda_defines = {}

    # Bazel sets '-B/usr/bin' flag to workaround build errors on RHEL (see
    # https://github.com/bazelbuild/bazel/issues/760).
    # However, this stops our custom clang toolchain from picking the provided
    # LLD linker, so we're only adding '-B/usr/bin' when using non-downloaded
    # toolchain.
    # TODO: when bazel stops adding '-B/usr/bin' by default, remove this
    #       flag from the CROSSTOOL completely (see
    #       https://github.com/bazelbuild/bazel/issues/5634)
    if _flag_enabled(repository_ctx, _BUILD_WITH_RHEL_LINKER_BIN_FIX):
        # This configuration is failing linker picking
        cuda_defines["%{linker_bin_path_flag}"] = 'flag: "-B/usr/bin"'
    else:
        cuda_defines["%{linker_bin_path_flag}"] = ""

    # TODO: setup two instances of this compiler, one for host and the other target
    nvcc_host_wrapper_fname = "clang/bin/crosstool_host_wrapper_driver_is_not_gcc"
    nvcc_target_wrapper_fname = "clang/bin/crosstool_target_wrapper_driver_is_not_gcc"
    _tpl(
        repository_ctx, None, "crosstool:BUILD", {
            "%{cross_nvcc_host_linker_files}": ":" + nvcc_host_wrapper_fname,
            "%{cross_nvcc_target_linker_files}":
            ":" + nvcc_target_wrapper_fname,
            "%{win_linker_files}": ":empty",
        })
    # TODO(phi9t): setup host and target wrappers
    _setup_crosstool_wrapper(repository_ctx, target_arch, cuda_defines,
                             host_compiler_includes, cuda_config_ext, host_cc,
                             nvcc_host_wrapper_fname)
    cuda_defines["%{cross_nvcc_host_compiler_path}"] = nvcc_host_wrapper_fname
    cuda_defines["%{cross_nvcc_host_compiler_includes}"] = \
        cuda_defines[_cuda_defines_compiler_includes_placeholder_]

    _setup_crosstool_wrapper(repository_ctx, target_arch, cuda_defines,
                             host_compiler_includes, cuda_config_ext,
                             target_cc, nvcc_target_wrapper_fname)
    cuda_defines[
        "%{cross_nvcc_target_compiler_path}"] = nvcc_target_wrapper_fname
    cuda_defines["%{cross_nvcc_target_compiler_includes}"] = \
        cuda_defines[_cuda_defines_compiler_includes_placeholder_]

    # TODO: remove this
    cuda_defines["%{cross_cuda_install_dir}"] = cuda_config.cuda_toolkit_path
    _tpl(repository_ctx, None, "crosstool:CROSSTOOL", cuda_defines)

    # Set up cuda_config.h, which is used by
    # tensorflow/stream_executor/dso_loader.cc.
    _tpl(
        repository_ctx, None, "cuda:cuda_config.h", {
            "%{cuda_version}":
            cuda_config.cuda_version,
            "%{cudnn_version}":
            cuda_config.cudnn_version,
            "%{cuda_compute_capabilities}":
            ",".join([
                "CudaVersion(\"%s\")" % c
                for c in cuda_config.compute_capabilities
            ], ),
            "%{cuda_toolkit_path}":
            cuda_config.cuda_toolkit_path,
        },
        "{}/cuda/cuda/cuda_config.h".format(target_arch)
    )


def _cuda_autoconf_impl(repository_ctx):
    """Implementation of the cuda_autoconf repository rule."""
    genrules = []
    for target_arch in _VALID_CUDA_TARGET_ARCH:
        _create_local_cuda_repository(repository_ctx, target_arch)
        repository_ctx.file("{}/BUILD".format(target_arch), "")
    _tpl(repository_ctx, None, "cuda:BUILD", {})

cuda_configure = repository_rule(
    implementation=_cuda_autoconf_impl,
    environ=[
        _TF_CROSS_COMPILATION,
        _CROSS_NVCC_HOST_COMPILER_PATH,
        _CROSS_NVCC_TARGET_COMPILER_PATH,
        _GCC_HOST_COMPILER_PATH,
        "TF_NEED_CUDA",
        _CUDA_TOOLKIT_PATH,
        _CUDNN_INSTALL_PATH,
        _TF_CUDA_VERSION,
        _TF_CUDNN_VERSION,
        _TF_CUDA_COMPUTE_CAPABILITIES,
        _TF_CUDA_CONFIG_REPO,
        _BUILD_WITH_RHEL_LINKER_BIN_FIX,
        "NVVMIR_LIBRARY_DIR",
        _PYTHON_BIN_PATH,
    ],
)
"""Detects and configures the local CUDA toolchain.

Add the following to your WORKSPACE FILE:

```python
cuda_configure(name = "local_config_cuda")
```

Args:
  name: A unique name for this workspace rule.
"""
