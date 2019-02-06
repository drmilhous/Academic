################################################################################
# Automatically-generated file. Do not edit!
################################################################################

OPTS=-I"./" -G -g -O0 -std=c++11 --compile --relocatable-device-code=false -gencode arch=compute_50,code=compute_50 -gencode arch=compute_52,code=compute_52 -gencode arch=compute_50,code=sm_50 -gencode arch=compute_52,code=sm_52  -x cu
OPTS2=--cudart static --relocatable-device-code=false -gencode arch=compute_50,code=compute_50 -gencode arch=compute_52,code=compute_52 -gencode arch=compute_50,code=sm_50 -gencode arch=compute_52,code=sm_52 -link

# Add inputs and outputs from these tool invocations to the build variables 
NVCC=/usr/local/cuda-9.1/bin/nvcc
# All Target
all: Fast

Fast: FastGrid.o FastGridMain.o
	$(NVCC) $(OPTS2) -o  "Fast"  ./FastGridMain.o ./FastGrid.o 

FastGrid.o: FastGrid.c 
	$(NVCC) $(OPTS) -o "FastGrid.o" "./FastGrid.c"


FastGridMain.o: FastGridMain.c 
	$(NVCC) $(OPTS) -o "FastGridMain.o" "./FastGridMain.c"



clean:
	rm *.o Fast
