#include <stdio.h>
#include <stdint.h>
#include <stdlib.h>
#include "grid.h"
#define MAX 4
#define N 10
void initCell(cell * c);
__global__ void compute2(grid ** result, int gridSize, grid * g, path * p, location * l);
__device__ void computeIterative(grid ** result, int gridSize, grid * g, path * p, location * loc);
__device__ void add(grid ** base, grid ** last, grid * newList);
__device__ void cloneToGrid(grid * g, grid * g2);
__device__ void eliminateValue(cell **c, int row, int col, int max, int value);
__device__ int check(grid * g, int row, int col, int number);
__device__ grid * allocateGridDevice(int size);
void printGrid(grid * g);
__device__ int pow2(int x);
__device__ grid * cloneGrid(grid * g);
char convert(int x);
int foo(path * p);
int main(void)
	{
		int deviceCount;
		cudaGetDeviceCount(&deviceCount);
		int device;
		for (device = 0; device < deviceCount; ++device)
			{
				cudaDeviceProp deviceProp;
				cudaGetDeviceProperties(&deviceProp, device);
				printf("Device %d has compute capability %d.%d.\n", device, deviceProp.major, deviceProp.minor);
			} //	 - See more at: http://docs.nvidia.com/cuda/cuda-c-programming-guide/#multi-device-system
				//cudaSetDevice(1);
		path ** p = scanChars();
		if (p != NULL)
			{
				foo(p[1]);
			}
	}
__global__ void compute2(grid ** result, int gridSize, grid * g, path * p, location * l)
	{
		int idx = blockIdx.x * blockDim.x + threadIdx.x;
		if (idx < N * N)
			{
				//int x = blockIdx.x;
				//int y = threadIdx.x;
				computeIterative(result, gridSize, g, p, l);
			}
	}
