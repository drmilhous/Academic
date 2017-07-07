#include <stdio.h>
#include <stdint.h>
#include <stdlib.h>
#include <time.h>
#include <unistd.h>
#include "FastGrid.h"
#include <ctype.h>

__device__ void printGridDev(Grid * g,Path * p, int N);
__device__	void printPathDev(Path * p);
StateList* getStates(int N, Path ** path);
__global__ void compute(int N ,int threads, State * s,State * result, int resSize, int maxDepth);
Grid * allocateGrid(int size);
__device__ char convertCharDev(char u);
void initGridData(Grid * g, int size);
void printDevProp(cudaDeviceProp devProp);
int getCores(cudaDeviceProp devProp);

void computeFull(StateList * initState,Path ** path, int N,int depth, int threads);
void initThreadsState(StateList * l,  State * s, int threads, int depth, int N, Path ** path);

__device__ int pow2(int x);
__device__ char convertDev(int x);
__device__ int testAndSet(Grid * g, int number, int x, int y);
State * allocateStateStack(int threads, int maxDepth, int N);
State * allocateState(int size, int N);
__device__ void computeLocal(State * s,State * res,int resSize, int N, int depth, int max);
void initThreads(State * s, int threads, int depth, int N, Path ** path);
__device__ void cloneState(State * s1, State * s2, int N);
__device__ void cloneGrid(Grid * oldGrid, Grid * newGrid, int size);
void cloneGridHost(Grid * oldGrid, Grid * newGrid, int size);
__device__ void cloneLocation(Location* srcLoc, Location* destLoc);
__device__ void initLocation(State * s);
__device__ int setAll(Grid * g, Path * p, Location * l, int N);
__device__ int updateLocation(Location * loc, Path * p, int size);
int main(int argc, char ** argv)
	{
		int device;
		int N;
		int c;
		char * output;
		int depth = 5;
		while ((c = getopt (argc, argv, "n:d:i:w:")) != -1)
		{
    		switch (c)
      		{
				  case 'n':
				  		N = atoi(optarg);
					  	break;
				  case 'd':
				  		device = atoi(optarg);
						break;
				case 'w':
				  		depth = atoi(optarg);
						break;
				  case 'i':
						output = optarg;
				  		break;
			}
		}
		cudaSetDevice(device);
		//read the path from the file
		Path ** path = scanChars(output);
		printf("Allocated \n");
		StateList* statelist = getStates(N,path);
		path[0] = path[0]->next;
		computeFull(statelist,path, N, depth, 840);

	}
StateList* getStates(int N, Path ** path)
{
	StateList* result =(StateList *) malloc(sizeof(StateList));
	int depth = 2;
	int threads = 1;
	int blocks = threads/1;
	int threadBlocks = threads / blocks;
	State * stateStack = allocateStateStack(threads, depth, N);
	initThreads(stateStack, threads, depth,N, path);
	int resSize = 840;
	State * resultList = allocateState(resSize, N);
	stateStack[0].location.type = FULL;
	stateStack[1].path = path[0];
	compute<<<blocks, threadBlocks>>>(N ,threads, stateStack,resultList,resSize, depth);
	cudaDeviceSynchronize();
	result->count = 0;
	for(int i = 0; i < resSize; i++)
		{
			if(resultList[i].grid.ok == '1')
			{
				result->count++;
			}
		}
	printf("Count %d\n",result->count);
	printGrid(&resultList[result->count-1].grid, N);
	result->states = resultList;
	printf("State count %d\n", result->count);
	return result;
}
void computeFull(StateList * initState,Path ** path, int N,int depth, int threads)
	{
		int blocks = threads/16;
		int threadBlocks = threads / blocks;
		if(threads % blocks != 0)
		{
			threadBlocks++;
		}
		for(int i = 0; i <= (depth+1)/6; i++)
		{
			printPath(path[i]);
		}
		State * stateStack = allocateStateStack(threads, depth, N);
		initThreadsState(initState,stateStack, threads, depth,N, path);
		int resSize = 1 * threads;
		State * resultList = allocateState(resSize, N);
		printf("Starting \n");
		clock_t begin = clock();
		compute<<<blocks, threadBlocks>>>(N ,threads, stateStack,resultList,resSize, depth);
		cudaDeviceSynchronize();
		clock_t end = clock();
		double time_spent = (double) (end - begin) / CLOCKS_PER_SEC;
		printf("Time spent %lf\n", time_spent);
		//printGrid(g,N);
		int last = -1;
		for(int i = 0; i < resSize; i++)
		{
			if(resultList[i].grid.ok == '1')
			{
				last =i ;
				//printf("Grid #%d\n",i);
				//printGrid(&resultList[i].grid, N);
			}
		}
		if(last > 0)
		{
				printf("Grid #%d\n",last);
				printGrid(&resultList[last].grid, N);
		}
		long *iter = (long *)malloc(depth * sizeof(long));
		long *count = (long *)malloc(depth * sizeof(long));
		int offset = 0;
		long ti = 0;
		for(int i = 0; i < threads * depth; i++)
		{
			
			//if(i % depth == 0)
			{
			//	printf("Grid %d\n", i);
			//	printGrid(&stateStack[i].grid, N);
				iter[offset] += stateStack[i].iterations;
				count[offset] += stateStack[i].count;
				//printf("Iterations %d\n",stateStack[i].iterations );
				//printf("Count %d\n",stateStack[i].count );
			}
			offset = (offset + 1) % depth;
		}
		printf("Depth,Round Iterations, Total Iterations,Count\n");
		for(int i = 0; i < depth; i++)
		{
			ti += iter[i];
			printf("%d,%ld,%ld,%ld,\n",i, iter[i],ti,count[i]);
		}
	}
