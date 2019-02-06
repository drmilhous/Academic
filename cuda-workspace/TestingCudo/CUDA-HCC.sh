#!/bin/sh
#SBATCH --time=00:15:00
#SBATCH --mem-per-cpu=1024
#SBATCH --job-name=cuda
#SBATCH --partition=gpu_k20
#SBATCH --gres=gpu:3
#SBATCH --error=/work/unklopers/millermj/cuda-job.%J.err
#SBATCH --output=/work/unklopers/millermj/cuda-job.%J.out
 
module load cuda/8.0
module load compiler/gcc/5.4
module load git

/work/unklopers/millermj/Academic/cuda-workspace/TestingCudo/Debug/TestingCudo 19 0
