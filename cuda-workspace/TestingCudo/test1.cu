#include <stdio.h>
#include <stdint.h>
#include <stdlib.h>
#include "grid.h"
#define N 10
#define UP 'U'
#define LEFT 'L'
#define MAX 3
void initCell(cell * c);
__global__ void compute2(grid * g, path * p, location * loc);
__device__ void computeIterative(grid * g, path * p, location * loc);
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
		}//	 - See more at: http://docs.nvidia.com/cuda/cuda-c-programming-guide/#multi-device-system
		//cudaSetDevice(1);
		path ** p = scanChars();
		if (p != NULL)
			{
				foo(p[1]);
			}
	}

__global__ void compute2(grid * g, path * p,location * l)
	{
		int idx = blockIdx.x * blockDim.x + threadIdx.x;
		if (idx < N * N)
			{
				//int x = blockIdx.x;
				//int y = threadIdx.x;
				computeIterative(g, p, l);
			}
	}
__device__ void computeIterative(grid * g, path * p, location * loc)
	{
		int breaker = 0;
		int bmax = 2;
		location * freeHead = NULL;
		location * freeTail = NULL;
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
		cloneToGrid(g,currentGrid);
		loc->currentG = allocateGridDevice(g->size);
		loc->p = p;
		//recCount = recCount +3 ;
		//int set = 0;
		int x,y;
		int count = 0;
		while(done == 0)
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
					direction = lasty > z ? -1 : 1;
				else
					direction = lastx > z ? -1 : 1;
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
			if(checkValue == 0 && count == MAX)
			{
				i ++;
				//printGrid(currentGrid);
			}
			if (checkValue == 0 && count < MAX) //rec value
				{

							//cloneToGrid(currentGrid, res[base]

				if(p->next != NULL)
					{
						if(freeHead == NULL)
						{
							temp = (location *)malloc(sizeof(location));
							temp->currentG = allocateGridDevice(g->size);
							printf("Allocated Block\n");
						}
						else
						{
							temp = freeHead;
							if(freeHead->next != NULL)
							{
								freeHead = freeHead->next;
							}
						}
						temp->x = lastx;
						temp->y = lasty;
						if (p->next->direction == LEFT) //Do UP/DOWN
						{
							temp->nx = 0;
							temp->ny = temp->y;
						}
						else
						{
							temp->nx = temp->x;
							temp->ny = 0;
						}
						//printf("Next x=%d y=%d nx=%d ny=%d\n",temp->x,temp->y,temp->nx,temp->ny);
						temp->p = p->next;
						
						cloneToGrid(currentGrid,temp->currentG);
						temp->next = loc;
						loc = temp;

						count ++;
					}
				}
			else
			{
			if(p->direction == LEFT)
			{
				z = loc->ny;
			}
			else
			{
				z = loc->nx;
			}
			if(z == g->size)
				{
					if(loc->next == NULL)
					{
						done = 1;
					}
					else
					{
						temp = loc->next;
						if(freeHead == NULL)
						{
							freeHead = loc;
							freeTail = loc;
						}
						else
						{
							freeTail->next = loc;
							freeTail = loc;
							freeTail->next = NULL;
						}
						//free(loc->currentG);
						//free(loc);
						loc = temp;
						count --;
					}
			}
			}
		if(bmax == breaker)
		{
			printf("Breaker %d\n",breaker);
			bmax *= 2;
		}
		if(breaker == 2147483648)
		{
			done = 1;
			printf("Breaker Max hit!");
		}
		}
		printf("The total is %d\n",i);
		
	}



int foo(path * p)
	{
		cudaDeviceSetLimit(cudaLimitMallocHeapSize, 128 * 1024 * 1024*8); //See more at: http://docs.nvidia.com/cuda/cuda-c-programming-guide/index.html#heap-memory-allocation
		int nBYn = N * N;
		int size = N;
		grid * g = allocateGrid(size);

		//int i = 0;
		location * larray;
		cudaMallocManaged((void **) &larray,sizeof(location) * nBYn);
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
		compute2<<<1, 1>>>(g, p, larray);
		cudaDeviceSynchronize();
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



