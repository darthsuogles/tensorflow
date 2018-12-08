
SMS ?= 60 61 70 72
GENCODE_FLAGS = $(foreach sm,$(SMS),$(eval GENCODE_FLAGS += -gencode arch=compute_$(sm),code=sm_$(sm)))

INC_FLAGS = -I/usr/local/cuda/samples/common/inc
NVCC_FLAGS = --std=c++14 $(GENCODE_FLAGS) -m64 $(INC_FLAGS)

REPO_ROOT = $(shell git rev-parse --show-toplevel)
CROSSTOOL_ROOT = $(REPO_ROOT)/toolchain/gcc-linaro-7.3.1-2018.05-x86_64_aarch64-linux-gnu
CROSSTOOL_CXX = $(CROSSTOOL_ROOT)/bin/aarch64-linux-gnu-g++

all: salut

.PHONY:
salut: salut.amd64 salut.aarch64 salut.remote_test

%.remote_test: %.aarch64
	scp $< xavier-sleeve:/tmp/ && ssh xavier-sleeve /tmp/$<

%.amd64: %.cu
	nvcc $(NVCC_FLAGS) -o $@ $^

# Please consult example cuda compiler flags
%.aarch64: %.cu
	nvcc $(NVCC_FLAGS) -ccbin $(CROSS_CXX) -o $@ $^

.PHONY:
clean:
	rm -f *.exec *.amd64 *.aarch64 *.o
