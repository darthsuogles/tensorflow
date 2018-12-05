#!/bin/bash

_bsd_="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${_bsd_}/configs/xavier.conf"
source "${_bsd_}/patch.sh"

# builtin variables
RED='\033[0;31m'
BLUE='\033[1;36m'
NC='\033[0m'
TF_PYTHON_VERSION=${TF_PYTHON_VERSION:-"3.5"}
TF_NEED_CLEAN_BUILD=no
TF_VERSION="${TF_VERSION:-v1.12.0}"
TF_BUILD_OUTPUT="${TF_BUILD_OUTPUT:-/tmp/tensorflow_pkg}"
CROSSTOOL_WHEEL_ARCH="${CROSSTOOL_WHEEL_ARCH:-any}"
TF_GIT_URL="${TF_GIT_URL:-https://github.com/tensorflow/tensorflow}"
WORKDIR="${_bsd_}"
BAZEL_BIN="$(command -v bazel)"

function log_failure_msg { echo -ne "[${RED}ERROR${NC}] $@\n"; }
function log_app_msg { echo -ne "[${BLUE}INFO${NC}] $@\n"; }

function fetch_toolchain {
    [[ "$CROSSTOOL_COMPILER" != "yes" ]] && return 0

    CROSSTOOL_DIR="${WORKDIR}/toolchain/${CROSSTOOL_DIR}/"

    [[ ! -d "${CROSSTOOL_DIR}/${CROSSTOOL_NAME}/bin/" ]] && {
        mkdir -p ${WORKDIR}/toolchain/
        curl -kfSL -o toolchain.tar.xz -O "${CROSSTOOL_URL}" || {
            log_failure_msg "error when download crosstool"
            exit 1
        }
        tar xf toolchain.tar.xz -C ${WORKDIR}/toolchain/ || {
            log_failure_msg "error when extract crosstool"
            exit 1
        }
        rm toolchain.tar.xz &>/dev/null
    }

}

function fetch_and_patch_tensorflow {
    pushd "${WORKDIR}"
    [[ -d tensorflow ]] || git clone https://github.com/tensorflow/tensorflow.git
    pushd tensorflow

    if [[ "yes" == "${TF_NEED_CLEAN_BUILD:-no}" ]]; then
        git checkout -B "autogen-toolchain-${TF_VERSION}" "${TF_VERSION}"
        git reset --hard "${TF_VERSION}"
        git clean -xfxd

        # sets git local config for apply patch
        git config user.email "auto@matique"
        git config user.name "automatique"

        _patch_custom_toolchain
        _patch_disable_arm_neon
    else
        log_app_msg "Using current tensorflow branch $(git rev-parse --short HEAD)"
    fi

    popd
    popd
}

function _patch_add_custom_toolchain {
    if [[ "$TF_PATCH" == "yes" ]]; then
        tf_patch || {
            log_failure_msg "error when apply patch"
            exit 1
        }
    fi

    if [[ ! -z "$CROSSTOOL_DIR" ]] && [[ ! -z "$CROSSTOOL_NAME" ]]; then
        tf_toolchain_patch "$CROSSTOOL_NAME" "$CROSSTOOL_DIR" "$CROSSTOOL_EXTRA_INCLUDE" || {
            log_failure_msg "error when apply crosstool patch"
            exit 1
        }
    fi
    git add .
    git commit -m "AUTOGEN TOOLCHAIN: ${CROSSTOOL_NAME}"
}

function _patch_disable_arm_neon {
    grep -rl . -e '-mfpu=neon' | xargs sed -i 's/-mfpu=neon//g'
    git add .
    git commit -m "AUTOGEN TOOLCHAIN: disable neon for arm build"
}

function configure_tensorflow {
    # configure tensorflow
    pushd "${WORKDIR}/tensorflow"

    ${BAZEL_BIN} clean
    export PYTHON_BIN_PATH="$(command -v python${TF_PYTHON_VERSION})"
    export ${TF_BUILD_VARS}

    # if need_cuda is enabled, search sdk
    if [[ "${TF_NEED_CUDA}" == "1" ]]; then
        local nvcc_path=$(command -v nvcc)

        local cuda_location="$(echo $nvcc_path | sed 's/\/bin\/nvcc//')"
        local cuda_version="$(cat "${cuda_location}/version.txt" | awk '{ print $3 }' | cut -d'.' -f-2)"
        local cudnn_version="$(readlink $(find "${cuda_location}/" -iname '*libcudnn.so') | cut -d'.' -f3)"

        export CUDA_TOOLKIT_PATH="${cuda_location}"
        export TF_CUDA_VERSION="${cuda_version}"
        export TF_CUDNN_VERSION="${cudnn_version}"
    fi

    ./configure
    # yes '' | ./configure || {
    #     log_failure_msg "error when configure tensorflow"
    #     exit 1
    # }
    popd
}

function build_tensorflow {
    pushd "${WORKDIR}/tensorflow"
    cat <<_BAZEL_BUILD_EOF_
##>>>>> Bazel Build Command
    $BAZEL_BIN build -c opt ${BAZEL_COPT_FLAGS} --verbose_failures ${BAZEL_EXTRA_FLAGS}"
##>>>>>
_BAZEL_BUILD_EOF_
    $BAZEL_BIN build -c opt ${BAZEL_COPT_FLAGS} --verbose_failures ${BAZEL_EXTRA_FLAGS} || return 1
    popd
    log_app_msg "Done."
}

function main {
    fetch_toolchain
    fetch_and_patch_tensorflow
    configure_tensorflow
    build_tensorflow
}

main
