#include <stdbool.h>
#include "afeNormalize.h"

#define OFFSET 0.085
#define TX_CURRENT_VAL 70
#define SAMPLES_TO_INTERPOLATE 8
#define SAMPLES_THAT_USE_PREVIOUS_SETTINGS  2
#define GAIN2_LENGTH 5

static const float GAIN2_MAP[GAIN2_LENGTH] = {1.0, 1.414, 2.0, 2.828, 4.0};

/*
This function performs linear interpolation on the samples ranging from startIndex+1 to stopIndex-1.
*/
void transitionFillIn(float* signal, int32_t startIndex, int32_t stopIndex)
{
    float slope = (signal[stopIndex]-signal[startIndex])/(stopIndex-startIndex);

    for (int32_t i=1; i<(stopIndex-startIndex); i++)
    {
        signal[startIndex+i] = signal[startIndex] + (slope*i);
    }
}

/*
This function performs agc gain and tx-current correction
It also saves agc gain and tx-current settings in afeStructure
Inputs:
    signal
    pPreviousAfe
    numberOfSamples
    frameCount
    tiaGain
    gain2
    offsetCurrent
    txCurrent
Output:
    Does not have dedicated outputs, instead it populates signal and afe structure

*/
void afeNormalize(float* signal, afe_t* pPreviousAfe, int32_t numberOfSamples, int32_t frameCount, int32_t tiaGain, int32_t gain2Idx, int32_t offsetCurrent, int32_t txCurrent)
{
    bool agcStateChanged = false;
    bool txCurrentChanged = false;

    // Check for agc gain and tx-current changes. If frameCount is 1, then do not check because there is no stored history of agc gain and tx-current settings.
    if (frameCount>1)
    {
        if ((tiaGain != pPreviousAfe->tiaGain) || (gain2Idx != pPreviousAfe->gain2Idx) || (offsetCurrent != pPreviousAfe->offsetCurrent))
            agcStateChanged = true;

        if (txCurrent != pPreviousAfe->txCurrent)
            txCurrentChanged = true;
    }

    if (agcStateChanged)
    {
        // Apply gain correction using previous packet
        for (int32_t i=0; i<SAMPLES_THAT_USE_PREVIOUS_SETTINGS; i++)
        {
            signal[i] = signal[i] / GAIN2_MAP[pPreviousAfe->gain2Idx];
            signal[i] = signal[i] + (200 * pPreviousAfe->offsetCurrent);
            signal[i] = signal[i] / pPreviousAfe->tiaGain;
        }

        // Apply gain correction settings to the rest of the samples
        for (int32_t i=SAMPLES_THAT_USE_PREVIOUS_SETTINGS; i<numberOfSamples; i++)
        {
            signal[i] = signal[i] / GAIN2_MAP[gain2Idx];
            signal[i] = signal[i] + (200 * offsetCurrent);
            signal[i] = signal[i] / tiaGain;
        }
    }
    else
    {
        // Apply gain correction to entire packet
        for (int32_t i=0; i<numberOfSamples; i++)
        {
            signal[i] = signal[i] / GAIN2_MAP[gain2Idx];
            signal[i] = signal[i] + (200 * offsetCurrent);
            signal[i] = signal[i] / tiaGain;
        }
    }

    // Apply tx-current correction
    float factor = (float)txCurrent/TX_CURRENT_VAL;

    if (txCurrentChanged)
    {
        // previous tx-current factor
        float previousFactor = (float)pPreviousAfe->txCurrent/TX_CURRENT_VAL;

        //Apply tx-current correction from previous packet
        for (int32_t i=0; i<SAMPLES_THAT_USE_PREVIOUS_SETTINGS; i++)
        {
            signal[i] = ((signal[i] - OFFSET) / previousFactor) + OFFSET;

        }

        //Apply tx-current correction to the rest of the packet
        for (int32_t i=SAMPLES_THAT_USE_PREVIOUS_SETTINGS; i<numberOfSamples; i++)
        {
            signal[i] = ((signal[i] - OFFSET) / factor) + OFFSET;

        }
    }
    else
    {
        // Apply tx-current correction to entire packet
        for (int32_t i=0; i<numberOfSamples; i++)
        {
            signal[i] = ((signal[i] - OFFSET) / factor) + OFFSET;

        }
    }

    // If there was either a gain or tx-current change, apply interpolation
    if (agcStateChanged || txCurrentChanged)
    {
        int32_t startIndex = SAMPLES_THAT_USE_PREVIOUS_SETTINGS-1;
        int32_t endIndex = SAMPLES_THAT_USE_PREVIOUS_SETTINGS+SAMPLES_TO_INTERPOLATE;
        transitionFillIn(signal, startIndex, endIndex);
    }

    // Save agc gain and tx-current settings
    pPreviousAfe->gain2Idx = gain2Idx;
    pPreviousAfe->tiaGain = tiaGain;
    pPreviousAfe->offsetCurrent = offsetCurrent;
    pPreviousAfe->txCurrent = txCurrent;
}
