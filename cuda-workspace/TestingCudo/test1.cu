#include <stdio.h>
#include <stdint.h>
#include <stdlib.h>
#include <time.h>
#include <unistd.h>
#include "grid.h"
#define N 10
int allocated = 0;
void initCell(cell * c);
gridResult * getGrids(path ** p, int MAX, int size);
__global__ void compute2(returnResult * res, grid * g, path ** pathList, location * l);
__global__ void compute3(returnResult * res, grid ** g, path ** pathlist, location * l);
__device__ void computeIterative(returnResult * res, grid * g, path ** pathList, location * baseLoc);
__device__ void add(grid ** base, grid ** last, grid * newList);
__device__ void cloneToGrid(grid * g, grid * g2);
void cloneToGridLocal(grid * g, grid * g2);
__device__ void eliminateValue(cell **c, int row, int col, int max, int value);
__device__ int check(grid * g, int row, int col, int number);
__device__ grid * allocateGridDevice(int size);
__device__ int updateLocation(location * loc, path * p, int size);
void printGrid(grid * g);
__device__ int pow2(int x);
__device__ grid * cloneGrid(grid * g);
char convert(int x);
int foo(path ** p, int MAX, int breaker);
void processGrids(gridResult * grids, path ** p,int MAX, int size, returnResult * res,location * larray, grid ** result);
__device__ void printGridDev(grid * g);
__device__ char convertDev(int x);
void printDevProp(cudaDeviceProp devProp);
int getCores(cudaDeviceProp devProp);
int main(int argc, char ** argv)
	{
		int MAX;
		int device;
		int deviceCount;
		cudaGetDeviceCount(&deviceCount);
		for (device = 0; device < deviceCount; ++device)
			{
				cudaDeviceProp deviceProp;
				cudaGetDeviceProperties(&deviceProp, device);
				printDevProp(deviceProp);
				//printf("Device %d has compute capability %d.%d.\n", device, deviceProp.major, deviceProp.minor);
			} //	 - See more at: http://docs.nvidia.com/cuda/cuda-c-programming-guide/#multi-device-system
		if(argc == 3)
		{
			MAX = atoi(argv[1]);
			device = atoi(argv[2]);
		}
		else
		{
			printf("MAX DEV\n");
			exit(-1);
		}
		printf("Starting on device %d MAX %d\n", device, MAX);
		cudaSetDevice(device);
		path ** p = scanChars();
		if (p != NULL)
			{
				//foo(&p[0],MAX, breaker);
				gridResult * grids = getGrids(p,1,N);
				p[0] = p[0]->next->next;
				int offset = 0;
				int currentSize = grids->size;
				int processSize = 1664;
				int done = 0;

				//allocate memory
				returnResult * res;
				grid ** result;
				cudaMallocManaged((void **) &res, 1);
				location * larray;
				cudaMallocManaged((void **) &larray, sizeof(location) * processSize);
				int amount = processSize * sizeof(grid *);
	//printf("Allocated Bytes %d\n", amount);
				cudaMallocManaged((void **) &result, amount);
				for (int i = 0; i < processSize; i++)
				{
					result[i] = allocateGrid(N);
				}
				cudaMallocManaged((void **) &res->gridStack, amount);
				for (int i = 0; i < res->threads * (MAX + 2); i++)
				{
					res->gridStack[i] = allocateGrid(N);
				}
					amount = sizeof(location) * (MAX + 2) * processSize;
					//printf("Allocated Bytes for LStack %d\n", amount);
				cudaMallocManaged((void **) &res->locationStack, amount);




				while(done == 0)
				{
					
					if((processSize * (offset +1))  > currentSize)
					{
						grids->size = currentSize - (processSize * offset); // remainder
					}
					else
					{
						grids->size = processSize;
					}
					printf("Starting size=%d\n", grids->size);
					processGrids(grids, p,MAX, N, res, larray, result);
					grids->grids = &grids->grids[grids->size];
					offset ++;
					if(offset * processSize > currentSize)
					{
						done = 1;
					}
					
				}
					for (int i = 0; i < res->threads * (MAX + 2); i++)
					{
			for(int j = 0; j < size; j++)
			{
				cudaFree(res->gridStack[i]->cells[j]);
			}
			cudaFree(res->gridStack[i]->cells);
			cudaFree(res->gridStack[i]);
		}
	cudaFree(res->gridStack);
	for (int i = 0; i < gridSize; i++)
		{
			for(int j = 0; j < size; j++)
			{
				cudaFree(result[i]->cells[j]);
			}
			cudaFree(result[i]->cells);
			cudaFree(result[i]);
		}
	cudaFree(result);
	cudaFree(res->locationStack);
	cudaFree(larray);
	cudaFree(res);
			}
	}
