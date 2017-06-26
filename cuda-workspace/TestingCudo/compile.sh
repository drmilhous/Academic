echo "Grid" &&
nvcc -I"./" -G -g -O0 -std=c++11 --compile --relocatable-device-code=false -gencode arch=compute_50,code=compute_50 -gencode arch=compute_52,code=compute_52 -gencode arch=compute_50,code=sm_50 -gencode arch=compute_52,code=sm_52  -x cu -o "FastGrid.o" "./FastGrid.c" &&
echo "Main" &&
nvcc -I"./" -G -g -O0 -std=c++11 --compile --relocatable-device-code=false -gencode arch=compute_50,code=compute_50 -gencode arch=compute_52,code=compute_52 -gencode arch=compute_50,code=sm_50 -gencode arch=compute_52,code=sm_52  -x cu -o "FastGridMain.o" "./FastGridMain.c" &&
echo "Both" &&
nvcc --cudart static --relocatable-device-code=false -gencode arch=compute_50,code=compute_50 -gencode arch=compute_52,code=compute_52 -gencode arch=compute_50,code=sm_50 -gencode arch=compute_52,code=sm_52 -link -o  "Fast"  ./FastGridMain.o ./FastGrid.o 