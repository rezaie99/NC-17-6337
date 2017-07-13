#include "mex.h"
#include <windows.h>
#include <stdlib.h>

void mexFunction (int nlhs, mxArray *plhs[], int nrhs, const mxArray *prhs[])
{
    double size1 = mxGetScalar(prhs[1]);
    LARGE_INTEGER size;
    size.QuadPart = size1;
    printf("Creating file with size: %lld \n",size.QuadPart);
 
    const char* full = mxArrayToString(prhs[0]);
    HANDLE hf = CreateFile(full, 
                           GENERIC_WRITE, 
                           0,
                           0,
                           CREATE_ALWAYS,
                           0,
                           0);
    SetFilePointerEx(hf, size, 0, FILE_BEGIN);
    SetEndOfFile(hf);
    CloseHandle(hf);	
    return;
}

