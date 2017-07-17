#include <math.h>
#include <stdio.h>
#include <stdlib.h>
#include "utils.h"
#include "constants.h"
#include <string.h>
//
// Accepts a pointer to 1D array of floats and its size
// Reverses the array in place
//
// Notes:
//      We are not checking for out of bounds exception
//

void ReverseInPlace(float *arr, uint32_t size) {
    float temp;
    uint32_t index, end = size - 1;
    
    for (index = 0; index < size/2; index++) {
        temp = arr[end];
        arr[end] = arr[index];
        arr[index] = temp;
        end--;
    }
}


//
// Accepts a pointer to 1D array of floats and its size
// Returns the sum of the array of numbers
//
// Notes:
//      We are not checking for out of bounds exception
//      We are not checking on size either
//

uint32_t GetSumBool(const uint8_t *arr, uint32_t size) {
    uint32_t index;
    uint32_t sum = 0;

    for (index = 0; index < size; index++) {
        sum += arr[index];
    }

    return sum;
}

float GetSum(const float *arr, uint32_t size) {
    uint32_t index;
    float sum = 0.0;
    
    for (index = 0; index < size; index++) {
        sum += arr[index];
    }

    return sum;
}


//
// Accepts a pointer to 1D array of floats and its size
// Returns the mean of the array of numbers.. maybe we don't need this
// Can use the GetSum above I guess. Just for modularity's sake.
//
// Notes:
//      We are not checking for out of bounds exception
//      We are not checking on size either
//

float GetMean(const float *arr, uint32_t size) {
    uint32_t index;
    float sum = 0.0;
    
    for (index = 0; index < size; index++) {
        sum += arr[index];
    }
    
    return sum/(1.0*size);
}


//
// Accepts a pointer to 1D array of floats and its size
// Normalizes the array by dividing each element by the array sum
//
// Notes:
//      We are not checking for out of bounds exception
//
// To DO:
//      What if array sum is 0.0? We need to take care
//

void NormalizeArray(float *arr, uint32_t size) {
    float sum;
    uint32_t index;
    
    sum = GetSum(arr, size);
    for (index = 0; index < size; index++) {
        arr[index] = arr[index]/sum;
    }
}


//
// Accepts a pointer to 1D array of bools and its size
// Returns the number of trues in the array
//
// Notes:
//      We are not checking for out of bounds exception
//      We are not checking on size either
//

int CountTrues(const utilBool *indicator, uint32_t size) {
    uint32_t index, count = 0;
    
    for (index = 0; index < size; index++) {
        if (indicator[index]) {
            count++;
        }
    }
    return count;
}


//
// Accepts a pointer to 1D array of floats and its size
// Returns the index location of the maximum value in the array
// If the maximum occurs multiple times, the index of first occurrence returned
//
// Notes:
//      We are not checking for out of bounds exception
//      We are not checking on size either
//

int GetMaxLocation(const float *arr, uint32_t size) {
    float maxValue;
    uint32_t index, maxLocation;
    
    maxLocation = 0;
    maxValue = arr[0];
    for (index = 1; index < size; index++) {
        if ((arr[index] - maxValue) > TOL) {
            maxValue = arr[index];
            maxLocation = index;
        }
    }
    
    return maxLocation;
}

float GetMaxValue(const float *arr, uint32_t size) {
    float maxValue;
    uint32_t index;
    
    maxValue = arr[0];
    for (index = 1; index < size; index++) {
        if ((arr[index] - maxValue) > TOL) {
            maxValue = arr[index];
            
        }
    }
    
    return maxValue;
}

float GetMaxAbsValue(const float *arr, uint32_t size) {
    float maxValue;
    uint32_t index;
    
    maxValue = fabsf(arr[0]);
    for (index = 1; index < size; index++) {
        if ((fabsf(arr[index]) - maxValue) > TOL) {
            maxValue = fabsf(arr[index]);
            
        }
    }
    
    return maxValue;
}

//
// Accepts a pointer to 1D array of floats and its size
// Returns the index location of the minimum value in the array
// If the minimum occurs multiple times, the index of first occurrence returned
//
// Notes:
//      We are not checking for out of bounds exception
//      We are not checking on size either
//

int GetMinLocation(const float *arr, uint32_t size) {
    float minValue;
    uint32_t index, minLocation;
    
    minLocation = 0;
    minValue = arr[0];
    for (index = 1; index < size; index++) {
        if ( (minValue - arr[index]) > TOL) {
            minValue = arr[index];
            minLocation = index;
        }
    }

    return minLocation;
}


