
#include <stdint.h>
#ifndef GRID
#define GRID

#define UP 'U'
#define LEFT 'L'
#define FULL 1
#define PART 0
#define DEV 0
#define MANAGED 1

typedef struct Path
	{
	struct path * next;
	char direction;
	int letters[4];
	char * domain;
	char * pass;
	} Path;

typedef struct Grid
	{
        int *row;
        int *col;
        char ** Cell;
        char ok;
       	} Grid;

typedef struct Location{
    uint8_t x;
    uint8_t y;
    uint8_t nextX;
    uint8_t nextY;
    uint8_t type;
} Location;

typedef State{
    Grid * grid;
    Location * location;
    Path * path;
    long count;
    long iterations;
}State;

typedef GridLocPath{
    Grid * grid;
    Location * location;
    Path * path;
} GridLocPath;

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
	uint8_t child;
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

Path * allocate(char c, char c1, char* c2, int direction);
Path ** scanChars();
char convertChar(char u);
int convertUpper(char u);
Path * getPath(char * line);
void printPath(Path * p);
void printGrid(Grid * g);

grid * allocateGrid(int size);
void initCell(cell * c);


void cloneToGridLocal(grid * g, grid * g2);
#endif
