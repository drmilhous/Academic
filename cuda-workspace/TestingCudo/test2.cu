#include <stdio.h>
#include <stdlib.h>
#define N 10
/*
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

__device__ int  recursive(int all, int count, int * t)
{
	int res = 0;
	count--;
	if(count > 0)
	{
		int *x = (int *)malloc(all);
		*x = count;
		res += recursive(all, count, x);
		free(x);
	}
	else
	{
		res = count+1;
	}
	return res + *t;
}
__global__ void rec(int count, int allocate)
{
	int idx = blockIdx.x * blockDim.x + threadIdx.x;
	//if(idx < N * N)
	{
		int * temp = (int *) malloc(allocate);
		*temp = 0;
		*temp = recursive(allocate, count, temp);
		printf("Sume = %d\n", *temp);
	}
}
/*int main()
{
	int value;
	int allocate;
	printf("Enter the size:");
	scanf("%d", &value);
	printf("Enter the Stack size:");
	scanf("%d", &allocate);
	//cout << "Yo Yo" << endl;
	printf("Hii\n");
	rec<<<N,N>>>(value, allocate);
	cudaDeviceSynchronize();
	printf("Yo\n");
	return 0;
}



*/