#include <stdio.h>
#include <stdint.h>
#include <stdlib.h>
#include <time.h>
#include <unistd.h>
#include "FastGrid.h"
#include <ctype.h>
#define DEL '-'
__device__ void printGridDev(Grid * g, int N);
__global__ void compute(Grid * g,int N ,int threads, State * s, int maxDepth);
Grid * allocateGrid(int size);
void initGridData(Grid * g, int size);
void printDevProp(cudaDeviceProp devProp);
int getCores(cudaDeviceProp devProp);
__device__ int pow2(int x);
__device__ char convertDev(int x);
__device__ int testAndSet(Grid * g, int number, int x, int y);
State * allocateStateStack(int threads, int maxDepth, int N);
__device__ void computeLocal(State * s, int N, int depth, int max);
void initThreads(State * s, int threads, int depth, int N, Path ** path);
__device__ void cloneState(State s1, State s2, int N);
__device__ void cloneGrid(Grid * oldGrid, Grid * newGrid, int size);
__device__ void cloneLocation(Location* srcLoc, Location* destLoc);
__device__ void initLocation(State * s);
__device__ int setAll(Grid * g, Path * p, Location * l, int N);
__device__ int updateLocation(Location * loc, Path * p, int size);
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
		int threads = 1;
		int blocks = threads/1;
		int threadBlocks = threads / blocks;
		printGrid(g,N);
		Path ** path = scanChars(output);
		printPath(path[0]);
		int depth = 3;
		State * stateStack = allocateStateStack(threads, depth, N);
		initThreads(stateStack, threads, depth,N, path);
		stateStack[0].location.x = 1;
		stateStack[0].location.y = 2;
		compute<<<blocks, threadBlocks>>>(g,N ,threads, stateStack, depth);
		cudaDeviceSynchronize();
		//printGrid(g,N);
		for(int i = 0; i < threads * depth; i++)
		{
			//if(i % depth == 0)
			{
				printf("Grid %d\n", i);
				printGrid(&stateStack[i].grid, N);
			}
		}
	}

void initThreads(State * s, int threads, int depth, int N, Path ** path)
{
	State* t = s;
	Path * current;
	Path ** base;
	for(int i = 0; i < threads; i++)
	{
		base = path;
		current = path[0];
		t++;
		for(int d = 0; d < depth-1; d++)
		{
			t->path = current;
			t++;
			if(current == NULL || current->next == NULL)
			{
				base++;
				current = base[0];
			}
			else
			{
				current = current->next;
			}
			
		}
	}
	/*for (int row = 0; row < N; row++)
			{
				for (int col = 0; col < N; col++)
					{
						s->location.x = row;
						s->location.y = col;

						s = &s[depth];
					}
			}*/
}

State * allocateStateStack(int threads, int maxDepth, int N)
{
	State * s;
	cudaMallocManaged((void **) &s, sizeof(State) * threads * maxDepth);
	for(int i = 0; i < threads * maxDepth; i++)
	{
		initGridData(&s[i].grid,N);
		printGrid(&s[i].grid,N);
		s[i].count = 0;
		s[i].iterations = 0;
	}
	return s;
}
__global__ void compute(Grid * g, int N, int threads, State * s, int maxDepth)
{
	int idx = blockIdx.x * blockDim.x + threadIdx.x;

		if (idx < threads)
			{
				s = &s[idx * maxDepth];
				computeLocal(s,N, 0, maxDepth);
				/*for(int i = 0; i < maxDepth; i++)
				{
					int value = testAndSet(&s[i].grid,0,1,3);
				}*/
				//printf("value = %d\n", value);
				/*value = testAndSet(g,1,1,7);
				printf("value = %d\n", value);
				value = testAndSet(g,0,1,7);
				printf("value = %d\n", value);*/
			}
}
__device__ void computeLocal(State * s,int N, int depth, int max)
{
	int value;
	int hasNext = 0;
	depth++;
	initLocation(&s[depth]);
	int count = 0;
	int maxCount = 10;

	for(int i = 0; i < N && hasNext == 0; i++)
	{
		int pop = 0;
		hasNext = 0;
		printf("depth[%d] x[%d] y[%d] nx[%d] ny[%d]\n", depth,s[depth].location.x, s[depth].location.y, s[depth].location.nextX, s[depth].location.nextY );
		cloneState(s[depth-1], s[depth],N);
		value = setAll(&s[depth].grid, s[depth].path, &s[depth].location, N);
		//printf("Before\n");
		//printGridDev(&s[depth-1].grid, N);
		//printf("After\n");
		if(value == 0)
		{
			printGridDev(&s[depth].grid, N);
			if(depth < max)
			{
				depth++;
				s[depth].location.x = s[depth-1].location.lastX;
				s[depth].location.y = s[depth-1].location.lastY;
				initLocation(&s[depth]);
			}
			else
			{
				pop = 1;
			}
		}
		else
		{
			pop = 1;
		}
		if(pop == 1)
		{
			hasNext = updateLocation(&s[depth].location, s[depth].path, N);
			while(hasNext != 0 && depth > 0)
			{
				depth--;
				hasNext = updateLocation(&s[depth].location, s[depth].path, N);
			}
		}
	}

}
/*
	while(depth > 0 && depth == 100)
	{
		printf("depth[%d] x[%d] y[%d] nx[%d] ny[%d]\n", depth,s[depth].location.x, s[depth].location.y, s[depth].location.nextX, s[depth].location.nextY );
		cloneState(s[depth-1], s[depth],N);
		value = setAll(&s[depth].grid, s[depth].path, &s[depth].location, N);
		if(depth == max-1) // end case
		{
			if(value == 0)
			{
				//printf("Valid");
			}
			depth --;
		}
		else // recursive case
		{
			if(value == 0)
			{
				depth++;
			}
			else
			{
				value = updateLocation(&s[depth].location, s[depth].path, N);
				if(value == 0)
				{
					depth++;
				}
				while(value != 0 && depth > 0)
				{
					depth --;
					value = updateLocation(&s[depth].location, s[depth].path, N);
				}
			}
		}
		count ++;
		if(count > maxCount)
		{
			break;
		}

	}
}*/

