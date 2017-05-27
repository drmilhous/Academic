
#ifndef GRID
#define GRID

#define UP 'U'
#define LEFT 'L'
#define FULL 1
#define PART 0

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
	uint8_t full;
}location;

typedef struct returnResult
{
	grid ** result;
	int size;
	int threads;
	int breaker;
}returnResult;

grid * allocateGrid(int size);

char convertChar(char u);
int convertUpper(char u);
path * allocate(char c, char c1, char* c2, int direction);
path ** scanChars();
path * getPath(char * line);
void printPath(path * p);

#endif
