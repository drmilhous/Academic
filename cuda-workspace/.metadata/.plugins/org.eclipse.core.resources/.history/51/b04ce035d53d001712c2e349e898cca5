
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
	int8_t x;
	int8_t y;
	struct location * next;
	path * p;
}location;

__device__ int pow2(int x);

#endif