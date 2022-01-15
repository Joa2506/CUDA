#include <stdlib.h>
#include <stdio.h>
#include <time.h>
#include "common.h"



void initialize(int *input, int size, type type)
{
    srand(time(0));

    if(type == INIT_RANDOM)
    {
        int random = rand();
        for (int i = 0; i < size; i++)
        {
            input[i] = random;
        }
        
    }
    else if(type == INIT_ONE_TO_TEN)
    {
        int random = rand()%9;
                for (int i = 0; i < size; i++)
        {
            input[i] = random;
        }
    }
    else
    {
        printf("No correct initialization type passed");
    }
}   