void processGrids(gridResult * grids, path ** p,int MAX, int size, returnResult * res,location * larray, grid ** result)
{

	
	
	//grid * g = allocateGrid(size);
	
	
	for(int i = 0; i < grids->size; i++)
	{
		larray[i].x = grids->grids[i]->x;
		larray[i].y = grids->grids[i]->y;
		larray[i].full = PART;
	}
	res->threads = grids->size;
	int base = 16;
	int blocks = (grids->size / base);
	if((grids->size % base) != 0)
	{
		blocks +=1;
	}
	int gridSize = 1 * res->threads;
	int amount = gridSize * sizeof(grid *);
	//printf("Allocated Bytes %d\n", amount);
	//cudaMallocManaged((void **) &result, amount);
	for (int i = 0; i < gridSize; i++)
		{
			//		result[i] = allocateGrid(size);
			grids->grids[i]->count = 0;
			grids->grids[i]->iterations = 0;
			grids->grids[i]->ok = '0';
			cloneToGridLocal(grids->grids[i],result[i]);
		}
	amount = res->threads * sizeof(grid *) * (MAX + 2);
	//printf("Allocated Bytes for GStack %d\n", amount);
	//cudaMallocManaged((void **) &res->gridStack, amount);
	//for (int i = 0; i < res->threads * (MAX + 2); i++)
	//	{
	//		res->gridStack[i] = allocateGrid(size);
	//	}
	//amount = sizeof(location) * (MAX + 2) * res->threads;
	//printf("Allocated Bytes for LStack %d\n", amount);
	//cudaMallocManaged((void **) &res->locationStack, amount);
	res->result = result;
	res->size = gridSize;
	res->MAX = MAX;
	clock_t begin = clock();
	printf("STarting block=%d threads%d\n",blocks,base);
	compute3<<<blocks, base>>>(res, grids->grids, p, larray);
	cudaDeviceSynchronize();
	clock_t end = clock();
	double time_spent = (double) (end - begin) / CLOCKS_PER_SEC;
	//printf("Time spent %lf\n", time_spent);
	int last = 0;
	for (int i = 0; i < gridSize; i++)
			{
				if (result[i]->ok == '1')
						{
							last = i;
							//printf("Grid #%d\n", i);
							//printGrid(result[i]);
						}
			}
	long iter = 0;
	long total = 0;
	for (int i = 0; i < gridSize; i++)
		{
			total += grids->grids[i]->count;
			iter += grids->grids[i]->iterations;
			//printf("C=%d I=%d\n", grids->grids[i]->count,grids->grids[i]->iterations);
		}
	
	printf("Grid #%d\n", last);
	printGrid(result[last]);
	printf("## Size,Grid,total,iter, time\n");
	printf("## %d, %d , %ld, %ld, %lf\n",gridSize, last,total, iter, time_spent);


	//cudaDeviceSynchronize();
}


