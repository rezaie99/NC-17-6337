

#ifndef qualityCalculate_h
#define qualityCalculate_h

#include <stdio.h>
#include <stdbool.h>
#include "qualityModel.h"
#include "constants.h"
#include "peaksorter.h"
#include "hrModel.h"
// the minimum of the amplitude. This value is define using
#define MIN_dB  -10
// the smallest value for the peak, for SNR definition
// the maximum of the amplitude. This value is define using
#define MAX_dB  10
// the largest value for the peak, for SNR definition
#define MIN_PEAK_BASE  2
#define MIN_QUALITY  0
//#define NUM_ACC_PEAKS_TO_CHOOSE  1
#define NUM_OPT_PEAKS_TO_CHOOSE  3
//#define MIN_OPT_BPM  30
//#define MAX_OPT_BPM  200
// What is consider a good quality data point in BPM Range
#define DEFAULT_BPM_THRESHOLD  4
#define goodQualityBPMThreshold DEFAULT_BPM_THRESHOLD
//window_size, fftLen, sampleRate

typedef struct QualityBuffer
{
    float buffer[HR_ESTAME_CURRENT_BUFFER_LEN];
} QualityBuffer_t;

typedef struct QualityData
{
    PowerSpecData_t  sigPS_pre,
                     sigPS_post,
                     accXPS,
                     accYPS,
                     accZPS,
                     sigPSH,
                     sigPSL,
                     sigPSR;
    QualityModel_t *fdModel;
    QualityModel_t *tdModel;
} QualityData_t;

uint8_t calculateFromModel(float *features,
                           QualityModel_t * model, bool isQuality);

float weightedStd(float *values,
                  float *weights,
                  int bufLen);

float getPeakToTroughRatio(float peak,
                           float *sigPS_specMins,
                           float *sigPS_specPeaks,
                           float *sigPS_specVals,
                           float *sigPS_specMinVals,
                           int bufLen);

float getPeakMotionSeparation(float peak,
                              float *sigPS_specPeaks,
                              float *sigPS_specVals,
                              float *accPS_specPeaks,
                              int bufLen);

void extractNonFrequencyDependentFeatures(
    float *accPS_specPeaks,
    float *accPS_specMins,
    float *accPS_specVals,
    float *accPS_specMinVals,
    utilBool  accPS_harmonic,
    float *accY_specPeaks,
    float *accY_specMins,
    float *accY_specVals,
    float *accY_specMinVals,
    utilBool   accY_harmonic,
    float *accZ_specPeaks,
    float *accZ_specMins,
    float *accZ_specVals,
    float *accZ_specMinVals,
    utilBool   accZ_harmonic,
    int invalidHR_counter,
    float td_peak,
    float fd_peak,
    float fd_peak_pre,
    float sigTrk_freqState,
    float sigTrkPre_freqState,
    float rawDataRange,
    float accXMeanBuff,
    float accYMeanBuff,
    float accZMeanBuff,
    float accXMinBuff,
    float accYMinBuff,
    float accZMinBuff,
    float accXRangeBuff,
    float accYRangeBuff,
    float accZRangeBuff,
    float peak,
    float accMax,
    PowerSpecData_t *sigPSL,
    PowerSpecData_t *sigPSR,
    PowerSpecData_t *sigPS_pre,
    PowerSpecData_t *sigPS_post,
    PowerSpecData_t *sigPSH,
    float* rrIntervalsTemp,
    float* peaksAmplitude,
    float* shortTdPkAmpBuffer,
    float* shortTdRRBuffer,
    float* tdBuffer,
    int numIntervalsTemp,
    float* qualityFeature,
    float* condQualityFeature);

void calculateNonFrequencyDependentQuality(
    float *accPS_specPeaks,
    float *accPS_specMins,
    float *accPS_specVals,
    float *accPS_specMinVals,
    utilBool accPS_harmonic,
    float* accY_specPeaks,
    float* accY_specMins,
    float* accY_specVals,
    float* accY_specMinVals,
    utilBool accY_harmonic,
    float* accZ_specPeaks,
    float* accZ_specMins,
    float* accZ_specVals,
    float* accZ_specMinVals,
    utilBool accZ_harmonic,
    int invalidHR_counter,
    float td_peak,
    float fd_peak,
    float fd_peak_pre,
    float sigTrkpre_freqState,
    float sigTrk_freqState,
    float rawDataRange,
    float accXMeanBuff,
    float accYMeanBuff,
    float accZMeanBuff,
    float accXMinBuff,
    float accYMinBuff,
    float accZMinBuff,
    float accXRangeBuff,
    float accYRangeBuff,
    float accZRangeBuff,
    float peak,
    float accMax,
    uint8_t *timeQuality,
    uint8_t *freqQuality,
    QualityModel_t *fdModel,
    QualityModel_t *tdModel,
    PowerSpecData_t *sigPSL,
    PowerSpecData_t *sigPSR,
    PowerSpecData_t *sigPS_pre,
    PowerSpecData_t *sigPS_post,
    PowerSpecData_t *sigPSH,
    float* rrIntervalsTemp,
    float* peaksAmplitude,
    float* tdPkAmpBuffer,
    float* tdPkRRBuffer,
    int32_t* tdPkNumBuffer,
    int32_t* tdPkAmpBufferStartPointer,
    int32_t* tdPkAmpBufferEndPointer,
    int32_t* tdBufferPointer,
    float* tdBuffer,
    int numIntervalsTemp,
    int32_t* qualityFeaturesBufferIndex,
    QualityBuffer_t* qualityFeaturesBuffer,
    float* qualityFeature,
    float* condQualityFeature);

void getHrPredictorFeatures(float* buffer,int qualityFeaturesBufferIndex, QualityBuffer_t* qualityFeaturesBuffer);
void updateNonFrequencyDependentFeaturesBuffer(float* newFeatures, int* qualityFeaturesBufferIndex, QualityBuffer_t* qualityFeaturesBuffer);

float calculateHrFromModel(float *features, HRModel_t *model);


#endif /* qualityCalculate_h */
