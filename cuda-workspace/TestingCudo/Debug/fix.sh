cat makefile | sed "s|/Developer/NVIDIA/CUDA-8.0|/usr|g" > makefile
cat subdir.mk | sed "s|/Developer/NVIDIA/CUDA-8.0|/usr|g" > subdir.mk 
