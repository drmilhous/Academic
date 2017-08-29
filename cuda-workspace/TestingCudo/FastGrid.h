
#include <stdint.h>
#ifndef GRID
#define GRID

#define UP 'U'
#define LEFT 'L'
#define FULL 1
#define PART 0
#define DEV 0
#define MANAGED 1

#define DEL '-'

typedef struct Path
	{
	struct Path * next;
	char direction;
	int letters[4];
	char * domain;
	char * pass;
	} Path;

typedef struct Grid
	{
        int *row;
        int *col;
        char ** Cells;
        char ok;
       	} Grid;

typedef struct Location{
    uint8_t x;
    uint8_t y;
    uint8_t nextX;
    uint8_t nextY;
    uint8_t lastX;
    uint8_t lastY;
    uint8_t type;
} Location;

typedef struct State{
    Grid grid;
    Location location;
    Path * path;
    long count;
    long iterations;
}State;

typedef struct GridLocPath{
    Grid grid;
    Location location;
    Path * path;
} GridLocPath;

typedef struct StateList
{
    State * states;
    int count;
}StateList;

Path * allocate(char c, char c1, char* c2, int direction);
Path ** scanChars(char * filePath);
char convertChar(char u);
int convertUpper(char u);
Path * getPath(char * line);
void printPath(Path * p);
void printGrid(Grid * g, int N);
char convert(int x);
//Grid * allocateGrid(int size);
#endif
