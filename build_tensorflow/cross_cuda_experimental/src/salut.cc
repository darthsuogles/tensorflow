#include <iostream>
//#include "cuda/include/cublas.h"
//#include "aarch64/cuda/include/cuda.h"
#include "platform/platform.hpp"

int main() {
    PlatformInfo platform_info;
    std::cout << "salut tout le monde: " << platform_info.repr() << std::endl;
}
