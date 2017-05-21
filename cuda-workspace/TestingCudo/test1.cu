#include <stdio.h>
#include <stdint.h>
#include <stdlib.h>
#define N 10
#define UP 'U'
#define LEFT 'L'
#define MAX 4

typedef struct path
	{
	struct path * next;
	char direction;
	int letters[4];
	char * domain;
	char * pass;
	} path;

struct cell
	{
	int value;
	int bitmap;
	};

typedef struct grid
	{
	cell ** cells;
	//cell cells[N][N];
	short size;
	struct grid * next;
	//int xx;
	char ok;
	//int yy;
	} grid;
typedef struct location
{
	int x;
	int nx;
	int y;
	int ny;
	struct location * next;
	struct grid * currentG;
	path * p;
}location;

void initCell(cell * c);
__device__ int pow2(int x);
__device__ void printGrid(grid * g);
__device__ char convert(int x);
__global__ void compute(grid * g, path * p, location * loc);
__device__ void computeIterative(grid * g, path * p, location * loc);
__device__ void cloneToGrid(grid * g, grid * g2);
__device__ void eliminateValue(cell **c, int row, int col, int max, int value);
__device__ void add(grid ** base, grid ** last, grid * newList);
__device__ int check(grid * g, int row, int col, int number);
__device__	grid * allocateGridDevice(int size);
//void printGrid(grid * g, int x, int y);
__device__ grid * cloneGrid(grid * g);
grid * allocateGrid(int size);
path * getPath(char * line);
void printPath(path * p);
path ** scanChars();
int foo(path * p);

int main(void)
	{
		path ** p = scanChars();
		if (p != NULL)
			{
				foo(p[1]);
			}
	}

__global__ void compute(grid * g, path * p,location * l)
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
						temp = (location *)malloc(sizeof(location));
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
						temp->currentG = allocateGridDevice(g->size);
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
						free(loc->currentG);
						free(loc);
						loc = temp;
						count --;
					}
			}
			}	
		}
		printf("The total is %d\n",i);
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

int foo(path * p)
	{
		cudaDeviceSetLimit(cudaLimitMallocHeapSize, 128 * 1024 * 1024*8); //See more at: http://docs.nvidia.com/cuda/cuda-c-programming-guide/index.html#heap-memory-allocation
		int nBYn = N * N;
		int size = N;
		grid * g = allocateGrid(size);

		int i = 0;
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
		compute<<<1, 1>>>(g, p, larray);
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

/*
 __global__ void add( int *a, int *b, int *c )
 {
 int tid = blockIdx.x; // handle the data at this index
 if (tid < N)
 c[tid] = a[tid] + b[tid];
 }*/

int convertUpper(char u)
	{
		int x = (int) u;
		int A = (int) 'A';
		x = x - A;
		return x;
	}
char convertChar(char u)
	{
		int x = (int) u;
		int A = (int) 'A';
		x = x + A;
		return (char) x;
	}

__device__ char convert(int x)
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


path * allocate(char c, char c1, char* c2, int direction)
	{
		path *p;
		cudaMallocManaged((void **) &p, 1);
		p->next = NULL;
		p->letters[0] = convertUpper(c);
		p->letters[1] = convertUpper(c1);
		p->letters[2] = convertUpper(c2[0]);
		p->letters[3] = convertUpper(c2[1]);
		p->direction = direction;
		p->domain = NULL;
		p->pass = NULL;
		return p;
	}
void printPath(path * p)
	{
		if (p != NULL)
			{
				char dir = p->direction == UP ? 'U' : 'L';
				if (p->domain != NULL)
					{
						printf("[%s]->[%s]\n", p->domain, p->pass);
					}
				int value = (int) p->letters[0];
				if (value > 30)
					{
						printf("[%c]->[%c%c%c]%c\n", p->letters[0], p->letters[1], p->letters[2], p->letters[3], dir);
					}
				else
					{
						printf("[%c]->[%c%c%c]%c\n", convertChar(p->letters[0]), convertChar(p->letters[1]), convertChar(p->letters[2]), convertChar(p->letters[3]), dir);
						//printf("[%d]->[%d%d%d]%c\n", p->letters[0], p->letters[1], p->letters[2], p->letters[3], dir);

					}
				printPath(p->next);
			}
	}
path * getPath(char * line)
	{
		char * domain = line;
		char * pass = strstr(domain, "-");
		long offset = (long) pass - (long) domain;
		domain[offset - 2] = 0;
		pass += 3;

		int domainLen = strlen(domain);

		//printf("[%s]->[%s]\n", domain, pass);
		path * head = NULL;
		path * tail = NULL;
		char previous = domain[domainLen - 1];
		int direction = domainLen % 2 == 1 ? UP : LEFT;
		for (int i = 0; i < domainLen; i++)
			{
				char next = domain[i];
				path * current = allocate(previous, next, &pass[i * 2], direction);
				previous = pass[i*2+1];
				if (head == NULL)
					{
						head = current;
						cudaMallocManaged((void **) &head->domain, domainLen + 1);
						strcpy(head->domain, domain);
						cudaMallocManaged((void **) &head->pass, strlen(pass) + 1);
						strcpy(head->pass, pass);
					}
				if (tail == NULL)
					{
						tail = head;
					}
				else
					{
						tail->next = current;
						tail = current;
					}
				direction = direction == UP ? LEFT : UP;
			}

		return head;
	}
path ** scanChars()
	{
		char test[100] = "HEBJCE  -> BJAGDHCHJEGJ";
		int count = 100;
		int index = 0;
		path ** pathList;
		cudaMallocManaged((void **) &pathList, (sizeof(path *)) * count);
		path * p = getPath(test);
		printPath(p);
		FILE * database;
		char buffer[30];

		database = fopen("output.txt", "r");

		if (NULL == database)
			{
				perror("opening database");
				return NULL;
			}
		int max = 10;
		while (EOF != fscanf(database, "%[^\n]\n", buffer) && index < max)
			{
				char * b = buffer;
				while (*b != '-')
					{
						if (*b == 0)
							{
								*b = ' ';
							}
						b++;
					}
				if (index < max)
					{
						p = getPath(buffer);
						pathList[index] = p;
						index++;
						if (index == count)
							{
								path ** temp;
								cudaMallocManaged((void **) &temp, (sizeof(path *) * count * 1.5));
								for (int i = 0; i < count - 1; i++)
									{
										temp[i] = pathList[i];
									}
								cudaFree(pathList);
								pathList = temp;
								count *= 1.5;

							}

						//printf("> %s\n", buffer);
						//	getPath(buffer);
					}
			}

		/*for (int i = 0; i < count; i++)
		 {
		 printPath(pathList[i]);
		 }*/
		printf("Count is  = %d\n", index);
		fclose(database);
		return pathList;
	}





__device__ int pow2(int x)
{
	int sum = 1;
	if( x == 0)
	{
		sum = 1;
	}
	else
	{
	for(int i = 0; i < x; i++)
	{
		sum = sum *2;
	}
	}
	return sum;
}

__device__ void printGrid(grid * g)
	{
		int n = g->size;
		//printf("X=%d Y=%d %c\n", x, y, g->ok);
		for (int row = 0; row < n; row++)
			{
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
__device__	grid * allocateGridDevice(int size)
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
		if(g2 != NULL)
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
