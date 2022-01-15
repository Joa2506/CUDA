#include <stdio.h>
#include <stdint.h>
#include <stdlib.h>
#include <cuda_runtime.h>

//Threads per block
#define BLOCK_SIZE 16

__global__ void gpu_matrixmul(int *a, int *b, int *c, int size)
{
    int row = blockIdx.y * blockDim.y + threadIdx.y ;
    int column = blockIdx.x * blockDim.x + threadIdx.x ;

    int sum = 0;
    if((row < size) && (column < size))
    {
        for(int i = 0; i < size; i++)
        {
            sum += a[row * size + i] * b[i * size + column] ;
        }
    }
    c[row * size + column] = sum ;
}

//Linear solution for matrix multiplication.
void matrixmul(int *a, int *b, int *c, int size)
{
    for (int i = 0; i < size; i++) 
    {
        for (int j = 0; j < size; j++)
        {
            for(int k = 0; k < size; k++)
            {
                c[i * size + j] += a[i * size + k] * b[k * size + j];
            }
        }
       // printf("%d\n", i);
    }
}

//Creates two random 2x2 matrices of size.
void create_matrix(int *a, int *b, int size)
{
    int i, j;
    for(i = 0; i < size; i++)
    {
        for (j = 0; j < size; j++)
        {
            a[i * size + j] = rand()%100;
            b[i * size + j] = rand()%100;
        }
    }
    printf("Matrix created!\n");
}

int main()
{

    int size = 1 << 10; //Easy init 1024
    int bytes = size*size*sizeof(int); // size for linear 2x2
    
    //Host
    int *a, *b, *c;

    //GPU
    int *g_a, *g_b, *g_c;


    a = (int*)malloc(bytes);
    b = (int*)malloc(bytes);
    c = (int*)malloc(bytes);

    cudaMalloc(&g_a, bytes);
    cudaMalloc(&g_b, bytes);
    cudaMalloc(&g_c, bytes);

    create_matrix(a, b, size);


    cudaMemcpy(g_a, a, bytes,cudaMemcpyHostToDevice);
    cudaMemcpy(g_b, b, bytes,cudaMemcpyHostToDevice);
    //cudaMemcpy(g_c, c, cudaMemcpyHostToDevice);

    //Blocks in each dimension
    int grid_size = (int)ceil(size/BLOCK_SIZE);

    dim3 grid(grid_size, grid_size);
    dim3 threads(BLOCK_SIZE, BLOCK_SIZE);

    gpu_matrixmul <<<grid, threads>>>(g_a, g_b, g_c, size);

    cudaMemcpy(c, g_c, bytes, cudaMemcpyDeviceToHost);

    //matrixmul(a, b, c, size);

    free(a);
    free(b);
    free(c);


}