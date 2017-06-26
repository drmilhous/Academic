#include <stdio.h>
#include <stdint.h>
#include <stdlib.h>
#include <time.h>
#include <unistd.h>
#include "FastGrid.h"
#include <ctype.h>
#define DEL '-'
__global__ void compute(Grid * g, int threads, State * s, int maxDepth);
Grid * allocateGrid(int size);
void initGridData(Grid * g, int size);
void printDevProp(cudaDeviceProp devProp);
int getCores(cudaDeviceProp devProp);
__device__ int pow2(int x);
__device__ char convertDev(int x);
__device__ int testAndSet(Grid * g, int number, int x, int y);
State * allocateStateStack(int threads, int maxDepth, int N);

int main(int argc, char ** argv)
	{
		Grid * g;	
		int device;
		int N;
		int c;
		char * output;
		while ((c = getopt (argc, argv, "n:d:i:")) != -1)
		{
    		switch (c)
      		{
				  case 'n':
				  		N = atoi(optarg);
					  	break;
				  case 'd':
				  		device = atoi(optarg);
						break;
				  case 'i':
						output = optarg;
				  		break;
			}
		}
		cudaSetDevice(device);
		g = allocateGrid(N);
		printf("Allocated \n");
		int threads = 100;
		int blocks = threads/10;
		int threadBlocks = threads / blocks;
		printGrid(g,N);
		Path ** path = scanChars(output);
		printPath(path[0]);
		int depth = 100;
		State * stateStack = allocateStateStack(threads, depth, N); 
		compute<<<blocks, threadBlocks>>>(g, threads, stateStack, depth);
		cudaDeviceSynchronize();
		//printGrid(g,N);
		for(int i = 0; i < threads * depth; i++)
		{
			printGrid(&stateStack[i].grid, N);
		}
	}

State * allocateStateStack(int threads, int maxDepth, int N)
{
	State * s;
	cudaMallocManaged((void **) &s, sizeof(State) * threads * maxDepth);
	for(int i = 0; i < threads * maxDepth; i++)
	{
		initGridData(&s[i].grid,N);
		s[i].count = 0;
		s[i].iterations = 0;
	}
	return s;
}
__global__ void compute(Grid * g, int threads, State * s, int maxDepth)
{
	int idx = blockIdx.x * blockDim.x + threadIdx.x;
	
		if (idx < threads)
			{
				s = &s[idx * maxDepth];
				for(int i = 0; i < maxDepth; i++)
				{
					int value = testAndSet(&s[i].grid,0,1,3);
				}
				//printf("value = %d\n", value);
				/*value = testAndSet(g,1,1,7);
				printf("value = %d\n", value);
				value = testAndSet(g,0,1,7);
				printf("value = %d\n", value);*/
			}
}

__device__ int testAndSet(Grid * g, int number, int x, int y)
{
	int ok = 0;
	int value = g->Cells[x][y];
	int mask;
	if (value != DEL && value != number)
		{
			ok = 1;
		}
	else
		{
			mask = pow2(number);
			int cbits = g->col[y];
			int rbits = g->row[x];
			ok = (mask & (rbits | cbits));
			if(ok == 0)
			{
				g->col[y] |= mask;
				g->row[x] |= mask;
				g->Cells[x][y] = convertDev(number);
			}
		}
	return ok;
}

__device__ char convertDev(int x)
	{
		char res = 'a';
		if (x >= 0)
			{
				int amount = int(x) + (int) res;
				res = (char) amount;
			}
		else
			{
				res = ' ';
			}
		return res;
	}

Grid * allocateGrid(int size)
	{
		Grid * g = NULL;
		cudaMallocManaged((void **) &g, sizeof(Grid));
		initGridData(g, size);
		return g;
	}
void initGridData(Grid * g, int size)
{
		cudaMallocManaged((void **) &g->row, size * sizeof(int));
		cudaMallocManaged((void **) &g->col, size * sizeof(int));

		char ** cells;
		cudaMallocManaged((void **) &cells, size * sizeof(char *));
		for (int i = 0; i < size; i++)
			{
				cudaMallocManaged((void **) &cells[i], size * sizeof(char));
				g->col[i] = 0;
				g->row[i] = 0;
			}
		g->Cells = cells;
		for (int row = 0; row < size; row++)
			{
				for (int col = 0; col < size; col++)
					{
						g->Cells[row][col] = DEL;
					}
			}
		
		g->ok = '0';
		
	}


void printDevProp(cudaDeviceProp devProp)
	{
		printf("%s\n", devProp.name);
		printf("Major revision number:         %d\n", devProp.major);
		printf("Minor revision number:         %d\n", devProp.minor);
		printf("Total global memory:           %u", devProp.totalGlobalMem);
		printf(" bytes\n");
		printf("Number of multiprocessors:     %d\n", devProp.multiProcessorCount);
		printf("Total amount of shared memory per block: %u\n", devProp.sharedMemPerBlock);
		printf("Total registers per block:     %d\n", devProp.regsPerBlock);
		printf("Warp size:                     %d\n", devProp.warpSize);
		printf("Maximum memory pitch:          %u\n", devProp.memPitch);
		printf("Total amount of constant memory:         %u\n", devProp.totalConstMem);
		printf("Cores:         %d\n", getCores(devProp));
		return;
	}
int getCores(cudaDeviceProp devProp)
	{
		int cores = 0;
		int mp = devProp.multiProcessorCount;
		switch (devProp.major)
			{
		case 2: // Fermi
			if (devProp.minor == 1)
				cores = mp * 48;
			else
				cores = mp * 32;
			break;
		case 3: // Kepler
			cores = mp * 192;
			break;
		case 5: // Maxwell
			cores = mp * 128;
			break;
		case 6: // Pascal
			if (devProp.minor == 1)
				cores = mp * 128;
			else if (devProp.minor == 0)
				cores = mp * 64;
			else
				printf("Unknown device type\n");
			break;
		default:
			printf("Unknown device type\n");
			break;
			}
		return cores;
	}
__device__ int pow2(int x)
	{
		int sum = 1;
		if (x == 0)
			{
				sum = 1;
			}
		else
			{
				for (int i = 0; i < x; i++)
					{
						sum = sum * 2;
					}
			}
		return sum;
	}
