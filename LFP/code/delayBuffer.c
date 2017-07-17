

#include <stdio.h>
#include <string.h>

#include "delayBuffer.h"

int32_t delayBufferInit ( DelayBuffer_t *d, float *buffer, int32_t bufferLength, int32_t windowLength)
{
    d->bufferLength = bufferLength;
    d->windowLength = windowLength;
    memset(buffer, 0, sizeof(float)*bufferLength);
    d->buffer = buffer; // points to begning of the buffer
    d->data = &d->buffer[0]; // same as d->buffer
    
    d->head = d->bufferLength - d->windowLength; // deprecated
    d->tail = d->windowLength; // deprecated
    
    return(0);
}

int32_t delayBufferRead ( DelayBuffer_t *d, float *out) // deprecated
{
    memcpy((void *)out, &d->data[d->tail], d->windowLength*sizeof(float));
    
    return(0);
}


int32_t delayBufferWrite( DelayBuffer_t *d, float *in)
{
    memmove((void *)&d->buffer[0], (void *)&d->buffer[d->windowLength], (d->bufferLength - d->windowLength)*sizeof(float));
    memcpy((void *)&d->buffer[d->bufferLength - d->windowLength], (void *)in, d->windowLength*sizeof(float));
    
    return(0);
}
