#include <iostream>
#include "cuda/cuda_config.h"
#include "cuda/include/cuda.h"
#include "cuda/include/cublas.h"
#include "platform/platform.hpp"

int main() {
    PlatformInfo platform_info;
    std::cout << "salut tout le monde: " << platform_info.repr() << std::endl;
}