void initThreadsState(StateList * l,  State * s, int threads, int depth, int N, Path ** path)
{
	State* t = s;
	Path * current;
	Path ** base;
	for(int i = 0; i < threads; i++)
	{
		base = path;
		current = path[0];
		t++;
		int full = 0;
		for(int d = 0; d < depth-1; d++)
		{
			t->path = current;
			if(full == 1)
			{
				t->location.type = FULL;
				t->location.x = 0;
				t->location.y = 0;
				full = 0;
			}
			t++;
			if(current == NULL || current->next == NULL)
			{
				base++;
				current = base[0];
				full  = 1;
			}
			else
			{
				current = current->next;
			}
			
		}
	}
	t=s;
	//printf("L->count%d\n", l->count);
		for(int i = 0; i < l->count; i++)
		{
			//copy x and y
			cloneGridHost(&l->states[i].grid, &t->grid, N);
			t->location.x = l->states[i].location.lastX;
			t->location.y = l->states[i].location.lastY;
			//printf("Loc (%d,%d)\n",t->location.x,t->location.y );
			t = &t[depth];
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
		//t++;
		int full = 0;
		for(int d = 0; d < depth-1; d++)
		{
			t->path = current;
			if(full == 1)
			{
				t->location.type = FULL;
				t->location.x = 0;
				t->location.y = 0;
				full = 0;
			}
			t++;
			if(current == NULL || current->next == NULL)
			{
				base++;
				current = base[0];
				full  = 1;
			}
			else
			{
				current = current->next;
			}
			
		}
	}
/*	s++;
	for (int row = 0; row < N; row++)
			{
				for (int col = 0; col < N; col++)
					{
						s->location.x = row;
						s->location.y = col;
						s->location.type = PART;
						s = &s[depth];
					}
			}*/
}



State * allocateStateStack(int threads, int maxDepth, int N)
{
	return allocateState(threads * maxDepth, N);
}

