#include "grid.h"
#include <stdio.h>
#include <stdint.h>
#include <stdlib.h>
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