gridResult * getGrids(path ** p, int MAX, int size)
{
	returnResult * res;
	cudaMallocManaged((void **) &res, 1);
	grid * g = allocateGrid(size);
	grid ** result;
	location * larray;
	cudaMallocManaged((void **) &larray, sizeof(location));
	larray[0].x = 0;
	larray[0].y = 0;
	larray[0].full = FULL;
	res->threads = 1;
	int gridSize = 10000;
	int amount = gridSize * sizeof(grid *);
	//printf("Allocated Bytes %d\n", amount);
	cudaMallocManaged((void **) &result, amount);
	for (int i = 0; i < gridSize; i++)
		{
			result[i] = allocateGrid(size);
		}
	amount = res->threads * sizeof(grid *) * (MAX + 2);
	//printf("Allocated Bytes for GStack %d\n", amount);
	cudaMallocManaged((void **) &res->gridStack, amount);
	for (int i = 0; i < res->threads * (MAX + 2); i++)
		{
			res->gridStack[i] = allocateGrid(size);
		}
	amount = sizeof(location) * (MAX + 2) * res->threads;
	//printf("Allocated Bytes for LStack %d\n", amount);
	cudaMallocManaged((void **) &res->locationStack, amount);
	res->result = result;
	res->size = gridSize;
	res->MAX = MAX;
	clock_t begin = clock();
	compute2<<<1, res->threads>>>(res, g, p, larray);
	cudaDeviceSynchronize();
	clock_t end = clock();
	double time_spent = (double) (end - begin) / CLOCKS_PER_SEC;
	//printf("Time spent %lf\n", time_spent);
	int last = 0;
	int valid = 0;
	for (int i = 0; i < gridSize; i++)
			{
				if (result[i]->ok == '1')
						{
							last = i;
							//printf("Grid #%d\n", i);
							//printGrid(result[i]);
							valid ++;
						}
			}
	gridResult* grids = (gridResult *)malloc(sizeof(gridResult));
	grids->grids = result;
	grids->size = last+1;
	printf("Valid = %d", valid);
	//printf("Size %d Grid #%d\n", gridSize, last);

	for (int i = 0; i < res->threads * (MAX + 2); i++)
		{
			for(int j = 0; j < size; j++)
			{
				cudaFree(res->gridStack[i]->cells[j]);
			}
			cudaFree(res->gridStack[i]->cells);
			cudaFree(res->gridStack[i]);
		}
	cudaFree(res->gridStack);
	/*for (int i = 0; i < gridSize; i++)
		{
			for(int j = 0; j < size; j++)
			{
				cudaFree(result[i]->cells[j]);
			}
			cudaFree(result[i]->cells);
			cudaFree(result[i]);
		}
	cudaFree(result);*/
	cudaFree(res->locationStack);
	cudaFree(larray);
	cudaFree(res);
	return grids;
}


