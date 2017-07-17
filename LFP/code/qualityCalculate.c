#include "qualityCalculate.h"
#include <stdlib.h>
#include <math.h>
#include "utils.h"

#define abs(x) ((x)<0 ? -(x) : (x))



float log10_(float x)
{
    return log10(abs(x + 0.001));

}
void getMinDistPeak(float *sigPS_specPeaks, float td_peak, float* minPeak, int32_t* loc, int32_t noPeaks)
{
    (*minPeak) = getMinDistancePeak(td_peak, sigPS_specPeaks, noPeaks) ;
    (*loc)     =  getMinDistanceIndex(td_peak, sigPS_specPeaks, noPeaks) ;
    if ((*minPeak) == 99999)
        (*minPeak) = -1;
}

/*
 Return the point to t-nth feature vector, n=0 returns the last updated feature vector
 inputs qualityFeaturesBufferIndex the pointer to the head of the buffer
 qualityFeaturesBuffer: the buffer
*/
float* getPreviousFeature(int32_t n, int qualityFeaturesBufferIndex, QualityBuffer_t* qualityFeaturesBuffer)
{
    int tempQualityFeaturesBufferIndex = qualityFeaturesBufferIndex - n;
    if (tempQualityFeaturesBufferIndex < 0)
        tempQualityFeaturesBufferIndex = QUALITY_HISTORY_BUFFER_LEN + tempQualityFeaturesBufferIndex;
    return qualityFeaturesBuffer[tempQualityFeaturesBufferIndex].buffer;
}

/*
 Update the circular buffer holding the history for features for the model
 inputs: newFeatures: feature vector, qualityFeaturesBufferIndex: the index to the current position of buffer,
 qualityFeaturesBuffer: Buffer
 output: qualityFeaturesBufferIndex: int value pointer to new head of Buffer,
*/
void updateNonFrequencyDependentFeaturesBuffer(float* newFeatures, int* qualityFeaturesBufferIndex, QualityBuffer_t* qualityFeaturesBuffer)
{
    *qualityFeaturesBufferIndex = *qualityFeaturesBufferIndex + 1;
    if (*qualityFeaturesBufferIndex >= QUALITY_HISTORY_BUFFER_LEN)
        *qualityFeaturesBufferIndex = 0;
    for (int i=0; i<HR_ESTAME_CURRENT_BUFFER_LEN; i++)
        qualityFeaturesBuffer[*qualityFeaturesBufferIndex].buffer[i] = newFeatures[i];
}

/*
   Cacluate the quality for time or frquency domain
   The input is the feature vector and one of the models from qualityModel.c
   The function returns the quality estimate. The output is  bounded and
   can be any int value between 0-255. if isQuality is False, The output is not bounded
   isQuality should be true for all quality calcualtion
*/
uint8_t calculateFromModel(float *features, QualityModel_t *model, bool isQuality)
{
    float modelResult = 0;
    int node = 0;

    //for each booster, calculate the score from the tree
    for (int booster = 0; booster < model->noOfBoosters; booster++)
    {
        node = 0;
        // For each Booster tree, first traverse through the tree to reach a leaf
        // To do this, find a zero element of yesTree
        while(model->yesTree[booster][node] != 0)
        {
            if (features[model->fLabel[booster][node]] < model->fValue[booster][node])
            {
                node = model->yesTree[booster][node];
            }
            else
            {
                node = model->noTree[booster][node];
            }
            // If the traverse reaches a leaf, add the scores from current tree to the total score of booster
        }
        modelResult = modelResult + model->leafValue[booster][node];
    }
    if (isQuality)
    {
        // Scale the result of the model, the final value should be in the 0 to 1 range
        modelResult = (modelResult - model->base) / model->scale;
        // Check if the quality value is between 0 and 1, then map it to 0-255 integer
        if (modelResult < 0)
        {
            modelResult = 0;
        }
        if (modelResult > 1)
        {
            modelResult = 1;
        }
        return (uint8_t)(round(modelResult * 255));
    }
    else
        return (uint8_t)(modelResult + 0.5);

}
/*
   Cacluate the HR model for time or frquency domain
   The input is the feature vector and one of the models from hrModel.c
   The function returns the HR estimate. The output is not bounded and
   can be any float value
*/
float calculateHrFromModel(float *features, HRModel_t *model)
{
    float modelResult = 0;
    int node = 0;

    //for each booster, calculate the score from the tree
    for (int booster = 0; booster < model->noOfBoosters; booster++)
    {
        node = 0;
        // For each Booster tree, first traverse through the tree to reach a leaf
        // To do this, find a zero element of yesTree
        while(model->yesTree[booster][node] != 0)
        {
            if (features[model->fLabel[booster][node]] < model->fValue[booster][node])
            {
                node = model->yesTree[booster][node];
            }
            else
            {
                node = model->noTree[booster][node];
            }
            // If the traverse reaches a leaf, add the scores from current tree to the total score of booster
        }
        modelResult = modelResult + model->leafValue[booster][node];
    }
    return modelResult;

}

