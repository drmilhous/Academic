
#include <stdint.h>
#ifndef GRID
#define GRID

#define UP 'U'
#define LEFT 'L'
#define FULL 1
#define PART 0
#define DEV 0
#define MANAGED 1

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
	uint8_t x;
	uint8_t y;
	long count;
	long iterations;
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
	uint8_t full;
}location;

typedef struct returnResult
{
	int MAX;
	grid ** result;
	int size;
	int threads;
	location * locationStack;
	grid ** gridStack;
	

}returnResult;

typedef struct gridResult{
	grid ** grids;
	int size;
}gridResut;


grid * allocateGrid(int size);

char convertChar(char u);
int convertUpper(char u);
path * allocate(char c, char c1, char* c2, int direction);
path ** scanChars();
path * getPath(char * line);
void printPath(path * p);

#endif
