
#ifndef GRID
#define GRID
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
grid * allocateGrid(int size);
__device__ void cloneToGrid(grid * g, grid * g2);
__device__ void eliminateValue(cell **c, int row, int col, int max, int value);
__device__ int check(grid * g, int row, int col, int number);
__device__	grid * allocateGridDevice(int size);
__device__ void printGrid(grid * g);
__device__ int pow2(int x);
__device__ grid * cloneGrid(grid * g);
__device__ char convert(int x);
char convertChar(char u);
int convertUpper(char u);
path * allocate(char c, char c1, char* c2, int direction);
path ** scanChars();
path * getPath(char * line);
void printPath(path * p);
__device__ void add(grid ** base, grid ** last, grid * newList);
#endif