int foo(path ** p, int MAX, int breaker)
	{
		returnResult * res;
		cudaMallocManaged((void **) &res, 1);
		//	cudaDeviceSetLimit(cudaLimitMallocHeapSize, 128 * 1024 * 1024 * 8); //See more at: http://docs.nvidia.com/cuda/cuda-c-programming-guide/index.html#heap-memory-allocation
		int nBYn = N * N;
		int size = N;
		grid * g = allocateGrid(size);

		grid ** result;
		int i;
		int last = 0;
		location * larray;
		cudaMallocManaged((void **) &larray, sizeof(location) * nBYn);
		for (int row = 0; row < N; row++)
			{
				for (int col = 0; col < N; col++)
					{
						int offset = row * N + col;
						larray[offset].x = row;
						larray[offset].y = col;
						larray[offset].full = PART;
					}
			}
		larray[0].full = PART;
		printPath(p[0]);
		printPath(p[1]);
		printPath(p[2]);
		printPath(p[3]);
		res->threads = 100;
		int gridSize = 1 * res->threads;
		int amount = gridSize * sizeof(grid *);
		printf("Allocated Bytes %d\n", amount);
		cudaMallocManaged((void **) &result, amount);
		for (i = 0; i < gridSize; i++)
			{
				result[i] = allocateGrid(size);
			}
		amount = res->threads * sizeof(grid *) * (MAX + 1);
		printf("Allocated Bytes for GStack %d\n", amount);
		cudaMallocManaged((void **) &res->gridStack, amount);
		for (i = 0; i < res->threads * (MAX + 1); i++)
			{
				res->gridStack[i] = allocateGrid(size);
			}
		amount = sizeof(location) * (MAX + 1) * res->threads;
		printf("Allocated Bytes for LStack %d\n", amount);
		cudaMallocManaged((void **) &res->locationStack, amount);
		//for(int breaker =100000; breaker < 10000000; breaker+=100000)
			{

				
				printf("Starting %d\n", breaker);
				res->result = result;
				//res->breaker = breaker;
				res->size = gridSize;
				res->MAX = MAX;
				clock_t begin = clock();
				compute2<<<1, res->threads>>>(res, g, p, larray);
				//compute2<<<10, 10>>>(res, g, p, larray);
				cudaDeviceSynchronize();
				clock_t end = clock();
				double time_spent = (double) (end - begin) / CLOCKS_PER_SEC;
				printf("Time spent %lf iteration Max %d\n", time_spent, breaker);
				for (i = 0; i < gridSize; i++)
					{
						if (result[i]->ok == '1')
							{
								last = i;
								printf("Grid #%d\n", i);
								printGrid(result[i]);
							}
					}
				printf("Size %d Grid #%d", gridSize, last);
				/*printf("Grid #%d", 0);
				 printGrid(result[0]);
				 printf("Grid #%d", last);
				 printGrid(result[last]);*/
				//printf("Done %d\n", breaker);
			}
		return 0;
	}


__global__ void compute2(returnResult * res, grid * g, path ** pathlist, location * l)
	{
		int idx = blockIdx.x * blockDim.x + threadIdx.x;
		if (idx < res->threads)
			{
				computeIterative(res, g, pathlist, l);
			}
	}
__global__ void compute3(returnResult * res, grid ** g, path ** pathlist, location * l)
	{
		int idx = blockIdx.x * blockDim.x + threadIdx.x;
		//printf("Index %d\n", idx);
		if (idx < res->threads)
			{
				computeIterative(res, g[idx], pathlist, l);
			}
	}
