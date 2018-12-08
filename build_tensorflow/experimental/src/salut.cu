#include <iostream>
#include <vector>

#include <cuda_runtime.h>
// helper functions and utilities to work with CUDA
#include <helper_cuda.h>
#include <helper_functions.h>

__global__ void kernel(int *g_data) {
    const unsigned int idx = threadIdx.x;
    int data = g_data[idx];
    g_data[idx] = ((((data <<  0) >> 24) + 10) << 24)
                  | ((((data <<  8) >> 24) + 10) << 16)
                  | ((((data << 16) >> 24) + 10) <<  8)
                  | ((((data << 24) >> 24) + 10) <<  0);

}

int main() {
    const size_t len = 512;
    const unsigned int num_threads = len / 4;
    using byte = unsigned char;
    const auto mem_size = sizeof(byte) * len;
    constexpr byte init_val = 32;
    std::vector<byte> host_vec(len, init_val);
    byte *gpu_data;

    checkCudaErrors(cudaMalloc((void **) &gpu_data, mem_size));
    checkCudaErrors(cudaMemcpy(gpu_data, &host_vec[0], mem_size, cudaMemcpyHostToDevice));

    kernel<<<1, num_threads>>>((int *) gpu_data);

    // check if kernel execution generated and error
    getLastCudaError("Kernel execution failed");

    checkCudaErrors(cudaMemcpy(&host_vec[0], gpu_data, mem_size, cudaMemcpyDeviceToHost));
    for (auto i = 0; i < len; ++i) {
        int val = static_cast<int>(host_vec[i]);
        if (val != init_val + 10) {
            std::cerr << "FAILED: idx " << i
                      << " val = " << val << " != " << init_val + 10 << std::endl;
        }
    }
}