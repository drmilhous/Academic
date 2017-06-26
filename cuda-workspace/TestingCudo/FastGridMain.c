#include <stdio.h>
#include <stdint.h>
#include <stdlib.h>
#include <time.h>
#include <unistd.h>
#include "FastGrid.h"
#include <ctype.h>
#define DEL '-'

Grid * allocateGrid(int size);
void printDevProp(cudaDeviceProp devProp);
int getCores(cudaDeviceProp devProp);

int main(int argc, char ** argv)
	{
		Grid * g;	
		char *cvalue = NULL;
		int device;
		int N;
		int c;
		while ((c = getopt (argc, argv, "nd:")) != -1)
		{
    		switch (c)
      		{
				  case 'n':
				  //printf("%c", c);
				  	cvalue = optarg;
					printf("%c'%s'", c,optarg);
					fflush(stdout);
				  	N = atoi(cvalue);
					  break;
				  case 'd':
				  	cvalue = optarg;
				  	device = atoi(optarg);
				  break;
			}
		}
		cudaSetDevice(device);
		g = allocateGrid(N);
		printf("Allocated \n");
		printGrid(g,N);
	}



Grid * allocateGrid(int size)
	{
		Grid * g = NULL;
		cudaMallocManaged((void **) &g, sizeof(Grid));

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
		return g;
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