__device__ void computeIterative(returnResult * res, grid * g, path ** pathList, location * baseLoc)
	{
		int baseIndex = 0;
		path * p = pathList[baseIndex]; //first path
		int MAX = res->MAX;
		int idx = blockIdx.x * blockDim.x + threadIdx.x;
		int xx = res->size / res->threads * idx;
		int index = idx * (MAX + 2);
		grid ** gridStack = &res->gridStack[index];
		location * locStack = &res->locationStack[index];
		
		grid ** result = &res->result[xx];
		int gridSize = res->size / res->threads;
		long breaker = 0;
		int bmax = 2;
		int printcount = 0;
		int count = 0;
		//location * loc = &baseLoc[idx];
		location * loc = &locStack[count];
		//copy location data
		loc->x = baseLoc[idx].x;
		loc->y = baseLoc[idx].y;
		loc->full = baseLoc[idx].full;

		//location * freeHead = NULL;
		long i = 0;
		int checkValue;
		int value;
		int done = 0;
		location * temp;
		if (p->direction == LEFT) //Do UP/DOWN
			{
				loc->nx = loc->x;
				loc->ny = 0;
			}
		else
			{
				loc->nx = 0;
				loc->ny = loc->y;
			}

		grid * currentGrid = allocateGridDevice(g->size);
		//grid * currentGrid = gridStack[count];
		cloneToGrid(g, currentGrid);
		cloneToGrid(currentGrid, gridStack[count]);
		//loc->currentG = gridStack[count];
		loc->p = p;
		loc->next = NULL;
		int pop;
		while (done == 0)
			{
				loc = &locStack[count];
				breaker++;
				pop = 0;
				cloneToGrid(gridStack[count], currentGrid);
				//currentGrid = gridStack[count];
				p = loc->p;
				int lasty = loc->y;
				int lastx = loc->x;
				value = p->letters[0];
				checkValue = 0; 
				if(loc->x >= g->size || loc->y >= g->size || loc->nx >= g->size || loc->ny >= g->size)
				{
					checkValue = 1;
					pop = 1;
				}
				if(checkValue == 0)
				{
					checkValue = check(currentGrid, loc->x, loc->y, value);
				}
				if (checkValue == 0)
					{
						currentGrid->cells[loc->x][loc->y].value = value;
						eliminateValue(currentGrid->cells, loc->x, loc->y, currentGrid->size, value);
						int direction;
						checkValue = 0;
						if (p->direction == LEFT) //Do UP/DOWN
							direction = loc->y > loc->ny ? -1 : 1;
						else
							direction = loc->x > loc->nx ? -1 : 1;
						for (int offset = 0; offset < 3 && checkValue == 0; offset++)
							{
								value = p->letters[offset + 1];
								if (p->direction == LEFT) //Do UP/DOWN
									lasty = (loc->ny + (offset * direction) + currentGrid->size) % currentGrid->size;
								else
									lastx = (loc->nx + (offset * direction) + currentGrid->size) % currentGrid->size;
								checkValue |= check(currentGrid, lastx, lasty, value);
								if (checkValue == 0)
									{
										currentGrid->cells[lastx][lasty].value = value;
										eliminateValue(currentGrid->cells, lastx, lasty, currentGrid->size, value);
									}
							}
					}
				/*if(idx == 839 && count >= MAX-1)
				{
					printf("V IDX=%d loc (%d,%d) (%d,%d) value%d \n", idx,loc->x, loc->y, loc->nx, loc->ny, checkValue);
					printGridDev(currentGrid);
				}*/
				if (checkValue == 0 && count == MAX)
					{
						i++;
						int offset = printcount % gridSize;
						//printf("breaker@@ = %d offset %d\n", breaker, offset);
						cloneToGrid(currentGrid, result[offset]);
						result[offset]->ok = '1';
						result[offset]->x = lastx;
						result[offset]->y = lasty;
						printcount++;
					}
				updateLocation(loc, p, g->size);
				if (checkValue == 0 && count < MAX && pop == 0) //rec value
					{
						uint8_t type = PART;
						path * nextLoc = NULL;
						if (p->next != NULL)
							{
								nextLoc = p->next;
							}
						else
							{
								baseIndex++;
								if (pathList[baseIndex] != NULL)
									{
										nextLoc = pathList[baseIndex];
										type = FULL;
									}
							}
						if (nextLoc != NULL)
							{
								count++;
								temp = &locStack[count];
								temp->full = type;
								temp->x = lastx;
								temp->y = lasty;
								if (nextLoc->direction == LEFT) //Do UP/DOWN
									{
										temp->nx = temp->x;
										temp->ny = 0;
									}
								else
									{
										temp->nx = 0;
										temp->ny = temp->y;
									}
								temp->p = nextLoc;
								cloneToGrid(currentGrid, gridStack[count]);
								//	printf("Push count=%d loc x%d y%d nx%d ny%d \n", count,loc->x, loc->y, loc->nx, loc->ny);
							}
					}
				else
					{
						
						if (pop == 1 ) //pop off the list
							{
								if (loc->full == FULL)
									{
										baseIndex--;
										if (baseIndex < 0)
											{
												done = 1;
											}
									}
								count--;
								if (count < 0)
									{
										done = 1;
									}
							}
					}
			}
		g->count = i;
		g->iterations = breaker;
		//printf("The total is %d breaker %d\n", i, breaker);
		for(int j = 0; j < g->size; j++)
			{
				free(currentGrid->cells[j]);
			}
		free(currentGrid->cells);
		free(currentGrid);
	}



