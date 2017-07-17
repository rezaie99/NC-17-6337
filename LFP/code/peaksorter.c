
#include "peaksorter.h"
#include "sigprocDebug.h"

void initHarmonicPeaks(HarmonicPeaks_t *hp, int32_t noPeaks,int32_t min_bpm)
{
    memset(hp, 0, sizeof(HarmonicPeaks_t));
    hp->no_fft_peaks = noPeaks;
    hp->no_fft_mins  = noPeaks;
    hp->no_hps_peaks = noPeaks;

    hp->fft_peaks = (float*)malloc(sizeof(float)*noPeaks);
	memset(hp->fft_peaks,0, sizeof(float)*noPeaks);

    hp->fft_mins = (float*)malloc(sizeof(float)*noPeaks);
    memset(hp->fft_mins,0, sizeof(float)*noPeaks);

	hp->hps_peaks = (float*)malloc(sizeof(float)*noPeaks);
	memset(hp->hps_peaks, 0, sizeof(float)*noPeaks);

	hp->lowest_fundamental = min_bpm;
    hp->tolerance = 5;
    
	hp->fft_peakVals = (float*)malloc(sizeof(float)*noPeaks);
    hp->fft_min_vals = (float*)malloc(sizeof(float)*noPeaks);
	hp->hps_peakVals = (float*)malloc(sizeof(float)*noPeaks);
    for (int i=0; i<noPeaks; i++)
    {
        hp->fft_peakVals[i] = 0;
        hp->hps_peakVals[i] = 0;
        hp->fft_min_vals[i] = 0;
    }
}

void freeHarmonicPeaks(HarmonicPeaks_t *hp)
{
    free(hp->fft_peaks);
    free(hp->hps_peaks);
    free(hp->fft_mins);
    free(hp->fft_peakVals);
    free(hp->hps_peakVals);
    free(hp->fft_min_vals);
}

void sortPeaks(float *spectrum, float* bpm, float* sortedPeakVals, float* vals, float *max_peak_val, int32_t noPeaks,  int32_t dBThreshold, uint32_t low_bin, uint32_t search_len)
{
    
    //Check that search_len is within bounds:
    if (search_len>MAX_SEACH_LEN){
        printf("Search length too large. Adjust search area to continue.\n");
        return;
    }
    
    
    float *regionOfInterest = &spectrum[low_bin];
    
    utilBool indicator[search_len];
    float peakVals[search_len];
    int32_t peakLocs[search_len];
    int32_t sortIndeces[search_len];
    
    *vals = 0; 

    memset(sortedPeakVals,0,sizeof(float)*noPeaks);
    memset(peakVals,0,sizeof(float)*noPeaks);
    memset(bpm,0,sizeof(float)*noPeaks);
    memset(indicator,UTIL_FALSE,sizeof(utilBool)*search_len);
    memset(peakLocs,0,sizeof(int32_t)*search_len);
    memset(sortIndeces,0,sizeof(int32_t)*search_len);
    
    //Get MAX_dB value on regionofInterest
    *max_peak_val = GetMaxValue(regionOfInterest, search_len);
    float max_peak_dB = 20*log10(*max_peak_val);
    
    //find the local peak locations in the spectrum
    GetLocalMaxLocationsSimple(regionOfInterest, indicator, search_len, 0);
    
    //create an array with just the local peaks and their indeces
    int32_t numLocalPeaks = 0;
    
    for( int32_t i=0; i < search_len; i++)
    {
        if( indicator[i] == UTIL_TRUE)
        {
            peakVals[numLocalPeaks] = regionOfInterest[i];
            peakLocs[numLocalPeaks] = i + low_bin;
            numLocalPeaks++;
        }
    }
    

    //Sort by spectrum strength
    FindSortIndexes(peakVals, sortIndeces, numLocalPeaks);
    
    if (numLocalPeaks>noPeaks){
        numLocalPeaks = noPeaks;
    }
    

    for( int32_t i=0; i<numLocalPeaks; i++)
    {
        
        float peak_dB = 20*log10f(peakVals[sortIndeces[i]]);
		
        //Check that peak is within the given dBThreshold
        if ( (max_peak_dB - peak_dB) < dBThreshold){
            
            bpm[i] = peakLocs[sortIndeces[i]] * BPM_PER_BIN;
			sortedPeakVals[i] = peakVals[sortIndeces[i]];
            if (i==0){
                *vals = (float)(peakVals[sortIndeces[i]]);
            }
            
        }
        else{
            bpm[i] = 0;
        }
        
    }
	
#if 0
	printf("\n sortpeak: fft peaks: ");
	for(int i=0; i<noPeaks; i++) printf("%d ", bpm[i]);
	printf("\t fft peakVals: ");
	for(int i=0; i<noPeaks; i++) printf("%f ", sortedPeakVals[i]);
	printf("\n");
#endif
}


