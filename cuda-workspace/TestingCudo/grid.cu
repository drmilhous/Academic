#include "grid.h"
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