// Implementation of numpy weighted STD
float weightedStd(float *values,
                  float *weights,
                  int bufLen)
{

    float dist, dist2;
    float average = 0;
    int count = 0;
    float sum_dist2 = 0;
    float sum_weight = 0;
    for (int i = 0; (i < bufLen); i++)
    {
        average += values[i] * weights[i];
        sum_weight += weights[i];
        count++;
    }

    if (count > 0)
    {
        average = average / sum_weight;
    }
    else
    {
        return 0;
    }

    for (int i = 0; i < bufLen; i++)
    {
        dist = values[i] - average;
        dist2 = dist * dist * weights[i];
        sum_dist2 += dist2;
    }
    if (sum_weight == 0)
    {
        return 0;
    }
    else
    {
        return sqrt(sum_dist2 / sum_weight);
    }
}

/*
find the std of variable, This function is ignoring any zero value
:param values,
:return the  standard deviation.
*/
float varf(float *values,
           int bufLen)
{
    float weights[bufLen];
    for (int i = 0; i<bufLen; i++)
    {
        weights[i] = 0;
        if (values[i] != 0)
            weights[i] = 1;
    }
    return weightedStd(values,weights,bufLen);
}

/*
Find median of an array
*/
float median(int n, float x[]) {
    float temp;
    int i, j;
    // the following two loops sort the array x in ascending order
    for(i=0; i<n-1; i++) {
        for(j=i+1; j<n; j++) {
            if(x[j] < x[i]) {
                // swap elements
                temp = x[i];
                x[i] = x[j];
                x[j] = temp;
            }
        }
    }

    if(n%2==0) {
        // if there is an even number of elements, return mean of the two elements in the middle
        return((x[n/2] + x[n/2 - 1]) / 2.0);
    } else {
        // else return the element in the middle
        return x[n/2];
    }
}


/*
Find the closest peak which is defines a the value of peak over base of the peak (quality factor of peak)
:param peak: the value of the peak in the frequency domain
:param sigPS: the spectrum of the variable
:return: the quality
*/
float getPeakToTroughRatio(float peak,
                           float *sigPS_specMins,
                           float *sigPS_specPeaks,
                           float *sigPS_specVals,
                           float *sigPS_specMinVals,
                           int bufLen)
{


    int32_t minLoc = getMinDistanceIndex(peak, sigPS_specMins, NUM_OPT_PEAKS_TO_CHOOSE) ;
    int32_t maxLoc = getMinDistanceIndex(peak, sigPS_specPeaks, NUM_OPT_PEAKS_TO_CHOOSE) ;
    float peakAmplitude = 20 *  log10_(sigPS_specVals[maxLoc]) - 20 * log10_(sigPS_specMinVals[minLoc]);
    float peakBase = abs(sigPS_specPeaks[maxLoc] - sigPS_specMins[minLoc]);
    if (peakBase < MIN_PEAK_BASE)   //  making sure the base is not zero
    {
        peakBase = MIN_PEAK_BASE;
    }
    return peakAmplitude / peakBase;
}
/*
Find the separation between peak and motion peaks. Then return the ratio of amplitude over the distance
between peaks.
:param peak: the value of the peak in the frequency domain
:param sigPS_specMins, sigPS_specPeaks, sigPS_specVals: the optical signal spectrum
:param accPS_specMins,accPS_specPeaks, accPS_specVals: the accelerometer spectrum
:return: the ratio of amplitude of the peak over the distance between peaks
*/
float getPeakMotionSeparation(float peak,
                              float *sigPS_specPeaks,
                              float *sigPS_specVals,
                              float *accPS_specPeaks,
                              int bufLen)
{
    float separation = MAX_dB;
    // find the closest peak to the candidate peak
    int32_t optLoc = getMinDistanceIndex(peak, sigPS_specPeaks, bufLen);

    for (int i=0; i<NUM_ACC_PEAKS_TO_CHOOSE; i++)
    {
        //# find the closest motion peak
        if (accPS_specPeaks[i] ==0 )
            break;
        int32_t accLoc = getMinDistanceIndex(accPS_specPeaks[i],sigPS_specPeaks, bufLen);
        if (sigPS_specPeaks[accLoc] - accPS_specPeaks[i] > ACC_OPT_TRANS_TOL)
            separation = MIN(separation,log10_(sigPS_specPeaks[optLoc]) + log10_(sigPS_specVals[optLoc]));
        else
            separation = MIN(separation,log10_(abs(sigPS_specPeaks[optLoc] - sigPS_specPeaks[accLoc])) +log10_(sigPS_specVals[optLoc]) - log10_(sigPS_specVals[accLoc]));
    }

    return separation;
}

/*
This function receives several parameters from trackStreaming. It takes in a 10 second buffer of data optical
and ambient as well as some attributes of powerSpec objects for all three accelerometers.
These inputs are used to populate a total of 58 data quality features.
:param: Receives a lot of parameters from trackStreaming, see calculateDataQuality and trackStreaming
for the descriptions store  the features for the quality check
:return: None
 */
