#!/bin/bash
# -*- shell-script -*-

set -eux

sdkm_download_root=/host/pkgs/driveworks/5.0

function install_host_toolchain {
    sudo apt-get update
    sudo apt-get install -y --no-install-recommends wget libusb-1.0-0
    # Please simply extract the content
    # sudo ${sdkm_download_root}/drive-t186ref-linux-5.0.10.3-12606092-host_native_cross-tensorrt--4.0.0.8.run

    # DriveWorks files are optional
    sudo dpkg -i ${sdkm_download_root}/driveworks_data-v1.2.400-a7f5475-478955-nogcid-linux-amd64-ubuntu1604.deb
    sudo dpkg -i ${sdkm_download_root}/driveworks-v1.2.400-a7f5475-478955-nogcid-linux-amd64-ubuntu1604.deb
    sudo dpkg -i ${sdkm_download_root}/driveworks_samples-v1.2.400-a7f5475-478955-nogcid-linux-amd64-ubuntu1604.deb
    sudo dpkg -i ${sdkm_download_root}/driveworks_cross_linux-v1.2.400-a7f5475-478955-12514001-drive-linux-5.0.10.3.deb
}

install_host_toolchain
