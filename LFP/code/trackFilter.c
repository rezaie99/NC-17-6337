#include <stdint.h>
#include <stdlib.h>
#include <stdio.h>
#include "trackFilter.h"

void AB_trackFilterInit( ABTracker_t *tracker_params, float start, float alpha, float beta, int32_t boundlo, int32_t boundhi)
{
    tracker_params->alpha = alpha;
    tracker_params->beta = beta;
    tracker_params->freqState = start;
    tracker_params->deltaFreqState = 0;
    
    tracker_params->boundlo = boundlo;
    tracker_params->boundhi = boundhi;
    
    tracker_params->init = 0;
    
}

void AB_trackFilterUpdate(ABTracker_t *tracker_params, float deltaT, float newMeasure)
{
    
    if ( deltaT > MAX_DELTA_T){
        deltaT = MAX_DELTA_T;
    }
    
    // if deltaT is equal to zero, there has possibly been some drift in the clock,
    // so assume that deltaT is DELTA_T, otherwise there would be a division by zero later on.
    if ( deltaT == 0){
        deltaT = DELTA_T;
    }
    
    deltaT = deltaT/1000;
    
    //Check if coasting is needed or if no peak was found
    if ( (newMeasure == AGC_COASTING_FLAG) || (newMeasure==BAD_DATA) ){
        AB_coasting(tracker_params);
        return;
    }
    
    //Check that newMeasure is within bounds
    if( (newMeasure > tracker_params->boundhi) || (newMeasure < tracker_params->boundlo))
    {
        tracker_params->deltaFreqState = 0;
        newMeasure = tracker_params->freqState;
    }
    
    
    //Check that deltaFreq is within bounds
    if (tracker_params->deltaFreqState > 0.5)
    {
        tracker_params->deltaFreqState =  0.5;
    }
    else if(tracker_params->deltaFreqState< -0.5)
    {
        tracker_params->deltaFreqState = -0.5;
    }
	tracker_params->deltaFreqState = 0;  // disable beta tracker
	
    //This line makes a prediction for freqState for the present time
    tracker_params->freqState += deltaT * tracker_params->deltaFreqState;
    
    
    float alpha = tracker_params->alpha;
    float beta = tracker_params->beta;
    
    float residual = newMeasure - tracker_params->freqState;
    
    if(fabsf(residual) > MAX_DIFFERENCE)
    {
        if (residual > 0){
            
            residual = MAX_DIFFERENCE;
        }
        else{
            
            residual = -1.0*MAX_DIFFERENCE;
        }

    }

    
    //Update States
    tracker_params->freqState += alpha*residual;
    tracker_params->deltaFreqState += (beta/deltaT)*residual;
    
    
    //Check that freqState is within bounds
    if (tracker_params->freqState > tracker_params->boundhi)
    {
        tracker_params->freqState = tracker_params->boundhi;
        tracker_params->deltaFreqState = 0;
    }
    else if (tracker_params->freqState < tracker_params->boundlo)
    {
        tracker_params->freqState = tracker_params->boundlo;
        tracker_params->deltaFreqState = 0;
    }
    
    return;

}

void AB_coasting(ABTracker_t *tracker_params){
    
    tracker_params->deltaFreqState = 0;
    
    return;
}
