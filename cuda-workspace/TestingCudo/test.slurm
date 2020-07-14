#!/bin/sh
#SBATCH --time=0:15:00
#SBATCH --mem-per-cpu=1024
#SBATCH --job-name=cuda
#SBATCH --partition=gpu_k20
#SBATCH --gres=gpu:1
#SBATCH --error=/work/unklopers/millermj/cuda-job.%J.err
#SBATCH --output=/work/unklopers/millermj/cuda-job.%J.out
DIR=/work/unklopers/millermj/Academic/cuda-workspace/TestingCudo/ 
 module load cuda/8.0
 module load compiler/gcc/5.4
 module load git
 
 $DIR/Fast -w 5 -n 10 -d 1 -i $DIR/output.txt -s $DIR/grid.txt 
