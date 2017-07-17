
#ifndef __fft_h__
#define __fft_h__

#include <stdint.h>
#include <Accelerate/Accelerate.h>

#define FFT_LEN_LOG2_MAX 14
#define FFT_LEN_MAX  (1 << FFT_LEN_LOG2_MAX)

typedef struct fftInstanceTag
{
    FFTSetup fftSetup;
    DSPSplitComplex fftBuffer;
    
    int32_t fftLen;
    int32_t fftLenLog2;
    int32_t windowLength;
    
    float window[FFT_LEN_MAX];
    float temp[FFT_LEN_MAX];
    
    float real[FFT_LEN_MAX/2];
    float imag[FFT_LEN_MAX/2];
} FFTInstance_t;

int32_t fftInit(FFTInstance_t *fft, int32_t lenLog2, int32_t winLen);
int32_t fftClose(FFTInstance_t *fft);
int32_t fftPowerSpectrum(FFTInstance_t *fft, float *in, float *out);
int32_t fftTest(FFTInstance_t *fft, int32_t freqBin);

int32_t HarmonicPowerSpec(float* in, float* out);

#endif
