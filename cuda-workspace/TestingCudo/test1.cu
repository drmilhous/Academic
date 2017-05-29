#include <stdio.h>
#include <stdint.h>
#include <stdlib.h>
#include <time.h>
#include <unistd.h>
#include "grid.h"
#define N 10
int allocated = 0;
void initCell(cell * c);
__global__ void compute2(returnResult * res, grid * g, path ** pathList, location * l);
__device__ void computeIterative(returnResult * res, grid * g, path ** pathList, location * baseLoc);
__device__ void add(grid ** base, grid ** last, grid * newList);
__device__ void cloneToGrid(grid * g, grid * g2);
__device__ void eliminateValue(cell **c, int row, int col, int max, int value);
__device__ int check(grid * g, int row, int col, int number);
__device__ grid * allocateGridDevice(int size);
__global__ void testIter(returnResult * res);
void printGrid(grid * g);
__device__ int pow2(int x);
__device__ grid * cloneGrid(grid * g);
char convert(int x);
void bar();
int foo(path ** p, int MAX);
__global__ void testIter(returnResult * res)
	{
		grid * g = allocateGridDevice(res->result[0]->size);
		grid ** temp = res->result;
		for (int i = 0; i < res->breaker; i++)
			{
				int index = i % res->size;
				cloneToGrid(g, temp[index]);
				temp[index]->ok = '1';
			}
	}

void foobared()
	{
		int size = 10;
		grid ** result;
		int i;
		int last = 0;
		int gridSize;
		returnResult * res;
		cudaMallocManaged((void **) &res, 1);
		res->threads = 1;
		//cudaDeviceSetLimit(cudaLimitMallocHeapSize, 128 * 1024 * 1024 * 16);
		gridSize = 1057 * res->threads;
		cudaMallocManaged((void **) &result, sizeof(grid *) * gridSize);
		for (i = 0; i < gridSize; i++)
			{
				result[i] = allocateGrid(size);
			}
		printf("Allocated Bytes %d\n", allocated);
		for (int breaker = 1050; breaker < 1000000; breaker += 1000)
			{
				printf("Starting %d\n", breaker);
				res->result = result;
				res->breaker = breaker;
				res->size = gridSize;
				testIter<<<1, res->threads>>>(res);
				cudaDeviceSynchronize();
				for (i = 0; i < gridSize; i++)
					{
						if (result[i]->ok == '1')
							{
								last = i;
							}
					}
				printf("Size %d Grid #%d", gridSize, last);
				printf("Grid #%d", 0);
				printGrid(result[0]);
				printf("Grid #%d", last);
				printGrid(result[last]);
			}

	}
int main(void)
	{
		int MAX = 5 * 2;
		int deviceCount;
		cudaGetDeviceCount(&deviceCount);
		int device;
		for (device = 0; device < deviceCount; ++device)
			{
				cudaDeviceProp deviceProp;
				cudaGetDeviceProperties(&deviceProp, device);
				printf("Device %d has compute capability %d.%d.\n", device, deviceProp.major, deviceProp.minor);
			} //	 - See more at: http://docs.nvidia.com/cuda/cuda-c-programming-guide/#multi-device-system
		device = 3;
		printf("Starting on device %d MAX=%d \n", device, MAX);
		cudaSetDevice(device);
		path ** p = scanChars();
		if (p != NULL)
			{
				foo(&p[1],MAX);
			}
	}
__global__ void compute2(returnResult * res, grid * g, path ** pathlist, location * l)
	{
		int idx = blockIdx.x * blockDim.x + threadIdx.x;
		if (idx < res->threads)
			{
				computeIterative(res, g, pathlist, l);
			}
	}
__device__ void computeIterative(returnResult * res, grid * g, path ** pathList, location * baseLoc)
	{
		int baseIndex = 0;
		path * p = pathList[baseIndex]; //first path
		int MAX = res->MAX;
		int idx = blockIdx.x * blockDim.x + threadIdx.x;
		int xx = res->size / res->threads * idx;
		int index = idx * (MAX + 1);
		grid ** gridStack = &res->gridStack[index];
		location * locStack = &res->locationStack[index];
		printf("Index %d xx = %d gridIndex\n", idx, xx, index);
		grid ** result = &res->result[xx];
		int gridSize = res->size / res->threads;
		int breaker = 0;
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
		int i = 0;
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
				//	printf("Count=%d loc x%d y%d nx%d ny%d \n", count,loc->x, loc->y, loc->nx, loc->ny);
				value = p->letters[0];
				checkValue = check(currentGrid, loc->x, loc->y, value);
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
				if (checkValue == 0 && count == MAX)
					{
						i++;
						int offset = printcount % gridSize;
						//printf("breaker@@ = %d offset %d\n", breaker, offset);
						cloneToGrid(currentGrid, result[offset]);
						result[offset]->ok = '1';
						printcount++;
						//done = 1;
					}
				if (loc->full == PART)
					{
						if (p->direction == LEFT)
							{
								loc->ny++;
								if (loc->ny >= g->size)
									pop = 1;
							}
						else
							{
								loc->nx++;
								if (loc->nx >= g->size)
									pop = 1;
							}
					}
				else
					{
						if (p->direction == LEFT)
							{
								loc->ny++;
								if (loc->ny >= g->size)
									{
										loc->ny = 0;
										loc->y++;
										if (loc->y >= g->size)
											{
												loc->y = 0;
												loc->x++;
												if (loc->x >= g->size)
													{
														pop = 1;
													}
											}
									}
							}
						else
							{
								loc->nx++;
								if (loc->nx >= g->size)
									{
										loc->nx = 0;
										loc->x++;
										if (loc->x >= g->size)
											{
												loc->x = 0;
												loc->y++;
												if (loc->y >= g->size)
													{
														pop = 1;
													}
											}
									}
							}
					}

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
						if (pop == 1) //pop off the list
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
				if (bmax == breaker)
					{
						//printf("Breaker %d PrintCount  %d\n", breaker, printcount);
						bmax *= 1.2;
					}
				if (breaker == res->breaker)
					{
						done = 1;

						printf("Breaker Max hit!");
					}
			}
		printf("The total is %d breaker %d\n", i, breaker);
	}

int foo(path ** p, int MAX)
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
		//res->threads = 100;
		//res->threads = nBYn;
		//int gridSize = 100;
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

				int breaker = 100000 * 10 * 10 * 10;
				printf("Starting %d\n", breaker);
				res->result = result;
				res->breaker = breaker;
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
		/*i = 0;
		 for (int row = 0; row < N; row++)
		 {
		 for (int col = 0; col < N; col++)
		 {

		 for(int j = 0; j <MAX * 3; j+=3)
		 {
		 int idx = (row * size + col) * MAX*3 +j;
		 if (result[idx]->ok == '1')
		 {
		 printf("(%d,%d,%d)\n", row, col, j);
		 printGrid(result[idx]);
		 }
		 i++;
		 }
		 }
		 }
		 */
		/*for( int i = 0; i < nBYn * MAX * 3; i++)
		 {
		 if (result[i]->ok == '1')
		 {
		 //printf("(%d,%d,%d)\n", row, col, j);
		 puts("");
		 printGrid(result[i]);
		 }
		 }
		 */
		//cudaFree(array);
		return 0;
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