//
// Accepts pointers to two 1D array of floats and their common size
// Returns the dot product of the two arrays
//
// Notes:
//      We are not checking for out of bounds exception, or that the two arrays should be of same size
//      We are not checking on size either
//
// TO DO:
//      Check that two arrays are of same size
//

float DotProduct(const float *arr1, const float *arr2, uint32_t size) {
    uint32_t index;
    float dot = 0.0;
    
    for (index = 0; index < size; index++) {
        dot += arr1[index] * arr2[index];
    }
    
    return dot;
    
}


//
// Accepts pointers to 1D array of floats and bools, their common size, and a choice of type bool
// The indicator array is flagged as true at locations of local maximum in the array of floats
//
// Notes:
//      We follow a simple algorithm: definition of peak as given here:
//      http://courses.csail.mit.edu/6.006/fall10/lectures/lec02.pdf
//      "An element is a peak if it is not smaller than it's neighbors": hence the <= and >= usage
//      We are including the peaks at the endpoint depending on the choice parameter (true or false)
//      We are not checking for out of bounds exception, or that arr and indicator should be of same size
//      We are not checking on size either
//
// TO DO:
//      Check that two arrays are of same size
//      Use TOL while comparing floats


void GetLocalMaxLocationsSimple(const float *arr, utilBool *indicator, uint32_t size, utilBool choice) {
    uint32_t index;
    int32_t no_neighbors = 1;
    float left, middle, right;
    uint8_t test[1] = {0};
    
    // Make sure that indicator array is properly initialized
    memset(indicator,UTIL_FALSE,size*sizeof(uint32_t));

    // Now look for local maxima in the middle
    for (index = no_neighbors; index < (size-no_neighbors); index++) {
        middle = arr[index];
        
        for (int32_t neighbor = 1; neighbor <= no_neighbors; neighbor++) {
            left = arr[index-neighbor];
            right = arr[index+neighbor];
            
            if (left < middle && middle > right) {
                test[neighbor-1] = 1;
            }
            
            else{
                test[neighbor-1] = 0;
            }

        }
        uint32_t sum = GetSumBool( test, no_neighbors);
        if (sum == no_neighbors) {
            indicator[index] = UTIL_TRUE;
//            printf("Local Max at index = %d \n", index);
        }

    }
    
    
    // Now check for peaks at the boundaries if choice is set to true
    if(choice) {
        if (arr[0] > arr[1]) indicator[0] = UTIL_TRUE;
        if (arr[size-2] < arr[size-1]) indicator[size-1] = UTIL_TRUE;
    }

}


//
// Accepts pointers to 1D array of floats and bools, their common size, and the element to look for
// The indicator array is flagged as true(1) at locations where element is found in the array of floats
//
// Notes:
//      We are not checking for out of bounds exception, or that arr and indicator should be of same size
//      We are not checking on size either
//
// TO DO:
//      Check that two arrays are of same size
//

void FindLocations(const float *arr, utilBool *indicator, uint32_t size, float element) {
    uint32_t index;
    //utilBool found = UTIL_FALSE;
    
    // Make sure that indicator array is properly initialized
    memset(indicator,UTIL_FALSE,size*sizeof(uint32_t));
    
    // Now search for the element
    for (index = 0; index < size; index++) {
        if (fabs(arr[index] - element) <= TOL) {
            indicator[index] = UTIL_TRUE;
            //found = UTIL_TRUE;
        }
    }
    
//    printf("found  = %d\n", found);
}

//
// Accepts pointers to 1D array of floats and 1D array of ints, their common size
// Populates the sortIndexes array with the index locations of the sorted (descending) values in original array
//
// Notes:
//      We are not checking for out of bounds exception, or that the two arrays should be of same size
//      We are not checking on size either
//
// TO DO:
//      Check that two arrays are of same size
//

void FindSortIndexes(const float *arr, int *sortIndexes, uint32_t size) {
    int index, indx, loc;
    utilBool indicator[size];
    float arr_copy[size];
    
    // Make the copy
    memcpy(&arr_copy[0], &arr[0], (size)*sizeof(float));
    
    // Sort (ascending) the copied array in place
    // After this step, arr_copy is sorted, but arr maintains its original order
    qsort(arr_copy, size, sizeof(float), compare_floats);
    
    // Start picking elements from the end, since arr_copy is sorted ascending
    loc = 0;
    for (index = (size-1); index >= 0; ) {
        FindLocations(arr, indicator, size, arr_copy[index]);
        // Start filling up the sortIndexes array
        for (indx = 0; indx < size; indx++) {
            if(indicator[indx] && loc < size) {
                //printf("\n -- %f found in location %d in original array\n", arr_copy[index], indx);
                sortIndexes[loc] = indx;
                loc++;
                index--;
            }
        }
    }
    
}