void extractNonFrequencyDependentFeatures(
    float *accPS_specPeaks,
    float *accPS_specMins,
    float *accPS_specVals,
    float *accPS_specMinVals,
    utilBool   accPS_harmonic,
    float *accY_specPeaks,
    float *accY_specMins,
    float *accY_specVals,
    float *accY_specMinVals,
    utilBool   accY_harmonic,
    float *accZ_specPeaks,
    float *accZ_specMins,
    float *accZ_specVals,
    float *accZ_specMinVals,
    utilBool  accZ_harmonic,
    //int timeStamp,
    int invalidHR_counter,
    float td_peak,
    float fd_peak,
    float fd_peak_pre,
    //float accThreshFreqProcessing,
    float sigTrk_freqState,
    float sigTrkpre_freqState,
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
    //int k,
    float accMax,
    PowerSpecData_t *sigPSL,
    PowerSpecData_t *sigPSR,
    PowerSpecData_t *sigPS_pre,
    PowerSpecData_t *sigPS_post,
    PowerSpecData_t *sigPSH,
    float* tdPkRRBuffer,
    float* tdPkAmpBuffer,
    float* shortTdPkAmpBuffer,
    float* shortTdRRBuffer,
    float* tdBuffer,
    int numIntervalsTemp,
    float* qualityFeature,
    float* condQualityFeature)

