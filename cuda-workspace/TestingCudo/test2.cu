#include <stdio.h>
#include <stdlib.h>
#define N 10

typedef struct graph{

	char * data;
	char direction;
}graph;

__device__ graph * graphAllocate()
{
	graph* g = (graph *) malloc(sizeof(graph));
	g->data = (char *)malloc(1000);
	for(int i = 0; i < 1000;i++)
	{
		g->data[i] = 254;
	}
	g->direction = 'M';
	printf("Before '%c' ", g->direction);
	return g;
}
__device__ void b(int idx)
{
	graph * g = graphAllocate();
	int sum = 1;
	for(int i = 0; i < 1000;i++)
	{
		sum = (sum + g->data[i]) % idx;
	}
	printf("After'%c' %02d\n", g->direction,sum);
	//printf("Device %d\n", idx);
}

__global__ void a()
{
	int idx = blockIdx.x * blockDim.x + threadIdx.x;
	if(idx < N * N)
	{
		b(idx);
	}
}

/*
int main()
{
	//cout << "Yo Yo" << endl;
	printf("Hii\n");
	a<<<N,N>>>();
	cudaDeviceSynchronize();
	printf("Yo\n");
	return 0;
}*/

int main()
{
	int value;
	printf("Enter the size:");
	scanf("%d", &value);
	//cout << "Yo Yo" << endl;
	printf("Hii\n");
	rec<<<N,N>>>(value);
	cudaDeviceSynchronize();
	printf("Yo\n");
	return 0;
}

__device__ void recursive(int count)
{
	count--;
	if(count > 0)
	{
		recursive(count);
	}
}
__global__ void rec(int count)
{
	int idx = blockIdx.x * blockDim.x + threadIdx.x;
	if(idx < N * N)
	{
		recursive(count);
	}
}