//
// Accepts pointers to two 1D array of floats, their common size, and the mean and std parameters for Gaussian
// Populates the gauss array with the the Gaussian value, taking corresponding value in arr as argument to Gaussian
//
// Notes:
//      We are not checking for out of bounds exception, or that the two arrays should be of same size
//      We are not checking on size either
//
// TO DO:
//      Check that two arrays are of same size
//      Check that std is a positive number, greater than TOL
//

void GenerateGaussian(float mean, float std, const float *arr, float *gauss, uint32_t size) {
    uint32_t index;
    float factor = 1.0/(std * sqrtf(2.0 * M_PI));
    
    // Populate the array of interest
    for (index = 0; index < size; index++) {
        // Trying not to use the "pow" function while squaring stuff
        gauss[index] = factor * expf(-1.0*(arr[index] - mean)*(arr[index] - mean)/(2.0*std*std));
    }
}


//
// Accepts pointers to three 1D array of floats and sizes of the first two
// Populates the arrOut array with the the result of convoluting arrIn and arrKernel
//
// Notes:
//      We are doing "full" mode convolution, the default in numpy.convolve
//      Size of arrOut would be (sizeSignal + sizeKernel - 1): User needs to make sure arrOut has that dimension
//

void Convolve(const float *arrSignal, float *arrKernel, float *arrOut, uint32_t sizeSignal, uint32_t sizeKernel) {
    uint32_t index;
    uint32_t idx, idxMin, idxMax;
    float overlap = 0.0;
    
    // Convolve ...
    for (index = 0; index < (sizeSignal + sizeKernel - 1); index++) {
        overlap = 0.0;
        
        idxMin = (index >= sizeKernel - 1) ? index - (sizeKernel - 1) : 0;
        idxMax = (index < sizeSignal - 1) ? index : sizeSignal - 1;
        
        for (idx = idxMin; idx <= idxMax; idx++)
        {
            overlap += arrSignal[idx] * arrKernel[index - idx];
        }
        arrOut[index] = overlap;
    }
}


t
//

int compare_floats (const void *a, const void *b) {
    const float *da = (const float *) a;
    const float *db = (const float *) b;
    
    //return (*da > *db) - (*da < *db);
    
    if (*da - *db > TOL) {
        return 1;
    }
    else if (*db - *da > TOL) {
        return -1;
    }
    else return 0;
}



int compare_int32 (const void *a, const void *b) {
    const int32_t *da = (const int32_t *) a;
    const int32_t *db = (const int32_t *) b;
    
    //return (*da > *db) - (*da < *db);
    
    if (*da - *db > TOL) {
        return 1;
    }
    else if (*db - *da > TOL) {
        return -1;
    }
    else return 0;
}



float getMinDistancePeak (float freqState, float* peaks, int32_t noPeaks){
    
    float minDist = 99999;
    float minPeak = 99999;
    float dist = 0;
    
    for(int32_t i=0; i< noPeaks; i++)
    {
        if (peaks[i] != 0){
            
            dist = fabsf(peaks[i] - freqState);
            if (dist < minDist)
            {
                minDist = dist;
                minPeak = peaks[i];
            }
        }
    }
    
    return minPeak;
}

int32_t getMinDistanceIndex (float freqState, float* peaks, int32_t noPeaks){
    
    float minDist = 99999;
    float dist = 0;
    int32_t minDistIndex = 0;
    
    for(int32_t i=0; i< noPeaks; i++)
    {
        if (peaks[i] != 0){
            dist = fabsf(peaks[i] - freqState);
            if (dist < minDist)
            {
                minDist = dist;
                minDistIndex = i;
            }
        }
    }
    
    return minDistIndex;
}


int32_t getMinPeakLocation (float* peaks, int32_t noPeaks)
{
    float minLoc = peaks[0];
    
    for(int32_t i=0; i < noPeaks; i++)
    {
        if (peaks[i] != 0){
            if( peaks[i] < minLoc)
            {
                minLoc = peaks[i];
            }
        }
    }

    return minLoc;
}

void memsetFloat(float *pt, float num, int32_t len){
    for( int i=0; i<len; i++){
        pt[i] = num;
    }
}

//
// Comparison function used for finding run lengths 
//
utilBool almostEqual(float x, float y, float TOL)
{
  return fabs(x-y) <= TOL;
}

