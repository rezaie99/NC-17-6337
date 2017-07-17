
#include <stdio.h>
#include <stdint.h>
#include <Accelerate/Accelerate.h>
#include <math.h>
#include <string.h>

#include "utils.h"
#include "fft.h"
#include "sigprocData.h"

int32_t blackman( float *win, int32_t N)
{
    for (int32_t n=0; n < N; n++)
    {
        win[n] = 0.42 - (0.5 * cosf(  2 * (float)M_PI * (float)n / (N-1) ) ) + (0.08 * cosf( 4 * (float)M_PI * (float)n / (N-1)) );
    }

    return 0;
}

int32_t blackmanHarris( float *win, int32_t N)
{
    for (int32_t n=0; n < N; n++)
    {
        win[n] = 0.35875 - (0.48829 * cosf( 2 * (float)M_PI * (float)n/N) )+ (0.14128 * cosf( 4 * (float)M_PI * (float)n /N)) + (0.01168 * cosf( 6 * (float)M_PI * (float)n /N));
    }

    return 0;
}

int32_t fftClose( FFTInstance_t *fft )
{
    vDSP_destroy_fftsetup( fft->fftSetup);
    return 0;
}

int32_t fftInit( FFTInstance_t *fft, int32_t lenLog2, int32_t winLen)
{
    fft->fftSetup = vDSP_create_fftsetup(FFT_LEN_LOG2_MAX, kFFTRadix2);
    if( fft->fftSetup == NULL)
    {
        perror("Could not allocate fft struct\n");
        return -1;
    }

    blackman(fft->window, winLen);
    //blackmanHarris(fft->window, winLen);

    fft->fftLen  = 1 << lenLog2;
    fft->fftLenLog2 = lenLog2;
    fft->windowLength = winLen;

    fft->fftBuffer.imagp = fft->imag;
    fft->fftBuffer.realp = fft->real;

    if( fft->fftLen > FFT_LEN_MAX)
    {
        perror("FFT Length is to bug\n");
        return -1;
    }

    return 0;
}

int32_t fftPowerSpectrum( FFTInstance_t *fft, float *in, float *out)
{
    memset(fft->fftBuffer.imagp,0,sizeof(float)*FFT_LEN_MAX/2);
    memset(fft->fftBuffer.realp,0,sizeof(float)*FFT_LEN_MAX/2);

    //apply the window function
    for( int32_t n = 0; n < fft->windowLength; n++)
    {
        fft->temp[n] = in[n]*fft->window[n];
    }

    /*
       Split the data using vDSP_ctoz
       even-indexed elements of the real data into the real components of the
       complex data and odd-indexed elements of the real data into imaginary
       components of the complex data
       */
    vDSP_ctoz((const DSPComplex *)fft->temp, 2, &fft->fftBuffer, 1, fft->windowLength/2);

    vDSP_fft_zrip(fft->fftSetup, &fft->fftBuffer, 1, fft->fftLenLog2, FFT_FORWARD);

    int fftLen2 = fft->fftLen/2;
    for( int32_t k=0; k < fftLen2; k++)
    {
        float re = fft->fftBuffer.realp[k];
        float im = fft->fftBuffer.imagp[k];

        out[k] = sqrt( re*re + im*im);
    }

    return 0;
}

int32_t fftTest( FFTInstance_t *fft, int32_t bin)
{
    int32_t fftLenLog2 = 13;
    int32_t fftLen = 1 << fftLenLog2;
    int32_t windowLength = 1000;

    float x[windowLength];
    float y[fftLen/2];
    float hps[fftLen/2];

    printf("FFTLen %d WinLen %d\n",fftLen,windowLength);

    int32_t freq = 1;

    for( int32_t k = 0; k < windowLength; k++)
    {
        x[k] = 1.0*cos(2*M_PI*k*freq/SAMPLE_RATE)+ 0.5*cos(2*M_PI*k*freq*2/SAMPLE_RATE)+0.25*cos(2*M_PI*k*freq*3/SAMPLE_RATE);
    }

    int32_t ret = fftInit(fft,fftLenLog2, windowLength);
    if( ret < 0)
    {
        perror("Could not init fft\n");
    }

    fftPowerSpectrum(fft, x, y);

    float maxVal = 0;
    int32_t maxLoc = 0;
    for( int32_t k=0; k< fftLen/2; k++)
    {
        if(y[k] > maxVal)
        {
            maxVal = y[k];
            maxLoc = k;
        }
    }

    printf("Max %f at index %d\n",maxVal,maxLoc);

    fftClose(fft);

    HarmonicPowerSpec(y, hps);

    printf("Goodbye\n");

    return 0;
}

int32_t HarmonicPowerSpec(float* in, float* out)
{
    // Compute HPS (out) of given power spectrum (in)
    memcpy(out, in, FFT_LENGTH/2);

    int32_t i, j;
    for(i=1; i<NUMBER_OF_HARMONICS; i++){
        j=0;
        while(j*(i+1)<FFT_LENGTH/2){
            out[j] *= in[j*(i+1)];
            j++;
        }
    }

    return 0;
}
