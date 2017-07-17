
#ifndef __delayBuffer_h__
#define __delayBuffer_h__

#include <stdint.h>

typedef struct delayBuffer
{
    int32_t bufferLength; // size of this delay buffer
    int32_t windowLength; // size of buffer update
    float *data; // pointer to beginning of 10s window
    float *buffer; // pointer to begning of whole buffer
    
    int32_t head; // deprecated
    int32_t tail; // deprecated
    
} DelayBuffer_t;


int32_t delayBufferInit ( DelayBuffer_t *d, float *buffer, int32_t bufferLength, int32_t windowLength);
int32_t delayBufferRead ( DelayBuffer_t *d, float *out);
int32_t delayBufferWrite( DelayBuffer_t *d, float *in);


#endif