__device__ int updateLocation(Location * loc, Path * p, int size)
	{
		int pop = 0;
		if (loc->type == PART)
			{
				if (p->direction == LEFT)
					{
						loc->nextY++;
						if (loc->nextY >= size)
							pop = 1;
					}
				else
					{
						loc->nextX++;
						if (loc->nextX >= size)
							pop = 1;
					}
			}
		else
			{
				if (p->direction == LEFT)
					{
						loc->nextY++;
						if (loc->nextY >= size)
							{
								loc->nextY = 0;
								loc->y++;
								if (loc->y >= size)
									{
										loc->y = 0;
										loc->x++;
										if (loc->x >= size)
											{
												pop = 1;
											}
									}
							}
					}
				else
					{
						loc->nextX++;
						if (loc->nextX >= size)
							{
								loc->nextX = 0;
								loc->x++;
								if (loc->x >= size)
									{
										loc->x = 0;
										loc->y++;
										if (loc->y >= size)
											{
												pop = 1;
											}
									}
							}
					}
			}
		return pop;
	}


__device__ void initLocation(State * s)
{
	Location* loc = &s->location;
	if(s->path->direction == LEFT)
	{
		loc->nextX = loc->x;
		loc->nextY = 0;
	}
	else
	{
		loc->nextX= 0;
		loc->nextY = loc->y;
	}
}

__device__ void cloneState(State s1, State s2, int N)
{
	cloneGrid(&s1.grid, &s2.grid, N);
	cloneLocation(&s1.location, &s2.location);
}

__device__ void cloneLocation(Location* srcLoc, Location* destLoc)
{
	destLoc->x = srcLoc->x;
	destLoc->y = srcLoc->y;
	destLoc->nextX = srcLoc->nextX;
	destLoc->nextY = srcLoc->nextY;
	destLoc->type = srcLoc->type;
}
__device__ void cloneGrid(Grid * srcGrid, Grid * newGrid, int size)
{
	for (int i = 0; i < size; i++)
		{
			newGrid->col[i] = srcGrid->col[i];
			newGrid->row[i] = srcGrid->row[i];
		}
	for (int row = 0; row < size; row++)
		{
			for (int col = 0; col < size; col++)
				{
					newGrid->Cells[row][col] = srcGrid->Cells[row][col];
				}
		}
	newGrid->ok = srcGrid->ok;
}
__device__ int setAll(Grid * g, Path * p, Location * l, int N)
{
	int value = testAndSet(g,p->letters[0],l->x,l->y);
	int nx = l->nextX;
	int ny = l->nextY;
	int direction;
	int letter;
	if(value == 0)
	{
		if (p->direction == LEFT) //Do UP/DOWN
			direction = l->y > l->nextY ? -1 : 1;
		else
			direction = l->x > l->nextX ? -1 : 1;
		for (int offset = 0; offset < 3 && value == 0; offset++)
			{
				if (p->direction == LEFT) //Do UP/DOWN
					ny = (l->nextY + (offset * direction) + N) % N;
				else
					nx = (l->nextX + (offset * direction) + N) % N;
				letter = p->letters[offset + 1];
				value |= testAndSet(g,letter,nx,ny);
				l->lastX = nx;
				l->lastY = ny;
			}
	}
	return value;
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
		printf("Total global memory:           %u", (uint32_t)devProp.totalGlobalMem);
		printf(" bytes\n");
		printf("Number of multiprocessors:     %d\n", devProp.multiProcessorCount);
		printf("Total amount of shared memory per block: %u\n", (uint32_t)devProp.sharedMemPerBlock);
		printf("Total registers per block:     %d\n", devProp.regsPerBlock);
		printf("Warp size:                     %d\n", devProp.warpSize);
		printf("Maximum memory pitch:          %u\n", (uint32_t)devProp.memPitch);
		printf("Total amount of constant memory:         %u\n",  (uint32_t) devProp.totalConstMem);
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
__device__ void printGridDev(Grid * g, int N)
	{
		printf("-- Grid -- \n       ");
		for (int i= 0; i < N; i++)
		{
			printf(" %03X ",g->col[i]);
		}
		printf("\n");
		for (int row = 0; row < N; row++)
			{
				printf("%01d|%03X| ", row,g->row[row]);
				for (int col = 0; col < N; col++)
					{
						char c = g->Cells[row][col];
						printf("  %c  ", c);
						//printf(" %02X ", c);
					}
				printf("\n");
			}
	}