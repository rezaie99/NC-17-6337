#ifndef Utilities_utils_h
#define Utilities_utils_h

#include <stdlib.h>
#include <stdint.h>

typedef enum {
    UTIL_FALSE = 0,
    UTIL_TRUE = 1
} utilBool;

// Utility functions for 1D arrays

void ReverseInPlace(float *arr, uint32_t size);

float GetSum(const float *arr, uint32_t size);

uint32_t GetSumBool(const uint8_t *arr, uint32_t size);


float GetMean(const float *arr, uint32_t size);

void NormalizeArray(float *arr, uint32_t size);

int CountTrues(const utilBool *indicator, uint32_t size);

int GetMaxLocation(const float *arr, uint32_t size);

int GetMinLocation(const float *arr, uint32_t size);

void FindSortIndexes(const float *arr, int *sortIndexes, uint32_t size);

float DotProduct(const float *arr1, const float *arr2, uint32_t size);

void FindLocations(const float *arr, utilBool *indicator, uint32_t size, float element);

void GetLocalMaxLocationsSimple(const float *arr, utilBool *indicator, uint32_t size, utilBool choice);

// Misc Functions

int compare_floats (const void *a, const void *b);

int compare_int32 (const void *a, const void *b);

void GenerateGaussian(float mean, float std, const float *arr, float *gauss, uint32_t size);

void Convolve(const float *arrSignal, float *arrKernel, float *arrOut, uint32_t sizeSignal, uint32_t sizeKernel);

float GetMaxValue(const float *arr, uint32_t size);
float GetMaxAbsValue(const float *arr, uint32_t size);

float getMinDistancePeak (float freqState, float* peaks, int32_t noPeaks);

int32_t getMinDistanceIndex (float freqState, float* peaks, int32_t noPeaks);

int32_t getMinPeakLocation (float* peaks,  int32_t noPeaks);

void memsetFloat(float *pt, float num, int32_t len);

utilBool almostEqual(float x, float y, float TOL);

#endif