State * allocateState(int size, int N)
{
	State * s;
	cudaMallocManaged((void **) &s, sizeof(State) *size);
	for(int i = 0; i < size; i++)
	{
		initGridData(&s[i].grid,N);
		//printGrid(&s[i].grid,N);
		s[i].count = 0;
		s[i].iterations = 0;
	}
	return s;
}
__global__ void compute(int N, int threads, State * s,State * result, int resSize, int maxDepth)
{
	int idx = blockIdx.x * blockDim.x + threadIdx.x;

		if (idx < threads)
			{
				s = &s[idx * maxDepth];
				int index = resSize/threads * idx;
				computeLocal(s,&result[index],resSize/threads,N, 0, maxDepth);
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
__device__ int printSol(State * s, int depth, int N)
{
	Location* l = &s[depth].location;
	Grid * g = &s[depth].grid;
	int printed = 0;
	if(depth == 0)
	{
		if(l->x == 7 && l->y == 3 && g->Cells[7][7] == 4 )
		{
			printf("Deth %d!!", depth);
			printGridDev(&s[depth].grid,s[depth].path, N);
			printed = 1;
		}
	}
	else if(depth == 1)
	{
		if(l->x == 7 && l->y == 3 && l->lastX == 0 && l->lastY == 3 &&l->nextX == 2 && l->nextY == 3  )
		{
			printf("Deth %d!!", depth);
			printGridDev(&s[depth].grid,s[depth].path, N);
		}
	}
	else if(depth == 2)
	{
		if(l->x == 0 && l->y == 3 && l->lastX == 0 && l->lastY == 8 &&l->nextX ==  0 && l->nextY == 6 && g->Cells[7][3] == 1 )
		{
			printf("Deth %d!!", depth);
			printGridDev(&s[depth].grid,s[depth].path, N);
		}
	}
	return printed;
}
__device__ void computeLocal(State * s,State * res,int resSize, int N, int depth, int max)
{
	int value;
	int hasNext = 0;
	int print = printSol(s,depth, N);
	depth++;
	cloneState(&s[depth-1], &s[depth],N);
	initLocation(&s[depth]);
	int count = 0;
	int maxCount = 10;
	int pop;
	int counter = 0;
	while(hasNext == 0 && depth > 0)
	{
		s[depth].iterations++;
		pop = 0;
		hasNext = 0;
		cloneGrid(&s[depth-1].grid, &s[depth].grid, N);
		value = setAll(&s[depth].grid, s[depth].path, &s[depth].location, N);
		if(value == 0)
		{
			if(print == 1)
				printSol(s,depth, N);
			s[depth].count++;
			if(depth == max-1)
			{
				if(counter < resSize)
				{
					cloneState(&s[depth],&res[counter],N);
					res[counter].grid.ok = '1';
					counter++;
				}
			}
			if(depth < max-1)
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
			while(hasNext != 0 && depth > 1)
			{
				depth--;
				hasNext = updateLocation(&s[depth].location, s[depth].path, N);
			}
		}
	}

}
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
										loc->nextX = loc->x;
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
										loc->nextY = loc->y;
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

__device__ void cloneState(State * s1, State * s2, int N)
{
	cloneGrid(&s1->grid, &s2->grid, N);
	cloneLocation(&s1->location, &s2->location);
}

__device__ void cloneLocation(Location* srcLoc, Location* destLoc)
{
	destLoc->x = srcLoc->x;
	destLoc->y = srcLoc->y;
	destLoc->nextX = srcLoc->nextX;
	destLoc->nextY = srcLoc->nextY;
	destLoc->lastX = srcLoc->lastX;
	destLoc->lastY = srcLoc->lastY;
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
void cloneGridHost(Grid * srcGrid, Grid * newGrid, int size)
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
				if(value != 0)
				{
					//printf("Fail offset [%d,%d]\n",nx,ny );
				}
			}
	}
	else
	{
		//printf("Fail offset [%d]\n", 0);
	}
	return value;
}


__device__ int testAndSet(Grid * g, int number, int x, int y)
{
	int ok = 0;
	int value = g->Cells[x][y];
	int mask;
	if (value != DEL)
		{
			if(value == number)
			{
				ok = 0;
			}
			else
			{
				//printf("!!%04X %04X\n",value, number);
				ok = 1;
			}
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
				g->Cells[x][y] = number;
			}
		}
	return ok;
}

__device__ char convertDev(int x)
	{
		char res = 'a';
		if (x != (int) DEL)
			{
				int amount = int(x) + (int) res;
				res = (char) amount;
			}
		else
			{
				res = DEL;
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
		if(g->col == NULL || g->row == NULL)
		{
			printf("Error Allocating\n");
			exit(-1);
		}

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
__device__ void printGridDev(Grid * g,Path * p ,int N)
	{
		if(p != NULL)
		{
			printf("Path -> ");
			printPathDev(p);
		}
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
						char x = g->Cells[row][col];
						char c = convertDev(x);
						printf("  %c  ", c);
						//printf(" %02X ", c);
					}
				printf("\n");
			}
	}

__device__	void printPathDev(Path * p)
	{
		char dir = p->direction == UP ? 'U' : 'L';
		if (p->domain != NULL)
					{
						printf("[%s]->[%s]\n", p->domain, p->pass);
					}
				int value = (int) p->letters[0];
				if (value > 30)
					{
						printf("[%c]-^[%c%c%c]%c\n", p->letters[0], p->letters[1], p->letters[2], p->letters[3], dir);
					}
				else
					{
						printf("[%c]->[%c%c%c]%c\n", convertCharDev(p->letters[0]), convertCharDev(p->letters[1]), convertCharDev(p->letters[2]), convertCharDev(p->letters[3]), dir);
						//printf("[%d]->[%d%d%d]%c\n", p->letters[0], p->letters[1], p->letters[2], p->letters[3], dir);
					}
	}

	__device__ char convertCharDev(char u)
	{
		int x = (int) u;
		int A = (int) 'A';
		x = x + A;
		return (char) x;
	}