

#include <stdio.h>
#include <string.h>
#include <math.h>

#include "peakFilter.h"
#include "sigprocDebug.h"
#include "sigprocData.h"
#include "delayBuffer.h"
#include "constants.h"

//TODO - confifurable sample rate
//TODO - threadable ???

//static const int32_t PK_LOCAL_WINDOW = 10;

static const float PK_DECAY = .9;
static const float PK_THRESH = .9;
static const float PK_DRANGE_CEOFF = .01;


static int32_t vectorArgMax( float *x, int32_t len)
{
    
    float max = x[0];
    int32_t maxLoc = 0;
    
    for( int32_t i=0; i<len; i++)
    {
        if( x[i] > max)
        {
            max = x[i];
            maxLoc = i;
        }
    }
    
    return maxLoc;
}

static float vectorMax( float *x, int32_t len)
{
    
    float max = x[0];
    
    for( int32_t i=0; i<len; i++)
    {
        if( x[i] > max)
        {
            max = x[i];
        }
    }
    
    return max;
}

static float vectorMin( float *x, int32_t len)
{
    
    float min = x[0];
    
    for( int32_t i=0; i<len; i++)
    {
        if( x[i] < min)
        {
            min = x[i];
        }
    }
    
    return min;
}

static int32_t localizePeaks( PeakFilterInstance_t *pk, float *rrIntervals, int32_t *peakLocs)
{
    
    
    float *p = &pk->delayBuff.data[WINDOW_LENGTH];
    int32_t rrIntervalCount = 0;
    
    pk->dynamicRange = 0;
    
    for( int32_t i=0; i < WINDOW_LENGTH; i++)
    {
        
        float diff = fabs(pk->peakFiltMax[i] - pk->peakFiltMin[i]);
        float thresh = pk->peakFiltMax[i] - diff*(1-PK_THRESH);
        
        //the dynamic range is the filtered difference of the max and min signal envelopes which are
        //computed by the peak filter
        pk->dynamicRangeHist += ( diff - pk->dynamicRangeHist)*PK_DRANGE_CEOFF;
        
        //compute the max value of the filtered output in this window
        if( pk->dynamicRangeHist > pk->dynamicRange)
        {
            pk->dynamicRange = pk->dynamicRangeHist;
        }
        
        if( p[i] > thresh)
        {
            
            if( i - pk->peakLocHist < PK_FILTER_LENGTH )
            {
                continue;
            }

            //printf("Crossing: %d Val: %f Thresh: %f Hist: %d\n",i+count,p[i],thresh,i-peakLocHist);
            
            float *start = &pk->delayBuff.data[WINDOW_LENGTH + i];
            int32_t peakLoc = vectorArgMax(start, PK_FILTER_LENGTH) + i;
            
            if( rrIntervalCount < PK_FILTER_MAX_INTERVALS)
            {
                peakLocs[rrIntervalCount] = peakLoc;
                rrIntervals[rrIntervalCount] = (float)(peakLoc - pk->peakLocHist)/SAMPLE_RATE;
                
                //printf("Val: %f Loc: %d Thresh: %f RR: %f\n",p[peakLoc],peakLoc+count,thresh, rrIntervals[rrIntervalCount]);
                rrIntervalCount++;
                
            }
            
            pk->peakLocHist = peakLoc;
        }
    }
    pk->peakLocHist -= WINDOW_LENGTH;

    
    return(rrIntervalCount);
}


int32_t peakFilterInit( PeakFilterInstance_t *pk )
{
    
    memset(pk->delayBuffMem,0,sizeof(float)*PEAK_BUFFER_LENGTH);
    memset(pk->peakHistMem,0,sizeof(float)*PK_FILTER_LENGTH);
    
    delayBufferInit(&pk->delayBuff, pk->delayBuffMem, PEAK_BUFFER_LENGTH, WINDOW_LENGTH);
    delayBufferInit(&pk->peakHist, pk->peakHistMem, PK_FILTER_LENGTH, 1);
    
    pk->currentMax = -1e6;
    pk->currentMin = 1e6;
    pk->count = 0;
    pk->peakLocHist=0;
    
    pk->dynamicRangeHist = 0;
    
    return 0;
}

int32_t peakFilterRun( PeakFilterInstance_t *pk, float *in, float *rrIntervals, int32_t *peakLocs, float* peaksAmplitude)
{
    
    //update the history delay buffer
    delayBufferWrite( &pk->delayBuff, in);
    
    
    //find the max and and min in the sliding window
    float *window = &pk->delayBuff.data[WINDOW_LENGTH+15];
    for( int32_t ind=0; ind < WINDOW_LENGTH; ind++)
    {
        
        //shift in the new value
        delayBufferWrite(&pk->peakHist, &window[ind]);
        
        
        float tempMax = vectorMax(pk->peakHist.data, PK_FILTER_LENGTH);
        if( tempMax > pk->currentMax)
        {
            //use the new max
            pk->currentMax = tempMax;
        }
        else
        {
            //decay the max a little bit to adapt to the running max
            pk->currentMax -= (1.0-PK_DECAY)*(pk->currentMax - tempMax);
        }
        pk->peakFiltMax[ind] = pk->currentMax;
        
        
        float tempMin = vectorMin(pk->peakHist.data, PK_FILTER_LENGTH);
        if( tempMin < pk->currentMin)
        {
            pk->currentMin = tempMin;
        }
        else
        {
            pk->currentMin -= (1.0-PK_DECAY)*(pk->currentMin - tempMin);

        }
        pk->peakFiltMin[ind] = pk->currentMin;
        
        
        
    }
    
    
    //localize the peaks using the treshold crossing
    int32_t rrIntervalCount = localizePeaks( pk, rrIntervals, peakLocs);
    pk->count += WINDOW_LENGTH;
    for(int i=0;i<rrIntervalCount;i++)
        peaksAmplitude[i] = pk->delayBuff.data[WINDOW_LENGTH + peakLocs[i]];
    return rrIntervalCount;
}

