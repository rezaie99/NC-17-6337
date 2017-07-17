
#ifndef __trackFilter_h__
#define __trackFilter_h__

#include <stdint.h>
#include "constants.h"
#include <math.h>

#define MAX_DIFFERENCE 20
#define DELTA_T  1000
#define MAX_DELTA_T 3*DELTA_T

static const float ALPHA = 0.1f;
static const float BETA = 0.0f;
static const float ALPHA2 = 0.2f;


typedef struct
{
    float freqState;
    float deltaFreqState;
    
    float alpha;
    float beta;
    
    int32_t boundlo;
    int32_t boundhi;
    
    int32_t init;
    
}ABTracker_t;


void AB_trackFilterInit(ABTracker_t *tracker_params, float start, float alpha, float beta, int32_t boundlo, int32_t boundhi);
void AB_trackFilterUpdate(ABTracker_t *tracker_params, float deltaT, float newMeasure);
void AB_coasting(ABTracker_t *tracker_params);

#endif