void is_FFT_Harmonic(HarmonicPeaks_t* hp){
    
    hp->fft_harmonic = UTIL_FALSE;
    hp->fft_fundamental = UTIL_FALSE;
    int size = hp->no_fft_peaks;
	
    //Create a copy of fft_peaks and sort it in ascending order and find index of first non-zero element
    //Sorting them in ascending order is necessary because the fundamental may be the distance
    //between adjacent peaks
	
	// fft_peaks at this point is sorted in descending order and is kept this way
	float peaks[size]; 	// Make the copy
	for(int i=0;i<size;i++)
        peaks[i]=hp->fft_peaks[i];

	qsort((void*)peaks, size, sizeof(float), compare_floats);
	
    
    //Get pointer to first non-zero element
    float* pIndex_fft = &peaks[0];
    int index_fft = 0;
    
    while ( *pIndex_fft == 0 ){
        
        pIndex_fft +=1;
        index_fft +=1;
        if ( index_fft >= size){
            //If all elements are zero : not harmonic:
            return;
        }
    }
    
    //If only one peak is non-zero : assume fft is harmonic:
    if(index_fft == size-1){
        hp->fft_fundamental = *pIndex_fft;
        hp->fft_harmonic = UTIL_TRUE;
        return;
    }
    
    else{
        //If there are multiple peaks; find a likely fundamental and check that other peaks are harmonics
        
        //Fundamental is likely the smallest interval of adjacent peaks or lowest frequency peak
        hp->fft_fundamental = peaks[index_fft];
        for (int32_t i=index_fft; i < (size-1); i++){
            if ( (peaks[i+1] - peaks[i]) < hp->fft_fundamental){
                hp->fft_fundamental = peaks[i+1]- peaks[i];
            }
        }
        
        //Check that fundamental is plausible
        if (hp->fft_fundamental < hp->lowest_fundamental){
            hp->fft_fundamental = UTIL_FALSE; // not plausible
            return;
        }
        
        float residual;
        int32_t harmonic_test = 0;
        //Check that other peaks are harmonics
        for(int32_t i=index_fft; i < size; i++){
            
            residual = fmod(peaks[i], hp->fft_fundamental);
            
            if ( !((residual <= hp->tolerance) || ( (hp->fft_fundamental - hp->tolerance) <= residual)) ){
                harmonic_test += 1;
            }
        }
        if(harmonic_test==0){
            hp->fft_harmonic = UTIL_TRUE;
        }else{
            hp->fft_fundamental = UTIL_FALSE;
        }
    }
    
    return;
}