__device__ int updateLocation(location * loc, path * p, int size)
	{
		int pop = 0;
		if (loc->full == PART)
					{
						if (p->direction == LEFT)
							{
								loc->ny++;
								if (loc->ny >= size)
									pop = 1;
							}
						else
							{
								loc->nx++;
								if (loc->nx >= size)
									pop = 1;
							}
					}
				else
					{
						if (p->direction == LEFT)
							{
								loc->ny++;
								if (loc->ny >= size)
									{
										loc->ny = 0;
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
								loc->nx++;
								if (loc->nx >= size)
									{
										loc->nx = 0;
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
__device__ void add(grid ** base, grid ** last, grid * newList)
	{
		if (newList != NULL)
			{
				if (*base == NULL)
					{
						*base = newList;
						*last = *base;
					}
				else
					{
						(*last)->next = newList;
					}
				while ((*last)->next != NULL)
					{
						*last = (*last)->next;
					}
			}
	}

char convert(int x)
	{
		char res = 'a';
		if (x >= 0)
			{
				//int amount = log2((double) x) + (int) res;
				int amount = int(x) + (int) res;

				res = (char) amount;
			}
		else
			{
				res = ' ';
			}
		return res;
	}

__device__ void cloneToGrid(grid * g, grid * g2)
	{
		g2->size = g->size;
		g2->ok = g->ok;
		for (int row = 0; row < g->size; row++)
			{
				for (int col = 0; col < g->size; col++)
					{
						g2->cells[row][col].bitmap = g->cells[row][col].bitmap;
						g2->cells[row][col].value = g->cells[row][col].value;
					}
			}
	}
void cloneToGridLocal(grid * g, grid * g2)
	{
		g2->size = g->size;
		g2->ok = g->ok;
		for (int row = 0; row < g->size; row++)
			{
				for (int col = 0; col < g->size; col++)
					{
						g2->cells[row][col].bitmap = g->cells[row][col].bitmap;
						g2->cells[row][col].value = g->cells[row][col].value;
					}
			}
	}

grid * allocateGrid(int size)
	{
		grid * g2 = NULL;
		allocated += (int) sizeof(grid);
		cudaMallocManaged((void **) &g2, sizeof(grid));
		g2->size = size;
		cell ** cells;
		cudaMallocManaged((void **) &cells, size * sizeof(cell *));
		allocated += (int) size * sizeof(cell *);
		for (int i = 0; i < size; i++)
			{
				cudaMallocManaged((void **) &cells[i], size * sizeof(cell));
				allocated += (int) size * sizeof(cell);
			}
		g2->cells = cells;
		for (int row = 0; row < size; row++)
			{
				for (int col = 0; col < size; col++)
					{
						g2->cells[row][col].bitmap = 0;
						g2->cells[row][col].value = -1;
					}
			}
		g2->next = NULL;
		g2->ok = '0';
		return g2;
	}

__device__ grid * allocateGridDevice(int size)
	{
		grid * g2 = NULL;
		g2 = (grid *) malloc(sizeof(grid));
		g2->size = size;
		cell ** cells;
		cells = (cell **) malloc(size * sizeof(cell *));
		for (int i = 0; i < size; i++)
			{
				cells[i] = (cell*) malloc(size * sizeof(cell));
			}
		g2->cells = cells;
		for (int row = 0; row < size; row++)
			{
				for (int col = 0; col < size; col++)
					{
						g2->cells[row][col].bitmap = 0;
						g2->cells[row][col].value = -1;
					}
			}
		g2->next = NULL;
		g2->ok = '0';
		return g2;
	}

__device__ grid * cloneGrid(grid * g)
	{
		grid * g2 = (grid *) malloc(sizeof(grid));
		if (g2 != NULL)
			{
				g2->size = g->size;
				cell * array = (cell *) malloc(g->size * g2->size * sizeof(cell));
				cell ** cells = (cell **) malloc(g2->size * sizeof(cell *));
				for (int i = 0; i < g->size; i++)
					{
						cells[i] = &array[i * g2->size];
					}
				g2->cells = cells;
				for (int row = 0; row < g2->size; row++)
					{
						for (int col = 0; col < g2->size; col++)
							{
								g2->cells[row][col].bitmap = g->cells[row][col].bitmap;
								g2->cells[row][col].value = g->cells[row][col].value;
							}
					}
				g2->next = NULL;
				g2->ok = '0';
			}
		return g2;
	}

__device__ void eliminateValue(cell **c, int row, int col, int max, int value)
	{
		int mask = pow2(value);
		for (int r1 = 0; r1 < max; r1++)
			{
				if (r1 != row)
					{
						c[r1][col].bitmap |= mask;
					}
			}
		for (int c1 = 0; c1 < max; c1++)
			{
				if (c1 != col)
					{
						c[row][c1].bitmap |= mask;
					}
			}
	}

__device__ int check(grid * g, int row, int col, int number)
	{
		int result;
		cell * c = &g->cells[row][col];
		if (c->value >= 0 && c->value != number)
			{
				result = 1;
			}
		else
			{
				int mask = pow2(number);
				int bits = c->bitmap;
				result = (mask & bits);
			}
		return result;
	}

void printGrid(grid * g)
	{
		int n = g->size;
		//printf("X=%d Y=%d %c\n", x, y, g->ok);
		printf("-- Grid -- \n");
		for (int row = 0; row < n; row++)
			{
				printf("%01d# ", row);
				for (int col = 0; col < n; col++)
					{
						cell c = g->cells[row][col];
						//printf("[%02d][%02d]%02X ",row, col, c[row * N + col].bitmap);
						int value = c.value;
						char printC = ' ';
						if (value < 0)
							{
								value = c.bitmap;
								printf(" %03X%c", value, printC);
							}
						else
							{
								//
								printC = convert(value);
								value = 0;
								printf("  %c  ", printC);
							}

					}
				printf("\n");
			}
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

__device__ void printGridDev(grid * g)
	{
		int n = g->size;
		//printf("X=%d Y=%d %c\n", x, y, g->ok);
		printf("-- Grid -- \n");
		for (int row = 0; row < n; row++)
			{
				printf("%01d# ", row);
				for (int col = 0; col < n; col++)
					{
						cell c = g->cells[row][col];
						//printf("[%02d][%02d]%02X ",row, col, c[row * N + col].bitmap);
						int value = c.value;
						char printC = ' ';
						if (value < 0)
							{
								value = c.bitmap;
								printf("_");
							}
						else
							{
								//
								printC = convertDev(value);
								value = 0;
								printf("%c", printC);
							}
					}
				printf("\n");
			}
	}

void printDevProp(cudaDeviceProp devProp)
{   
	printf("%s\n", devProp.name);
	printf("Major revision number:         %d\n", devProp.major);
	printf("Minor revision number:         %d\n", devProp.minor);
	printf("Total global memory:           %u", devProp.totalGlobalMem);
	printf(" bytes\n");
	printf("Number of multiprocessors:     %d\n", devProp.multiProcessorCount);
	printf("Total amount of shared memory per block: %u\n",devProp.sharedMemPerBlock);
	printf("Total registers per block:     %d\n", devProp.regsPerBlock);
	printf("Warp size:                     %d\n", devProp.warpSize);
	printf("Maximum memory pitch:          %u\n", devProp.memPitch);
	printf("Total amount of constant memory:         %u\n",   devProp.totalConstMem);
	printf("Cores:         %d\n", getCores(devProp)  );
return;
}
int getCores(cudaDeviceProp devProp)
{  
    int cores = 0;
    int mp = devProp.multiProcessorCount;
    switch (devProp.major){
     case 2: // Fermi
      if (devProp.minor == 1) cores = mp * 48;
      else cores = mp * 32;
      break;
     case 3: // Kepler
      cores = mp * 192;
      break;
     case 5: // Maxwell
      cores = mp * 128;
      break;
     case 6: // Pascal
      if (devProp.minor == 1) cores = mp * 128;
      else if (devProp.minor == 0) cores = mp * 64;
      else printf("Unknown device type\n");
      break;
     default:
      printf("Unknown device type\n"); 
      break;
      }
    return cores;
}