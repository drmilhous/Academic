#!/bin/sh
#SBATCH --time=50:00:00
#SBATCH --mem-per-cpu=1024
#SBATCH --job-name=cuda
#SBATCH --partition=gpu_k20
#SBATCH --gres=gpu:1
#SBATCH --error=/work/unklopers/millermj/cuda-job-w20n15.%J.err
#SBATCH --output=/work/unklopers/millermj/cuda-job-w20n15.%J.out
DIR=/work/unklopers/millermj/test/Academic/cuda-workspace/TestingCudo/ 
module load cuda/8.0
module load compiler/gcc/5.4
module load git
 
 $DIR/Fast -w 20 -n 15 -c 2496 -d 0 -i $DIR/output15.txt -s $DIR/grid15.txt 