__device__ void computeIterative(grid ** result, int gridSize, grid * g, path * p, location * loc)
	{
		int breaker = 0;
		int bmax = 2;
		int printcount = 0;
		location * freeHead = NULL;
		int i = 0;
		if (p->direction == LEFT) //Do UP/DOWN
			{
				loc->nx = 0;
				loc->ny = loc->y;
			}
		else
			{
				loc->nx = loc->x;
				loc->ny = 0;
			}
		location * temp;
		int checkValue;
		int value;
		int z;
		int done = 0;
		//int idx = blockIdx.x * blockDim.x + threadIdx.x;
		//int base = idx * MAX *3 + recCount;
		grid * currentGrid = allocateGridDevice(g->size);
		cloneToGrid(g, currentGrid);
		loc->currentG = allocateGridDevice(g->size);
		loc->p = p;
		loc->next = NULL;
		//recCount = recCount +3 ;
		//int set = 0;
		int x, y;
		int count = 0;
		while (done == 0)
			{
				breaker++;
				cloneToGrid(loc->currentG, currentGrid);
				x = loc->x;
				y = loc->y;

				p = loc->p;
				int lasty = y;
				int lastx = x;
				value = p->letters[0];
				checkValue = check(currentGrid, x, y, value);
				if (checkValue == 0)
					{
						currentGrid->cells[x][y].value = value;
						eliminateValue(currentGrid->cells, x, y, currentGrid->size, value);
						int direction;
						if (p->direction == LEFT) //Do UP/DOWN
							{
								z = loc->ny;
								loc->ny++;
							}
						else
							{
								z = loc->nx;
								loc->nx++;
							}
						checkValue = 0;
						if (p->direction == LEFT) //Do UP/DOWN
							direction = y > z ? -1 : 1;
						else
							direction = x > z ? -1 : 1;
						for (int offset = 0; offset < 3 && checkValue == 0; offset++)
							{
								value = p->letters[offset + 1];
								if (p->direction == LEFT) //Do UP/DOWN
									lasty = (z + (offset * direction) + currentGrid->size) % currentGrid->size;
								else
									lastx = (z + (offset * direction) + currentGrid->size) % currentGrid->size;
								checkValue |= check(currentGrid, lastx, lasty, value);
								if (checkValue == 0)
									{
										currentGrid->cells[lastx][lasty].value = value;
										eliminateValue(currentGrid->cells, lastx, lasty, currentGrid->size, value);
									}
							}
						//if(checkValue == 0)
						//{
						//	printGrid(currentGrid);
						//}

					}
				if (checkValue == 0 && count == MAX)
					{
						i++;
						if (printcount < gridSize)
							{
								printf("breaker@@ = %d\n", breaker);
								cloneToGrid(currentGrid, result[printcount]);
								result[printcount]->ok = '1';
								//prinotGrid(currentGrid);
								printcount++;
							}
						else
							{
								done = 1;
							}
					}
				if (checkValue == 0 && count < MAX) //rec value
					{
						//cloneToGrid(currentGrid, res[base]
						if (p->next != NULL)
							{
								if (freeHead == NULL)
									{
										temp = (location *) malloc(sizeof(location));
										temp->currentG = allocateGridDevice(g->size);
										printf("Allocated Block\n");
									}
								else
									{
										temp = freeHead;
										if (freeHead->next != NULL)
											{
												freeHead = freeHead->next;
											}
									}
								temp->x = lastx;
								temp->y = lasty;
								if (p->next->direction == LEFT) //Do UP/DOWN
									{
										
										temp->nx = temp->x;
										temp->ny = 0;	
									}
								else
									{
										temp->nx = 0;
										temp->ny = temp->y;
									}
								//printf("Next x=%d y=%d nx=%d ny=%d\n",temp->x,temp->y,temp->nx,temp->ny);
								temp->p = p->next;
								cloneToGrid(currentGrid, temp->currentG);
								temp->next = loc;
								loc = temp;
								count++;
							}
					}
				else 
					{
						if (p->direction == LEFT)
							{
								z = loc->ny;
							}
						else
							{
								z = loc->nx;
							}
						if (z == g->size) //pop off the list
							{
								if (loc->next == NULL)
									{
										done = 1;
									}
								else
									{
										temp = loc->next;
										if (freeHead == NULL)
											{
												freeHead = loc;
												freeHead->next = NULL;
											}
										else
											{
												
												loc->next = freeHead;
												freeHead = loc;
												//freeHead->next = loc;
												//freeTail = loc;
												//freeTail->next = NULL;
												
											}
										loc = temp;
										//free(loc->currentG);
										//free(loc);
										
										count--;
									}
							}
					}
				if (bmax == breaker)
					{
						printf("Breaker %d\n", breaker);
						bmax *= 2;
					}
				if (breaker == 10000)
					{
						done = 1;
						printf("Breaker Max hit!");
					}
			}
		printf("The total is %d\n", i);

	}

int foo(path * p)
	{
		cudaDeviceSetLimit(cudaLimitMallocHeapSize, 128 * 1024 * 1024 * 8); //See more at: http://docs.nvidia.com/cuda/cuda-c-programming-guide/index.html#heap-memory-allocation
		int nBYn = N * N;
		int size = N;
		grid * g = allocateGrid(size);
		int gridSize = 100;
		grid ** result;
		int i;

		cudaMallocManaged((void **) &result, sizeof(grid *) * gridSize);
		for (i = 0; i < gridSize; i++)
			{
				result[i] = allocateGrid(size);
			}
		//int i = 0;

		location * larray;
		cudaMallocManaged((void **) &larray, sizeof(location) * nBYn);
		for (int row = 0; row < N; row++)
			{
				for (int col = 0; col < N; col++)
					{
						int offset = row * N + col;
						larray[offset].x = row;
						larray[offset].y = col;
					}
			}

		printPath(p);
		compute2<<<1, 1>>>(result,gridSize, g, p, larray);
		cudaDeviceSynchronize();
		for (i = 0; i < gridSize; i++)
			{
				printf("Grid #%d", i);
				if (result[i]->ok == '1')
					{
						printGrid(result[i]);
					}
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
		cudaMallocManaged((void **) &g2, sizeof(grid));
		g2->size = size;
		cell ** cells;
		cudaMallocManaged((void **) &cells, size * sizeof(cell *));
		for (int i = 0; i < size; i++)
			{
				cudaMallocManaged((void **) &cells[i], size * sizeof(cell));
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