{
    float minPeak;
    int32_t loc;
    PowerSpecData_t accYPS;
    PowerSpecData_t accZPS;
    for (int i =0; i<NUM_ACC_PEAKS_TO_CHOOSE; i++)
    {
        accYPS.specPeaks[i] = accY_specPeaks[i];
        accYPS.specMins[i]  = accY_specMins[i];
        accYPS.specVals[i]  = accY_specVals[i];
        accYPS.specMinVals[i] = accY_specMinVals[i];
        accZPS.specPeaks[i] = accZ_specPeaks[i];
        accZPS.specMins[i]  = accZ_specMins[i];
        accZPS.specVals[i]  = accZ_specVals[i];
        accZPS.specMinVals[i] = accZ_specMinVals[i];
    }


    // Feature 1-2 Time-Frequency Consistency, similarity between two consecutive blocks of data

    float peakL = sigPSL->specPeaks[0];
    float peakR = sigPSR->specPeaks[0];

    if (peakL > 0)
    {
        qualityFeature[FEATURE_FIXED_FRQ_CONSIST] = 1 - abs(peakL - peakR) / peakL;
    }
    else
    {
        qualityFeature[FEATURE_FIXED_FRQ_CONSIST] = 0;
    }

    if ((fd_peak > 0) & (td_peak != INVALID_TD_ESTIMATE))
    {
        qualityFeature[FEATURE_FIXED_TIM_CONSIST] = 1 - abs(fd_peak - td_peak) / fd_peak;
    }
    else
    {
        qualityFeature[FEATURE_FIXED_TIM_CONSIST] = 0;
    }

    //  Feature 3 = Change in the spectrum's top peak after motion cancellation
    qualityFeature[FEATURE_FIXED_PRE_POST_1ST_PEAK_DF] = abs(sigPS_pre->specPeaks[0] - sigPS_post->specPeaks[0]);

    //  Feature 4 = is optical signal (before motion cancellation)
    //  fft-harmonic?
    qualityFeature[FEATURE_FIXED_PRE_FFT_HARMONIC] = sigPS_pre->fft_harmonic;

    //  Feature 5 = is optical signal (before motion cancellation)
    //  hps-harmonic?
    qualityFeature[FEATURE_FIXED_PRE_HPS_HARMONIC] = sigPS_pre->hps_harmonic;

    //  Feature 6 = is optical signal (before motion cancellation) harmonic?
    qualityFeature[FEATURE_FIXED_PRE_HARMONIC] = sigPS_pre->harmonic;

    //  Feature 7 = is the Top peak selected in tracker before motion cancellation
    qualityFeature[FEATURE_FIXED_PRE_TOP_PEAK_EXIST] = 1 * (sigPS_pre->topPeak != 0);

    //Feature 8 = is optical signal fft harmonic?
    qualityFeature[FEATURE_FIXED_POST_FFT_HARMONIC] = sigPS_post->fft_harmonic;

    //Feature 9 = is optical signal hps harmonic?
    qualityFeature[FEATURE_FIXED_POST_HPS_HARMONIC] = sigPS_post->hps_harmonic;

    //Feature 10 = is optical signal harmonic?
    qualityFeature[FEATURE_FIXED_POST_HARMONIC] = sigPS_post->harmonic;

    //Feature 11 = is the top peak selected from optical signal?
    qualityFeature[FEATURE_FIXED_POST_TOP_PEAK_EXIST] = 1 * (sigPS_post->topPeak != 0);

    //Feature 12 = is the motion passed the time frequency selection threshold?
    qualityFeature[FEATURE_FIXED_MOTION_THR] = accMax;


    //Feature 13 = The amplitude of the closest peak in the spectrum to
    //td-peak, if it is too far MIN_dB
    getMinDistPeak(sigPS_post->specPeaks, td_peak, &minPeak, &loc, NUM_OPT_PEAKS_TO_CHOOSE);
    if ((abs(minPeak - td_peak) > 5)|(td_peak == INVALID_TD_ESTIMATE))
    {
        qualityFeature[FEATURE_FIXED_POST_AMP_PEAK_CLOSEST_TO_TDPEAK] = MIN_dB;
    }
    else
    {
        qualityFeature[FEATURE_FIXED_POST_AMP_PEAK_CLOSEST_TO_TDPEAK] = 20 * log10_(sigPS_post->specVals[loc]);
    }

    //  Feature 14 = fd_peak amplitude
    getMinDistPeak(sigPS_post->specPeaks, fd_peak, &minPeak, &loc, NUM_OPT_PEAKS_TO_CHOOSE);
    qualityFeature[FEATURE_FIXED_POST_AMP_PEAK_CLOSEST_TO_FDPEAK] = 20 * log10_(sigPS_post->specVals[loc]);

    //  Feature 15 = peak amplitude
    getMinDistPeak(sigPS_post->specPeaks, peak, &minPeak, &loc, NUM_OPT_PEAKS_TO_CHOOSE);
    qualityFeature[FEATURE_FIXED_POST_AMP_PEAK_CLOSEST_TO_TRACKERIN] = 20 * log10_(sigPS_post->specVals[loc]);

    //Feature 16 = sigTrk_freqState amplitude in the spectrum if exist
    getMinDistPeak(sigPS_post->specPeaks, sigTrk_freqState, &minPeak, &loc,NUM_OPT_PEAKS_TO_CHOOSE);
    if (abs(minPeak - sigTrk_freqState) > goodQualityBPMThreshold)
    {
        qualityFeature[FEATURE_FIXED_POST_AMP_PEAK_CLOSEST_TO_TRACKER] = MIN_dB;
    }
    else
    {
        qualityFeature[FEATURE_FIXED_POST_AMP_PEAK_CLOSEST_TO_TRACKER] = 20 * log10_(sigPS_post->specVals[loc]);
    }

    //  Feature 17 = distance between top 2 peaks in the spectrum
    if (sigPS_post->specPeaks[1] != 0)
    {
        qualityFeature[FEATURE_FIXED_FIRST_SECOND_PEAK_DF] = 20 * log10_(sigPS_post->specVals[0]) - 20 * log10_(sigPS_post->specVals[1]);
    }
    else
    {
        qualityFeature[FEATURE_FIXED_FIRST_SECOND_PEAK_DF] = MAX_dB;
    }

    //  Feature 18 = number of non-zero peaks in spectrum
    int i = 0;
    while(i<NUM_OPT_PEAKS_TO_CHOOSE)
        if (sigPS_post->specPeaks[i] > 0)
            i++;
        else
            break;
    qualityFeature[FEATURE_FIXED_NUM_POST_PEAKS] = i;

    //  Feature 19 = number of peaks in motion spectrum
    i = 0;
    while( i<(NUM_ACC_PEAKS_TO_CHOOSE))
        if (accPS_specPeaks[i] > 0)
            i++;
        else
            break;

    qualityFeature[FEATURE_FIXED_NUM_ACC_PEAKS] = i;

    //  Feature 20
    qualityFeature[FEATURE_FIXED_TD_PEAK_EXIST] = 1* (td_peak>0);

    //  Feature 21-23 = find closest peak in the accelerometer to highest peak, get the distance and relative amplitude
    getMinDistPeak(accPS_specPeaks, sigPS_pre->specPeaks[0], &minPeak, &loc, NUM_ACC_PEAKS_TO_CHOOSE);
    qualityFeature[FEATURE_FIXED_POST_ACCPEAK_CLOSEST_TO_FIRSTPEAK] = abs(minPeak - sigPS_pre->specPeaks[0]);
    qualityFeature[FEATURE_FIXED_PRE_AMP_FIRSTPEAK_ACCPEAK_DF] = 20 * log10_(sigPS_pre->specVals[0]) - 20 * log10_(sigPS_pre->spect_at_X);
    qualityFeature[FEATURE_FIXED_1ST_ACCPEAK_AMP] = 20 * log10_(accPS_specVals[0]);

    //  Feature 24-26 = find closest peak in the Y accelerometer to highest peak, get the distance and relative amplitude
    getMinDistPeak(accYPS.specPeaks, sigPS_pre->specPeaks[0], &minPeak, &loc, NUM_ACC_PEAKS_TO_CHOOSE);
    qualityFeature[FEATURE_FIXED_PRE_FIRSTPEAK_YACCPEAK_DF] = abs(minPeak - sigPS_pre->specPeaks[0]);
    qualityFeature[FEATURE_FIXED_TD_PEAK_AMP_LONGHIST_VAR] = varf(tdPkAmpBuffer,MAX_TD_BUFFER_LEN);
    qualityFeature[FEATURE_FIXED_PRE_FIRSTPEAK_YACCPEAK_AMP_DF] = 20 * log10_(sigPS_pre->specVals[0]) - 20 * log10_(sigPS_pre->spect_at_Y);


    //  Feature 27-29 = find closest peak in the Z accelerometer to highest peak, get the distance and relative amplitude
    getMinDistPeak(accZPS.specPeaks, sigPS_pre->specPeaks[0], &minPeak, &loc, NUM_ACC_PEAKS_TO_CHOOSE);
    qualityFeature[FEATURE_FIXED_PRE_FIRSTPEAK_ZACCPEAK_DF] = abs(minPeak - sigPS_pre->specPeaks[0]);
    qualityFeature[FEATURE_FIXED_TD_RR_LONGHIST_VAR] = 100*varf(tdPkRRBuffer,MAX_TD_BUFFER_LEN);
    qualityFeature[FEATURE_FIXED_PRE_FIRSTPEAK_ZACCPEAK_AMP_DF] = 20 * log10_(sigPS_pre->specVals[0]) - 20 * log10_(sigPS_pre->spect_at_Z);

    //  Feature 30-31 = the variance of optical signal spectrum peaks (amplitude and peaks)
    qualityFeature[FEATURE_FIXED_POST_PEAK_VAR] = varf(sigPS_post->specPeaks, NUM_OPT_PEAKS_TO_CHOOSE);
    qualityFeature[FEATURE_FIXED_POST_PEAK_AMP_VAR] = varf(sigPS_post->specVals, NUM_OPT_PEAKS_TO_CHOOSE);

    //  Feature 32-33 = the variance of accelerometer spectrum peaks (amplitude and peaks)
    qualityFeature[FEATURE_FIXED_ACC_PEAK_VAR] = varf(accPS_specPeaks, NUM_ACC_PEAKS_TO_CHOOSE);
    qualityFeature[FEATURE_FIXED_ACC_PEAK_AMP_VAR] = varf(accPS_specVals, NUM_ACC_PEAKS_TO_CHOOSE);

    //  Feature 34-35 = the peak to base ratio (peak quality factor) of optical signal highest
    //   before and after motion cancellation
    qualityFeature[FEATURE_FIXED_QUALITY_POST_1ST_PEAK] = getPeakToTroughRatio(sigPS_post->specPeaks[0], sigPS_post->specMins, sigPS_post->specPeaks,
            sigPS_post->specVals, sigPS_post->specMinVals, NUM_OPT_PEAKS_TO_CHOOSE) ;
    qualityFeature[FEATURE_FIXED_QUALITY_PRE_1ST_PEAK] = getPeakToTroughRatio(sigPS_pre->specPeaks[0], sigPS_pre->specMins, sigPS_pre->specPeaks,
            sigPS_pre->specVals, sigPS_pre->specMinVals, NUM_OPT_PEAKS_TO_CHOOSE) ;

    //  Feature 36 = the peak to base ratio (peak quality factor) of accelerometer peaks
    qualityFeature[FEATURE_FIXED_QUALITY_1ST_ACC_PEAK] = getPeakToTroughRatio(accPS_specPeaks[0], accPS_specMins, accPS_specPeaks,
            accPS_specVals, accPS_specMinVals, NUM_ACC_PEAKS_TO_CHOOSE) ;
    //  Feature 37 = the peak to base ratio (peak quality factor) of optical signal td peak
    if (td_peak != INVALID_TD_ESTIMATE) {
        qualityFeature[FEATURE_FIXED_QUALITY_POST_TD_PEAK] = getPeakToTroughRatio(td_peak, sigPS_post->specMins, sigPS_post->specPeaks,
                sigPS_post->specVals, sigPS_post->specMinVals, NUM_OPT_PEAKS_TO_CHOOSE) ;
    }
    else
        qualityFeature[FEATURE_FIXED_QUALITY_POST_TD_PEAK] = MIN_QUALITY;

    //  Feature 38-39 = the peak to base ratio (peak quality factor) of optical signal second peak
    //  if there is no second peak it is MIN_QUALITY
    if (sigPS_post->specPeaks[1] > 0)
        qualityFeature[FEATURE_FIXED_QUALITY_POST_2ND_PEAK] = getPeakToTroughRatio(sigPS_post->specPeaks[1], sigPS_post->specMins, sigPS_post->specPeaks,
                sigPS_post->specVals, sigPS_post->specMinVals, NUM_OPT_PEAKS_TO_CHOOSE_MAX) ;
    else
    {
        qualityFeature[FEATURE_FIXED_QUALITY_POST_2ND_PEAK] = MIN_QUALITY;
    }

    if (sigPS_post->specPeaks[2] > 0)
        qualityFeature[FEATURE_FIXED_QUALITY_POST_3RD_PEAK] = getPeakToTroughRatio(sigPS_post->specPeaks[2], sigPS_post->specMins, sigPS_post->specPeaks,
                sigPS_post->specVals, sigPS_post->specMinVals, NUM_OPT_PEAKS_TO_CHOOSE_MAX) ;
    else
    {
        qualityFeature[FEATURE_FIXED_QUALITY_POST_3RD_PEAK] = MIN_QUALITY;
    }

    //  Feature 40 = the peak to base ratio (peak quality factor) of optical signal fd peak
    qualityFeature[FEATURE_FIXED_QUALITY_POST_FD_PEAK] = getPeakToTroughRatio(fd_peak, sigPS_post->specMins,     sigPS_post->specPeaks,
            sigPS_post->specVals, sigPS_post->specMinVals, NUM_OPT_PEAKS_TO_CHOOSE_MAX) ;

    //  Feature 41 = the peak to base ratio (peak quality factor) of optical signal tracker peak
    qualityFeature[FEATURE_FIXED_QUALITY_POST_TRACKERIN] = getPeakToTroughRatio(peak, sigPS_post->specMins, sigPS_post->specPeaks,
            sigPS_post->specVals, sigPS_post->specMinVals, NUM_OPT_PEAKS_TO_CHOOSE_MAX) ;

    //  Feature 42 = the peak to base ratio (peak quality factor) of highest from motion peaks
    qualityFeature[FEATURE_FIXED_PRE_1ST_PEAK_SEP] = getPeakMotionSeparation(sigPS_pre->specPeaks[0],
            sigPSH->specPeaks, sigPSH->specVals,
            accPS_specPeaks, NUM_OPT_PEAKS_TO_CHOOSE_MAX) ;

    //  Feature 43 = the peak to base ratio (peak quality factor) of tracker peak from motion peaks
    qualityFeature[FEATURE_FIXED_POST_1ST_PEAK_TO_ACC_SEP] = getPeakMotionSeparation(peak,
            sigPSH->specPeaks, sigPSH->specVals,
            accPS_specPeaks, NUM_OPT_PEAKS_TO_CHOOSE_MAX) ;

    //  Feature 44 = the peak to base ratio (peak quality factor) of td peak from motion peaks
    if (td_peak != INVALID_TD_ESTIMATE)
    {
        qualityFeature[FEATURE_FIXED_SEP_TD_PEAK] = getPeakMotionSeparation(td_peak,
                sigPSH->specPeaks, sigPSH->specVals,
                accPS_specPeaks, NUM_OPT_PEAKS_TO_CHOOSE_MAX) ;
    } else
        qualityFeature[FEATURE_FIXED_SEP_TD_PEAK] = MIN_QUALITY;

    //  Feature 45 = the peak to base ratio (peak quality factor) of fd peak from motion peaks
    qualityFeature[FEATURE_FIXED_SEP_FD_PEAK] = getPeakMotionSeparation(fd_peak,
            sigPSH->specPeaks, sigPSH->specVals,
            accPS_specPeaks, NUM_OPT_PEAKS_TO_CHOOSE_MAX) ;

    //  Feature 46 = Amplitude difference of highest optical spectrum peak and top ambient spectrum peak
    qualityFeature[FEATURE_FIXED_TD_PEAK_AMP_SHORTHIST_VAR] =  varf(shortTdPkAmpBuffer, MAX_TD_BUFFER_LEN);
    //20 * log10_(sigPS_pre->specVals[0]) - 20 * log10_(sigAmbPS->specVals[0]);

    //  Feature 47 = Amplitude  of highest optical spectrum peak and top ambient spectrum peak
    qualityFeature[FEATURE_FIXED_TD_RR_SHORTHIST_VAR] = 100*varf(shortTdRRBuffer, MAX_TD_BUFFER_LEN);;//20 * log10_(sigAmbPS->specVals[0]);

    //  Feature 48 = The tracker's Error
    qualityFeature[FEATURE_FIXED_TRACKERIN_TRACKEROUT_DF] = abs(peak - sigTrk_freqState);

    //  Feature 49 = weight STD of all 20 peaks in the spectrum
    qualityFeature[FEATURE_FIXED_POST_20_PEAKS_WEIGHTED_VAR] = weightedStd(sigPSH->specPeaks, sigPSH->specVals, NUM_OPT_PEAKS_TO_CHOOSE_MAX) ;

    //  Feature 50 = Number of non-Zero peaks in the 23 peaks

    i = 0;
    while(sigPSH->specPeaks[i] > 0)
    {
        i++;
    }

    qualityFeature[FEATURE_FIXED_POST_NUM_20_PEAKS] = i;
    
    // All the FEATURES used for condtional features
    // The features are used for model based HR estimation
    condQualityFeature[FEATURE_CONDITIONAL_TD_MID] = median(TD_BUFFER_LEN, tdBuffer);
    condQualityFeature[FEATURE_CONDITIONAL_FD_PEAK] = fd_peak;
    condQualityFeature[FEATURE_CONDITIONAL_TRACKERIN] = peak;
    condQualityFeature[FEATURE_CONDITIONAL_TD_PEAK] = td_peak;
    condQualityFeature[FEATURE_CONDITIONAL_POST_1ST_PEAK] = sigPS_post->specPeaks[0];
    condQualityFeature[FEATURE_CONDITIONAL_1ST_ACC_PEAK] = accPS_specPeaks[0];
    condQualityFeature[FEATURE_CONDITIONAL_PRE_TOP_PEAK_AMP] = 20 * log10_(sigPS_pre->specVals[0]);
    condQualityFeature[FEATURE_CONDITIONAL_ACC_2ND_PEAK] = accPS_specPeaks[1];
    condQualityFeature[FEATURE_CONDITIONAL_1ST_ACC_PEAK_AMP] = 20 * log10_(sigPS_pre->spect_at_X);
    condQualityFeature[FEATURE_CONDITIONAL_ACC_3RD_PEAK] = accPS_specPeaks[2];
    condQualityFeature[FEATURE_CONDITIONAL_POST_2ND_PEAK_AMP] = 20 * log10_(sigPS_post->specVals[1]);
    condQualityFeature[FEATURE_CONDITIONAL_ACC_2ND_PEAK_AMP] = 20 * log10_(sigPS_pre->spect_at_X_2nd);
    condQualityFeature[FEATURE_CONDITIONAL_TRACKER] = sigTrk_freqState;
    condQualityFeature[FEATURE_CONDITIONAL_POST_2ND_PEAK] = sigPS_post->specPeaks[1];
    condQualityFeature[FEATURE_CONDITIONAL_PRE_1ST_PEAK] = sigPS_pre->specPeaks[0];
    condQualityFeature[FEATURE_CONDITIONAL_PRE_2ND_PEAK] = sigPS_pre->specPeaks[1];
    condQualityFeature[FEATURE_CONDITIONAL_PRE_3RD_PEAK] = sigPS_pre->specPeaks[2];
    condQualityFeature[FEATURE_CONDITIONAL_HPS_PEAK] = sigPSH->fft_fundamental;
    condQualityFeature[FEATURE_CONDITIONAL_FD_PEAK_PRE] = fd_peak_pre;
    condQualityFeature[FEATURE_CONDITIONAL_TRACKER_PRE] = sigTrkpre_freqState;
    condQualityFeature[FEATURE_CONDITIONAL_RAW_DATA_RANGE] = rawDataRange;
    condQualityFeature[FEATURE_CONDITIONAL_HAR_X] = accPS_harmonic;
    condQualityFeature[FEATURE_CONDITIONAL_HAR_Y] = accY_harmonic;
    condQualityFeature[FEATURE_CONDITIONAL_HAR_Z] = accZ_harmonic;
    condQualityFeature[FEATURE_CONDITIONAL_ACC_MEAN_X] = accXMeanBuff;
    condQualityFeature[FEATURE_CONDITIONAL_ACC_MEAN_Y] = accYMeanBuff;
    condQualityFeature[FEATURE_CONDITIONAL_ACC_MEAN_Z] = accZMeanBuff;
    condQualityFeature[FEATURE_CONDITIONAL_ACC_RANGE_X] = accXRangeBuff;
    condQualityFeature[FEATURE_CONDITIONAL_ACC_RANGE_Y] = accYRangeBuff;
    condQualityFeature[FEATURE_CONDITIONAL_ACC_RANGE_Z] = accZRangeBuff;
    condQualityFeature[FEATURE_CONDITIONAL_ACC_MIN_X] = accXMinBuff;
    condQualityFeature[FEATURE_CONDITIONAL_ACC_MIN_Y] = accYMinBuff;
    condQualityFeature[FEATURE_CONDITIONAL_ACC_MIN_Z] = accZMinBuff;

}

