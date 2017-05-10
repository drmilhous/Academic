#include <stdio.h>
#include <stdlib.h>
#define N 10
#define UP 'U'
#define LEFT 'L'
#define MAX 8

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
typedef struct state
{
	int idx;
	grid * currentGrid;
	int base;
	int lastx;
	int lasty;
	int x1;
	int y1;
	int direction;
	int checkValue;
	int set;
	int value;
	int offset;
	int row;
	int col;
}state;
void initCell(cell * c);
char convert(int x);
__device__ void computeRecursive(grid * g, path * p,path** p2, int x, int y, grid ** res, int recCount);
__device__ void cloneToGrid(grid * g, grid * g2);
__device__ void eliminateValue(cell **c, int row, int col, int max, int value);
__device__ void add(grid ** base, grid ** last, grid * newList);
//void printGrid(grid * g, int x, int y);
__device__ grid * cloneGrid(grid * g);
void printGrid(grid * g)
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
__device__ void eliminateValue(cell **c, int row, int col, int max, int value)
	{
		//int mask = pow(2.0, (double) value);
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
				//x->c = ch;
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
				//int mask = pow(2.0, (double) number);
				int mask = pow2(number);
				int bits = c->bitmap;
				result = (mask & bits);
			}
		return result;
	}
grid * allocateGrid(int size)
	{

		grid * g2 = NULL;
		cudaMallocManaged((void **) &g2, sizeof(grid));
		g2->size = size;
		//cell * array;
		//cudaMallocManaged((void **) &array, size * size * sizeof(cell));
		cell ** cells;
		cudaMallocManaged((void **) &cells, size * sizeof(cell *));
		for (int i = 0; i < size; i++)
			{
				//cells[i] = &array[i * size];
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
		//printf("XX%p->%c\n",g2, g2->ok);
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
__global__ void compute(grid * g, path * p,path ** p2, grid ** result)
	{
		int idx = blockIdx.x * blockDim.x + threadIdx.x;
		if (idx < N * N)
			{
				int x = blockIdx.x;
				int y = threadIdx.x;
				computeRecursive(g, p,p2, x, y, result, 0);
			}
	}
__device__ void computeRecursive(grid * g, path * p, path ** nextPath, int x, int y, grid ** res, int recCount)
	{
		state * s = (state *) malloc(sizeof(state));
		s->idx = blockIdx.x * blockDim.x + threadIdx.x;
		s->base = s->idx * MAX *2 + recCount;
		//printf("index[%02d] base[%d]\n",idx, base);
		s->currentGrid = res[s->base +1];
		recCount = recCount +2 ;
		s->set = 0;
		s->checkValue = 0;
		s->value = p->letters[0];
		cloneToGrid(g,s->currentGrid);
		if(s->currentGrid != NULL)
		{
		//grid* previousGrid = res[base + 2];
		s->checkValue = check(s->currentGrid, x, y, s->value);
		if (s->checkValue == 0)
			{
				s->currentGrid->cells[x][y].value = s->value;
				eliminateValue(s->currentGrid->cells, x, y, s->currentGrid->size, s->value);
				//cloneToGrid(currentGrid, previousGrid);
				if (p->direction == LEFT) //Do UP/DOWN
					{
						s->lasty = y;
						for (s->y1 = 0; s->y1 < s->currentGrid->size; (s->y1)++) //check above
							{
								if (s->y1 != y)
									{
										s->direction = y > s->y1 ? -1 : 1;
										s->checkValue = 0;
										for (s->offset = 0; s->offset < 3; (s->offset)++)
											{
												s->value = p->letters[s->offset + 1];
												s->lasty = (s->y1 + (s->offset * s->direction) + s->currentGrid->size) % s->currentGrid->size;
												s->checkValue |= check(s->currentGrid, x, s->lasty, s->value);
												if (s->checkValue == 0)
													{
														s->currentGrid->cells[x][s->lasty].value = s->value;
														eliminateValue(s->currentGrid->cells, x, s->lasty, s->currentGrid->size, s->value);
													}
											}
										if (s->checkValue == 0) //recursive call
											{
												if (s->set == 0)
													{
														s->set = 1;
														cloneToGrid(s->currentGrid, res[s->base]);
														res[s->base]->ok = '1';
													}
												if(recCount < MAX *2)
												 {
													if (p->next != NULL )
													{
														computeRecursive(s->currentGrid, p->next,nextPath, x, s->lasty, res, recCount);
														//add(&result, &last, temp);
													}
													else
													{
														printf("Next Path %d\n", s->idx );
														p = nextPath[0];
														nextPath++;
														for (s->row = 0; s->row < g->size; s->row++)
														{
															for (s->col = 0; s->col < g->size; s->col++)
																{
																	computeRecursive(s->currentGrid, p,nextPath, s->row, s->col, res, recCount);
																}
														}	
													}
												 }
											}
									}
								//cloneToGrid(previousGrid, currentGrid);
								cloneToGrid(g,s->currentGrid);
								s->currentGrid->cells[x][y].value = p->letters[0];
								eliminateValue(s->currentGrid->cells, x, y, s->currentGrid->size, p->letters[0]);
							}
					}
				else // direction = left/right
					{
						s->lastx = x;
						for (s->x1 = 0; s->x1 < s->currentGrid->size; s->x1++) //check above
							{
								if (s->x1 != x)
									{
										s->direction = x > s->x1 ? -1 : 1;
										s->checkValue = 0;
										for (s->offset = 0; s->offset < 3; s->offset++)
											{
												s->value = p->letters[s->offset + 1];
												s->lastx = (s->x1 + (s->offset * s->direction) + s->currentGrid->size) % s->currentGrid->size;
												s->checkValue |= check(s->currentGrid, s->lastx, y, s->value);
												if (s->checkValue == 0)
													{
														s->currentGrid->cells[s->lastx][y].value = s->value;
														eliminateValue(s->currentGrid->cells, s->lastx, y, s->currentGrid->size, s->value);
													}
											}

										//printGrid(currentGrid, x, y);
										if (s->checkValue == 0) //recursive call
											{
												if (s->set == 0)
													{
														s->set = 1;
														//cloneToGrid(currentGrid, res[index]);
														//res[index]->ok = '1';
														cloneToGrid(s->currentGrid, res[s->base]);
														res[s->base]->ok = '1';
													}
												//printGrid(currentGrid, x, y);
												 if(recCount < MAX *2)
												 {
													if (p->next != NULL )
													{
														computeRecursive(s->currentGrid, p->next,nextPath, s->lastx, y, res, recCount);
														//add(&result, &last, temp);
													}
													else
													{
														printf("Next Path %d\n", s->idx );
														p = nextPath[0];
														nextPath++;
														for (s->row = 0; s->row < g->size; s->row++)
														{
															for (s->col = 0; s->col < g->size; s->col++)
																{
																	computeRecursive(s->currentGrid, p,nextPath, s->row, s->col, res, recCount);
																}
														}	
													}
												 }
											}
										//cloneToGrid(previousGrid, currentGrid);
										cloneToGrid(g,s->currentGrid);
										s->currentGrid->cells[x][y].value = p->letters[0];
										eliminateValue(s->currentGrid->cells, x, y, s->currentGrid->size, p->letters[0]);
									}
							}
					}
			}
		}
		else
		{
			printf("Memory Allocation Error");
		}
		/*free(&currentGrid->cells[0]);
		free(currentGrid->cells);
		free(currentGrid);*/
		//return result;
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
		/*char str[100];
		 scanf("%[^\t\n]99", str);
		 str[99] = 0;
		 */
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

int foo(path * p, path ** p2)
	{

		cudaDeviceSetLimit(cudaLimitMallocHeapSize, 128 * 1024 * 1024*8); //See more at: http://docs.nvidia.com/cuda/cuda-c-programming-guide/index.html#heap-memory-allocation

	//cell * array;
	//	cell** cells;
		int nBYn = N * N;
		int size = N;
		grid * g = allocateGrid(size);
		/*cudaMallocManaged((void**) &g, sizeof(grid));
		 g->size = N;
		 cudaMallocManaged((void**) &array, nBYn * sizeof(cell));
		 cudaMallocManaged((void **) &cells, size * sizeof(cell *));

		 for (int i = 0; i < size; i++)
		 {
		 cells[i] = &array[i * size];
		 }
		 g->cells = cells;
		 */

		/*	path *p;
		 cudaMallocManaged((void **) &p, 2);
		 path *p2 = p++;


		 p->next = p++;
		 p->direction = UP;
		 p->letters[0] = 4;
		 p->letters[1] = 3;
		 p->letters[2] = 1;
		 p->letters[3] = 4;

		 p2->next = NULL;
		 p2->direction = LEFT;
		 p2->letters[0] = 4;
		 p2->letters[1] = 2;
		 p2->letters[2] = 1;
		 p2->letters[3] = 3;
		 */
		int i = 0;
		grid **result;
		cudaMallocManaged((void**) &result, sizeof(grid*) * size * size * MAX * 2);
		for (int i = 0; i < nBYn * MAX * 2; i++)
			{
				result[i] = allocateGrid(size);
			}
		/*for (int row = 0; row < N; row++)
		 {
		 for (int col = 0; col < N; col++)
		 {
		 printf("(%d,,%d)\n", row, col);
		 if (result[i] != NULL)
		 printGrid(result[i], row, col);
		 i++;
		 }
		 }*/
		printPath(p);
		compute<<<size, size>>>(g, p,p2, result);
		cudaDeviceSynchronize();
		i = 0;
		for (int row = 0; row < N; row++)
			{
				for (int col = 0; col < N; col++)
					{

						for(int j = 0; j <MAX * 2; j+=2)
						{
						int idx = (row * size + col) * MAX*2 +j;
						if (result[idx]->ok == '1')
							{
								printf("(%d,%d,%d)\n", row, col, j);
								printGrid(result[idx]);
							}
						i++;
						}
					}
			}
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

void test2()
	{

	}

/*void initCell(cell * c)
 {

 for (int row = 0; row < N; row++)
 {
 for (int col = 0; col < N; col++)
 {
 c[row * N + col].value = col;
 printf("[%02d][%02d]%02d ", row, col, c[row * N + col].bitmap);
 c[row * N + col].value = -1;
 }
 printf("\n");
 }
 }*/
int main(void)
	{
		path ** p = scanChars();
		if (p != NULL)
			{
				foo(p[1],&p[2]);
			}
	}
/*
 void test1()
 {
 cell * c = (cell *)malloc(N*N*sizeof(cell));
 cell * dev_c;
 cudaMalloc((void **) &dev_c, N*N*sizeof(cell));
 initCell(c);
 cudaMemcpy( dev_c, c, N*N * sizeof(cell), cudaMemcpyHostToDevice) ;
 char ch = 'a';
 ch = (char) (((int) ch) + 7);
 removeIndex<<<10,1>>>( dev_c, 0,5,N,pow(2,7));
 puts("");
 cudaMemcpy( c, dev_c, N*N * sizeof(cell),cudaMemcpyDeviceToHost);
 for (int row=0; row<N; row++)
 {
 for (int col=0; col<N; col++)
 {
 //printf("[%02d][%02d]%02X ",row, col, c[row * N + col].bitmap);
 int index = row * N + col;
 int value = c[index].value;
 char printC = ' ';
 if( value == -1)
 {
 value = c[index].bitmap;
 }
 else

 printC = convert(value);
 printf("%02X-%c ", value, printC);
 }
 printf("\n");
 }
 // free the memory allocated on the GPU
 cudaFree( dev_c );
 }*/
