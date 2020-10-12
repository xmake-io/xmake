#include <stdio.h>
#include <omp.h>

int main(int argc, char** argv)
{
    #pragma omp parallel for
    for (int i = 0; i < 10; ++i)
    {
        printf("hello(%d): i = %d\n", omp_get_thread_num(), i);
    }
    return 0;
}