/*
 Calculate the quality of data. This is a wrapper function that first extracts the features and then calls
 the time and frequency models to calculate the quality
 :param: Receives a lot of parameters from SigprocData.c, see SigprocData.c trackstreaming.py
 for the description
 :return: HR quality consist of time quality, frequency quality and a flag to
 use time quality (if false use frq)
 Quality Control
 Extract all the features required for calculating quality metric and store them.
 */


void calculateNonFrequencyDependentQuality(float *accPS_specPeaks,
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
        float sigTrk_freqState,
        float sigTrkpre_freqState,
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
        float* condQualityFeature)
{

    // Calculate quality of the data from the features. This function finds time and frequency quality metrics.
    // update circular buffer to keep 10s of td_peak history
    tdBuffer[*tdBufferPointer] = td_peak;

    // Make a 10s and 3s circular buffer to keep all the rr intervals
    int32_t tempEnd = *tdPkAmpBufferEndPointer; //pointer to end of the amp buffer
    for (int i=0; i<numIntervalsTemp; i++)
    {
        if ((tempEnd+i) == MAX_TD_BUFFER_LEN) //if reach the end jump to start
            tempEnd = -i;
        tdPkAmpBuffer[tempEnd+i] = peaksAmplitude[i];//update 10s amp buffer
        tdPkRRBuffer[tempEnd+i] = rrIntervalsTemp[i];//update 10s rr buffer
    }

    int32_t tempStart = (*tdPkAmpBufferStartPointer);
    for (int i=0; i<tdPkNumBuffer[*tdBufferPointer]; i++) //remove values after 11s
    {
        if ((tempStart+i) == MAX_TD_BUFFER_LEN)
            tempStart = -i;
        tdPkAmpBuffer[tempStart+i] = 0; //remove values from Amp after 11s
        tdPkRRBuffer[tempStart+i] = 0;
    }
    *tdPkAmpBufferStartPointer += tdPkNumBuffer[*tdBufferPointer]; //update pointer to start of RR buffer

    tdPkNumBuffer[*tdBufferPointer] = numIntervalsTemp; //update the buffer holding number of RRs

    int tempTdBufferPointer = *tdBufferPointer;
    int shortWindowLen = 0;
    for (int i=0; i<3; i++) //calculate number of RRs in past 3s
    {
        shortWindowLen += tdPkNumBuffer[tempTdBufferPointer -i];//add all RR in past 3s
        if (tempTdBufferPointer == i)
            tempTdBufferPointer = i+TD_BUFFER_LEN;
    }

    float shortTdPkAmpBuffer[MAX_TD_BUFFER_LEN] = {0};
    float shortTdRRBuffer[MAX_TD_BUFFER_LEN] = {0};

    int tempTdPkAmpBufferEndPointer = *tdPkAmpBufferEndPointer;

    for (int i=0; i<numIntervalsTemp; i++) // make RR and Amp buffer from past 3s
    {
        shortTdPkAmpBuffer[i] = peaksAmplitude[i];
        shortTdRRBuffer[i]    = rrIntervalsTemp[i];
    }

    for (int i=0; i<shortWindowLen-numIntervalsTemp; i++) // make RR and Amp buffer from past 3s
    {
        if (tempTdPkAmpBufferEndPointer == i)
            tempTdPkAmpBufferEndPointer = i + MAX_TD_BUFFER_LEN;

        shortTdPkAmpBuffer[i+numIntervalsTemp] = tdPkAmpBuffer[tempTdPkAmpBufferEndPointer-i-1];
        shortTdRRBuffer[i+numIntervalsTemp]    = tdPkRRBuffer [tempTdPkAmpBufferEndPointer-i-1];
    }

    *tdBufferPointer += 1; //update pointer to buffer with number of point
    *tdPkAmpBufferEndPointer += numIntervalsTemp; //update pointer to end of RR buffer

    if (*tdBufferPointer >= TD_BUFFER_LEN)
        *tdBufferPointer = 0;


    if(*tdPkAmpBufferStartPointer >= MAX_TD_BUFFER_LEN)
        *tdPkAmpBufferStartPointer -= MAX_TD_BUFFER_LEN;

    if(*tdPkAmpBufferEndPointer >= MAX_TD_BUFFER_LEN)
        *tdPkAmpBufferEndPointer -= MAX_TD_BUFFER_LEN;

    extractNonFrequencyDependentFeatures(accPS_specPeaks,
                                         accPS_specMins,
                                         accPS_specVals,
                                         accPS_specMinVals,
                                         accPS_harmonic,
                                         accY_specPeaks,
                                         accY_specMins,
                                         accY_specVals,
                                         accY_specMinVals,
                                         accY_harmonic,
                                         accZ_specPeaks,
                                         accZ_specMins,
                                         accZ_specVals,
                                         accZ_specMinVals,
                                         accZ_harmonic,
                                         invalidHR_counter,
                                         td_peak,
                                         fd_peak,
                                         fd_peak_pre,
                                         sigTrk_freqState,
                                         sigTrkpre_freqState,
                                         rawDataRange,
                                         accXMeanBuff,
                                         accYMeanBuff,
                                         accZMeanBuff,
                                         accXMinBuff,
                                         accYMinBuff,
                                         accZMinBuff,
                                         accXRangeBuff,
                                         accYRangeBuff,
                                         accZRangeBuff,
                                         peak,
                                         accMax,
                                         sigPSL,
                                         sigPSR,
                                         sigPS_pre,
                                         sigPS_post,
                                         sigPSH,
                                         tdPkRRBuffer,
                                         tdPkAmpBuffer,
                                         shortTdPkAmpBuffer,
                                         shortTdRRBuffer,
                                         tdBuffer,
                                         numIntervalsTemp,
                                         qualityFeature,
                                         condQualityFeature);

    *freqQuality = calculateFromModel(qualityFeature + 1, fdModel, true);

    if (td_peak != INVALID_TD_ESTIMATE)
        *timeQuality = calculateFromModel(qualityFeature + 1, tdModel, true);
    else
        *timeQuality = 0;

    float newFeature[HR_ESTAME_CURRENT_BUFFER_LEN];
    for (int i=0; i<QUALITY_FEATURE_LEN-1; i++)
        newFeature[i] = qualityFeature[i+1];

    for (int i=0; i<COND_QUALITY_FEATURE_LEN; i++)
        newFeature[i+QUALITY_FEATURE_LEN-1] = condQualityFeature[i];

    updateNonFrequencyDependentFeaturesBuffer(newFeature,qualityFeaturesBufferIndex, qualityFeaturesBuffer);

}

