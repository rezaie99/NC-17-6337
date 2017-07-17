

#ifndef sigprocIOS_peakFilter_h
#define sigprocIOS_peakFilter_h

#include <stdint.h>

#include "delayBuffer.h"

#define PK_FILTER_LENGTH 50
#define WINDOW_LENGTH 100
#define PEAK_BUFFER_LENGTH 3*WINDOW_LENGTH


typedef struct peakFilterInstTag
{
    float delayBuffMem[PEAK_BUFFER_LENGTH];
    DelayBuffer_t delayBuff;
    
    float peakHistMem[PK_FILTER_LENGTH];
    DelayBuffer_t peakHist;
    
    int32_t peakLocHist;
    
    float currentMax;
    float currentMin;
    
    float peakFiltMax[WINDOW_LENGTH];
    float peakFiltMin[WINDOW_LENGTH];
    
    float dynamicRange;
    float dynamicRangeHist;
    
    int32_t count;

    
}PeakFilterInstance_t;


int32_t peakFilterInit( PeakFilterInstance_t *pk );
int32_t peakFilterRun( PeakFilterInstance_t *pk, float *in, float *rrIntervals, int32_t *peakLocs, float* peaksAmplitude);




#endif
