//CUDA related header files
#include <cuda_runtime.h>
#include <device_launch_parameters.h>

//C header files
#include <stdio.h>

#include "common.h"

/*
sequential reduction
int sum = 0;
for(int i = 0; i < size; i++)
{
    sum += array[i];
}
*/
//Synchronized reduction
__global__ void reduction_gpu(int *input, int *temp, const int size)
{
    int tid = threadIdx.x;
    int gid = blockDim.x * blockIdx.x + threadIdx.x;

    if(gid > size)
    {
        return;
    }
    for (int offset = 0; offset <= blockDim.x/2; offset *= 2)
    {
        if(tid % (2 * offset) == 0)
        {
            input[gid] += input[gid + offset];
        }
        __syncthreads();
    }

    if(tid == 0)
    {
        temp[blockIdx.x] = input[gid];
    }
    
}

int reduction_cpu(int * input, const int size)
{
    int sum = 0;
    for(int i = 0; i < size; i++)
    {
        sum += input[i];
    }
    return sum;
}
void compare_results(int gpu_results, int cpu_results)
{
    printf("GPU results: %d\nCPU results: %d\n", gpu_results, cpu_results);
    if(gpu_results == cpu_results)
    {
        printf("Results are the same");
    }
    else
    {
        printf("Results are different");
    }
}

int main()
{

    int size = 1 << 27; //128 Mb of data

    int byte_size = size * sizeof(int);

    int block_size = 128;
    
    int *h_input, *h_ref;
    h_input = (int*)malloc(byte_size);
    initialize(h_input, size, INIT_ONE_TO_TEN);
    int cpu_result = reduction_cpu(h_input, size);

    dim3 block(block_size);
    dim3 grid(size/block.x);

    printf("Kernel launch parameters | grid.x : %d, block.x : %d\n", grid.x, block.x);

    int temp_array_byte_size = sizeof(int)* grid.x;
    h_ref = (int*)malloc(temp_array_byte_size);

    int * d_input, *d_temp;

    gpuErrchk(cudaMalloc((void**)&d_input, byte_size));
    gpuErrchk(cudaMalloc((void**)&d_temp, temp_array_byte_size));

    gpuErrchk(cudaMemset(d_temp, 0, temp_array_byte_size));
    gpuErrchk(cudaMemcpy(d_input, h_input, byte_size, cudaMemcpyHostToDevice));

    reduction_gpu <<<grid, block>>>(d_input,d_temp,size);

    gpuErrchk(cudaDeviceSynchronize());

    gpuErrchk(cudaMemcpy(h_ref, d_temp, temp_array_byte_size, cudaMemcpyDeviceToHost));

    int gpu_result = 0;

    for (int i = 0; i < grid.x; i++)
    {
        gpu_result += h_ref[i];
    }
    
    compare_results(gpu_result, cpu_result);

    cudaFree(d_temp);
    cudaFree(d_input);

    free(h_ref);
    free(h_input);

    gpuErrchk(cudaDeviceReset());
    printf("Code finished\n");
    return 0;
}