/*
 This function return the features vectors by assembing the features from the past history of 10 second
 The output is used for model based HR estimate
  input: qualityFeaturesBufferIndex: the pointer to the head of the history buffer, qualityFeaturesBuffer: history buffer
        ,buffer: point to the output buffer
 the buffer length should be  HR_ESTAME_CURRENT_BUFFER_LEN * 3 or HR_ESTAME_FEATURE_BUFFER_LEN
 */
void getHrPredictorFeatures(float* buffer, int qualityFeaturesBufferIndex, QualityBuffer_t* qualityFeaturesBuffer)
{
    float* currentBuffer;
    int i;

    currentBuffer= getPreviousFeature(0, qualityFeaturesBufferIndex, qualityFeaturesBuffer);
    for (i=0; i<HR_ESTAME_CURRENT_BUFFER_LEN; i++)
        buffer[i] = currentBuffer[i];

    currentBuffer = getPreviousFeature(5, qualityFeaturesBufferIndex, qualityFeaturesBuffer);
    for (i=HR_ESTAME_CURRENT_BUFFER_LEN; i<HR_ESTAME_CURRENT_BUFFER_LEN*2; i++)
        buffer[i] = currentBuffer[i-HR_ESTAME_CURRENT_BUFFER_LEN];

    currentBuffer = getPreviousFeature(10, qualityFeaturesBufferIndex, qualityFeaturesBuffer);
    for (i=HR_ESTAME_CURRENT_BUFFER_LEN*2; i<HR_ESTAME_CURRENT_BUFFER_LEN*3; i++)
        buffer[i] = currentBuffer[i-HR_ESTAME_CURRENT_BUFFER_LEN*2];

}