void is_HPS_Harmonic(HarmonicPeaks_t *hp){
    
    hp->hps_harmonic = UTIL_FALSE;
    hp->hps_fundamental = 0;
    
	// at this point, hps_peaks are ordered by strength and padded at the end with zeros
	int noPeaks = 0;
	for(int i=0; i<hp->no_hps_peaks; i++){
		if(hp->hps_peaks[i]!=0){
			noPeaks += 1;
		}
	}
	
	if (noPeaks == 0){ // if there are no peaks, return
		return;
	}
    //Check that there is at least one HPS peak, but no more than 2. This ensures that HPS isn't too cluttered
    if (noPeaks > 2){
        return;
    }
    
    //Sometimes the HPS will look like a decaying exponential, and we may pick up a zig in lower frequency bound.
    //In this case, the HPS peak is not interesting. We exit out of the function if the peak found is not the highest
    //value of our area of interest and if it is too close to the lower frequency bound.
    if (hp->top_hps_peak_val < hp->max_hps_peak_val && hp->hps_peaks[0] <= (MIN_OPT_BPM_HPS + hp->tolerance)) {
        return;
    }
    //At this point we have one or two peaks, so we assume HPS is harmonic.
    hp->hps_harmonic = UTIL_TRUE;
    
    //Return if there's only one peak
    if (noPeaks==1) {
        hp->hps_fundamental = hp->hps_peaks[0];
        return;
    }
    
    //At this point, we have exactly two hps peaks, and we we are trying to sort out the
    //specific situation when the fundamental is the lower frequency peak with a lower amplitude
    if ( noPeaks==2 && (hp->hps_peaks[0] > hp->hps_peaks[1]) ) {
        
        //Check if higher frequency hps peak (with lower amplitude) is a multiple of the
        //lower frequency (with higher amplitude)
        float residual = fmod(hp->hps_peaks[0], hp->hps_peaks[1]);
        
        if (residual <= hp->tolerance || residual >= (hp->hps_peaks[1] - hp->tolerance)) {
            hp->hps_fundamental = hp->hps_peaks[1];
        }
        else{
            hp->hps_fundamental = hp->hps_peaks[0];
        }
        
    }
    
    //If the lower frequency peak has a higher amplitude, select it.
    else{
        hp->hps_fundamental = hp->hps_peaks[0];
    }
    
    //Check that HPS peak is within tolerance of fft_fundamental
    if (hp->fft_fundamental != 0){
        
        float fundamental, test_fundamental, residual;
        if (hp->fft_fundamental > hp->hps_fundamental){
            fundamental = hp->fft_fundamental;
            test_fundamental = hp->hps_fundamental;
        }
        else{
            fundamental = hp->hps_fundamental;
            test_fundamental = hp->fft_fundamental;
        }
        
        residual = fmod(test_fundamental, fundamental);
        if ( (residual <= hp->tolerance) || (residual >= (hp->fft_fundamental-hp->tolerance)) ){
            hp->hps_harmonic = UTIL_TRUE;
            return;
        }
        
    }
}

void getTopPeak (float *fft_peaks, float *fft_peakVals, float *comparisonPeaks, int32_t noCompPeaks,float dBDistance, int32_t bpmDistanceToAccPeaks, float* retTopPeak){
    
    //This function checks if the top optical peak is much larger than the next highest peak.
    //Also, the top peak must not exist in the accelerometer.
    //Returns 0 if conditions were not met, or the top-peak otherwise.
    
    float minDistance, bpmDistance;
    minDistance = 9999;
    *retTopPeak = 0;

    if ((20*log10f(fft_peakVals[0]) - 20*log10f(fft_peakVals[1])) >= dBDistance){
        for(int i=0; i<noCompPeaks; i++){  //get minDistance
            if(comparisonPeaks[i]!=0){
                bpmDistance = fabs(comparisonPeaks[i] - fft_peaks[0]);
                if (bpmDistance<minDistance){
                     minDistance = bpmDistance;
                }
            }
        }
        if (minDistance >= bpmDistanceToAccPeaks && minDistance != 9999){
            *retTopPeak = fft_peaks[0];
        }
     }
    return;
}


void isHarmonic(HarmonicPeaks_t* hp) {
    
    hp->harmonic = UTIL_FALSE;
  
    is_FFT_Harmonic(hp);
    is_HPS_Harmonic(hp);
    
    
    // If the signal is both fft and hps harmonic, and the fundamentals are close to each other
    // assume the signal is harmonic. Use fft_fundmanetal as general fundamental.
    // hps funamentela tends to be 3-4 bpm lower, using fft_fund is more realiable
    
    if (hp->fft_harmonic == UTIL_TRUE && hp->hps_harmonic == UTIL_TRUE){
        if (fabs(hp->fft_fundamental - hp->hps_fundamental) <= hp->tolerance){
            hp->harmonic = UTIL_TRUE;
        }
    }
    
    return;
}

