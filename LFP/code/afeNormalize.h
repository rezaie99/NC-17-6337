#ifndef afeNormalize_h
#define afeNormalize_h

#include <stdio.h>

typedef struct afeTag
{
    int32_t tiaGain;
    int32_t gain2Idx;
    int32_t offsetCurrent;
    int32_t txCurrent;
} afe_t;

void afeNormalize(float* signal, afe_t* pAfe, int32_t numberOfSamples, int32_t frameCount, int32_t tiaGain, int32_t gain2Idx, int32_t offsetCurrent, int32_t txCurrent);

#endif /* afeNormalize_h */