void sortMins(float *spectrum, float* bpm, float* sortedPeakVals, float* vals, float *max_peak_val, int32_t noPeaks,  int32_t dBThreshold, uint32_t low_bin, uint32_t search_len){

    float max_spectrum = -1;
    float spectrum_temp [FFT_LENGTH/2];
    for (int i=0; i<(FFT_LENGTH/2);i++)
        if (spectrum[i]>max_spectrum)
            max_spectrum = spectrum[i];

    for (int i=0; i<(FFT_LENGTH/2);i++)
        spectrum_temp[i] = max_spectrum-spectrum[i];

    sortPeaks(spectrum_temp, bpm, sortedPeakVals, vals, max_peak_val,
              noPeaks,  dBThreshold,low_bin, search_len);

    for (int i=0; i<noPeaks;i++){
        if (bpm[i] !=0)
            sortedPeakVals[i] = max_spectrum - sortedPeakVals[i];
    }

    *max_peak_val = max_spectrum - *max_peak_val;
    *vals = max_spectrum - *vals;
}

// getPowerSpectData update the Spectrum data structure for optical and acclamator spectrums
// The function first find the spectrum peaks in the FFT spectrum, then it calculate the Harmonic power spectrum
//  and find the peaks in the second spectrum as well and find out if it is harmonic. At the end it calculates the
//top peak for the spectrum
// Inputs:
//    powerSpec : optical or motion power spectrum
//    accXHp    : Motion power spectrum data, it is required for optical spectrum if get_top_peak is true
//    num_of_peaks : Maximum number of peaks to search for
//    get_top_peak : if true, updates the top peak
//    acc : If it is true, spectrum is a acclamator otherwise it is a optical signal
void getPowerSpectData(PowerSpecData_t *out, float *powerSpec, HarmonicPeaks_t *accXHp, int num_of_peaks, bool get_top_peak, bool acc)
{
    if (!acc)
    {
        sortPeaks(powerSpec, out->fft_peaks, out->fft_peakVals,
              &out->top_fft_peak_val, &out->max_fft_peak_val,
              num_of_peaks, OPT_FFT_DB_CUTOFF, OPT_LOW_BIN, OPT_SEARCH_LEN);
        float harPowerSpec[LENGTH_HPS];
        HarmonicPowerSpec(powerSpec, harPowerSpec);
        sortPeaks(harPowerSpec, out->hps_peaks, out->hps_peakVals,
              &out->top_hps_peak_val, &out->max_hps_peak_val,
              num_of_peaks, OPT_HPS_DB_CUTOFF, OPT_LOW_BIN_HPS, OPT_SEARCH_LEN_HPS);
        isHarmonic(out);
        //sortMins(powerSpec, out->fft_mins, out->fft_min_vals,
        //     &out->top_fft_min_val, &out->max_fft_min_val,
        //     num_of_peaks, OPT_FFT_DB_CUTOFF, OPT_LOW_BIN, OPT_SEARCH_LEN);
        if (get_top_peak)
            getTopPeak(out->fft_peaks, out->fft_peakVals, accXHp->fft_peaks, accXHp->no_fft_peaks, dB_DISTANCE, BPM_DISTANCE_TO_ACC_PEAKS, &out->topPeak);
    }
    else
    {
        sortPeaks(powerSpec, out->fft_peaks, out->fft_peakVals,
                  &out->top_fft_peak_val, &out->max_fft_peak_val,
                  num_of_peaks, ACC_PEAK_DB_CUTOFF, ACC_LOW_BIN, ACC_SEARCH_LEN);
        float harPowerSpec[LENGTH_HPS];
        HarmonicPowerSpec(powerSpec, harPowerSpec);
        sortPeaks(harPowerSpec, out->hps_peaks, out->hps_peakVals,
                  &out->top_hps_peak_val, &out->max_hps_peak_val,
                  num_of_peaks, ACC_PEAK_DB_CUTOFF, ACC_LOW_BIN, ACC_SEARCH_LEN);
        isHarmonic(out);
        // use search range of optical signal for finding minimumns of acc spectrum
        //sortMins(powerSpec, out->fft_mins, out->fft_min_vals,
        //         &temp, &temp,
        //         num_of_peaks, ACC_PEAK_DB_CUTOFF, OPT_LOW_BIN, OPT_SEARCH_LEN);
    }
    memcpy(out->specPeaks, out->fft_peaks, num_of_peaks*sizeof(float));
    memcpy(out->specVals, out->fft_peakVals, num_of_peaks*sizeof(float));
    memcpy(out->specMins, out->fft_mins, num_of_peaks*sizeof(float));
    memcpy(out->specMinVals, out->fft_min_vals, num_of_peaks*sizeof(float));
}