#!/usr/bin/env python
import argparse
import numpy as np
import matplotlib.pyplot as pl
import signal as sig
import scipy.signal as signal
from collections import OrderedDict
import iirFiltDesign as iir

def signal_handler(signal, frame):
    sys.exit(0)
sig.signal(sig.SIGINT, sig.SIG_DFL)

class PowerSpec:

    def __init__(self, fftLen=8192,sampleRate=100,winLen=1000,peakHi=240,peakLo=17,numHarmonics=4,
                 numPeaks=None, hrHi=600, hrLo=10, useWelch=False, use_threshold=True, dBcutoff=80,
                 dBcutoff_hps=10, label=""):

        self.label= label
        self.fftLen = fftLen
        self.sampleRate = sampleRate
        self.winLen = winLen
        self.freq = np.fft.rfftfreq(fftLen, d=1/sampleRate)
        self.w = signal.blackman(self.winLen, sym=True)

        self.peakHi = peakHi
        self.peakLo = peakLo
        self.bpmRange, self.bpmBins = self.freq2bpmRange(self.peakLo, self.peakHi)

        self.numHarmonics = numHarmonics

        self.numPeaks = numPeaks

        #Used to define plotting boundaries
        self.hrHi = hrHi
        self.hrLo = hrLo
        self.plot_bpmRange, self.plot_bpmBins = self.freq2bpmRange(self.hrLo, self.hrHi)

        self.use_threshold = use_threshold
        self.dBcutoff = dBcutoff
        self.dBcutoff_hps = dBcutoff_hps


        self.useWelch = useWelch

        self.margin = 30
        self.center = None

        self.harmonic = False
        self.fft_har_hist = []
        self.hps_har_hist = []
        self.har_hist = []


    def freq2bpmRange(self, freqLo, freqHi):

        hiBin = int((freqHi/60)*self.fftLen/100)
        loBin = int((freqLo/60)*self.fftLen/100)
        bpmBins = np.arange(loBin,hiBin)
        bpmRange = (bpmBins * self.sampleRate * 60.0 / self.fftLen)

        return bpmRange, bpmBins



    def bin2bpm(self,bin):
        return int(bin*self.sampleRate*60.0/self.fftLen)



    #@profile
    def getPowerSpec(self,x):

        self.x = np.copy(x)

        if self.useWelch:
            f, self.X = signal.welch(self.x, self.sampleRate, nperseg=1024,window='blackman')
        else:
            self.X = np.abs(np.fft.rfft(x*self.w, n=self.fftLen))

        self.specPeaks, self.specVals = self.getLocalPeaks(self.X,self.dBcutoff,self.numPeaks)

        return self.specPeaks



    def spectralSubtract(self,Y):
        self.X = np.abs(self.X - Y)
        self.specPeaks = self.getLocalPeaks(self.X, self.dBcutoff)



    def getLocalPeaks(self,x,dBcutoff,numPeaks=None,HPS=False):


        # MAX Values
        x_bpmRange = x[self.bpmBins]
        maxPeak = x_bpmRange.argmax()
        maxPeakVal = x_bpmRange[maxPeak]
        maxPeak_dB= 20*np.log10(maxPeakVal)


        #find the relative peaks in the spectrum
        peakLocations = signal.argrelmax(x)
        peakVals = x[peakLocations]

        # peakMap stores the frequency to peak magnitude correspondence
        peakMap = dict(zip(self.freq[peakLocations], peakVals))

        # There is a chance that the maxPeak itself is un-physiological
        # In that case, it will get eliminated below.
        badCandidates = set()
        for frequency, peakVal in peakMap.items():
            # IF the value does not meet our condition, note it
            if not self.isCandidate(frequency, peakVal, maxPeak_dB, dBcutoff, HPS):
                badCandidates.add(frequency)

        # Remove the bad candidates
        for frequency in badCandidates:
            peakMap.pop(frequency)

        #
        # Sort by dictionary value, frequencies sorted by their strengths
        #
        ordered = OrderedDict(sorted(peakMap.items(), key=lambda d: d[1], reverse=True))
        counter = 0

        if numPeaks == None:
            numPeaks = len(ordered)

        peaks= np.zeros((numPeaks,))
        vals = np.zeros((numPeaks,))

        for freq in ordered:
            # We want to pick the top three frequencies in each channel
            if counter >= numPeaks:
                break
            # orderedFreqsByIntensity[freq]) stores the intensity of the peak in dB
            peaks[counter] = int(60*freq)*1.0
            vals[counter] = ordered[freq]
            counter += 1

        return peaks,vals


    def isCandidate(self, freq, peakValue, maxPeakDB, dBcutoff, HPS):

        b = freq*60

        if HPS:
            peakLo = 0
            peakHi = 800

        else:
            peakLo = self.peakLo
            peakHi = self.peakHi

        if peakLo <= freq*60 <= peakHi:

            if self.use_threshold:

                peakDB = 20*np.log10(peakValue)
                if np.abs(maxPeakDB - peakDB) <= dBcutoff:
                    return True
                else:
                    return False
            else:
                return True
        else:

            return False



    def isFineCandidate(self, freq):

        if self.center == None:
            return self.isCandidate(freq)
        else:
            Lo = self.center-self.margin
            Hi = self.center+self.margin

            if Lo<self.peakLo:
                Lo = self.peakLo
                Hi = Lo + 2*self.margin

            elif Hi>self.peakHi:
                Hi = self.peakHi
                Lo = Hi - 2*self.margin

            if Lo <= freq*60 <= Hi:
                return True
            else:
                return False



    #@profiles
    def getHarmProdSpec(self):

        self.HPS = np.array(self.X)
        for i in np.arange(1,self.numHarmonics):

            temp = np.zeros((self.X.shape[0],))
            length = len(self.X[0:-1:i+1])
            temp[0:length] = self.X[0:-1:i+1]
            self.HPS *= temp

        self.hps_fftPeaks, self.hps_fftVals = self.getLocalPeaks(self.X, dBcutoff=self.dBcutoff_hps, numPeaks=self.numPeaks, HPS=True)
        self.hpsPeaks, self.hpsVals = self.getLocalPeaks(self.HPS, dBcutoff=self.dBcutoff_hps)
        # self.hpsRatio = 20*np.log10(self.hpsVals[0]/self.hpsVals[-1])

        '''
        self.hpsPeak = np.argmax(self.HPS[self.bpmBins]) + self.bpmBins[0]
        self.hpsPeak = self.bin2bpm(self.hpsPeak)

        if self.hpsPeak >= self.hrHi:
            self.hpsPeak = self.hrHi
        elif self.hpsPeak <= self.hrLo:
            self.hpsPeak = self.hrLo
        '''
        self.isHarmonic()

        return self.hpsPeaks


    def isHarmonic(self):

        self.fft_harmonic = False
        self.hps_harmonic = False
        self.harmonic=False

        self.is_FFT_Harmonic()
        self.is_HPS_Harmonic()

        if self.fft_harmonic and self.hps_harmonic:
            if np.abs(self.hps_fundamental-self.fft_fundamental)<=5:
                self.HR = self.fft_fundamental
                self.harmonic=True

        self.har_hist.append(self.harmonic)
        self.hps_har_hist.append(self.hps_harmonic)
        self.fft_har_hist.append(self.fft_harmonic)

        return self.harmonic


    def is_HPS_Harmonic(self):

        #Remove Zeros from fft_peaks and sort
        freq_peaks = [i for i in self.hps_fftPeaks if i !=0]
        sorted_freq_peaks = sorted(freq_peaks)

        #Check that there is at least one HPS peak, but no more than 2. This ensures that HPS isn't too cluttered
        if 0<len(self.hpsPeaks)<=2:

            # HPS peak is true harmonic rate if it is the tallest peak in spectrum
            if self.hpsVals[0] >= np.max(self.HPS[self.bpmBins]):

                #assume tallest peak is the fundamental
                hps_fundamental = self.hpsPeaks[0]

                #check that the HPS peak exists in sorted_freq_peaks
                if len(sorted_freq_peaks)>0:

                    #Peak may not line up perfectly, so check that residual is small enough to consider it
                    residual = np.abs(sorted_freq_peaks[0]%hps_fundamental)

                    if residual<= 4 or residual>=(hps_fundamental-4):
                        self.hps_harmonic = True
                        self.hps_fundamental = self.hpsPeaks[0]

        return self.hps_harmonic

    def is_FFT_Harmonic(self):

        #Remove Zeros from fft_peaks and sort
        freq_peaks = [i for i in self.hps_fftPeaks if i !=0]
        sorted_freq_peaks = sorted(freq_peaks)

        # If there is only one freq_peak, assume it is harmonic
        if len(sorted_freq_peaks) == 1:
            self.fft_harmonic = True
            self.fft_fundamental = sorted_freq_peaks[0]

        elif len(sorted_freq_peaks) > 1:

            #Get possible fundamental
            if len(sorted_freq_peaks) == 2:
                fundamental = np.diff(sorted_freq_peaks)

            else:
                possible_fundamentals = np.diff(sorted_freq_peaks)
                #The smallest delta in frequency peaks must be the fundamental:
                fundamental = np.min(possible_fundamentals)

            # Check that fundamental is larger that lowest acceptable threshold:
            if fundamental >= self.peakLo:

                #Peak may not line up perfectly, so check that ALL residuals are small enough to consider them harmonics
                residuals = np.abs([i%fundamental for i in sorted_freq_peaks])

                #harmonic_test gets populated with 0 if peak is harmonic or 1 is it isn't
                harmonic_test = np.ones((len(residuals)))

                for i in np.arange(len(residuals)):
                    if residuals[i] <= 4 or (fundamental-4) <= residuals[i]:
                        harmonic_test[i] = 0

                # Check that all peaks were harmonics, if so return the fun
                if np.sum(harmonic_test) == 0:
                    self.fft_harmonic=True
                    self.fft_fundamental = fundamental

        return self.fft_harmonic


    def plotdB(self, title=""):

        title = title + self.label + ' in dB'
        f1, ax1 = pl.subplots(2, sharex=True)
        f1.suptitle(title)

        ax1[0].plot(self.plot_bpmRange, 20*np.log10(self.X[self.plot_bpmBins]), 'b')
        ax1[0].set_ylabel('dB')
        ax1[1].set_xlabel('Power Spectrum')
        ax1[0].grid()

        ax1[1].plot(self.plot_bpmRange, 20*np.log10(self.HPS[self.plot_bpmBins]), 'b')
        ax1[1].set_xlabel('Harmonic Product Spectrum')
        ax1[1].set_ylabel('dB')
        ax1[1].grid()

        return f1

    def plot(self, title=""):

        title = title + self.label
        f1, ax1 = pl.subplots(2, sharex=True)
        f1.suptitle(title)

        ax1[0].plot(self.plot_bpmRange, self.X[self.plot_bpmBins], 'b')
        ax1[0].set_ylabel('Linear')
        ax1[0].set_xlabel('Power Spectrum')
        ax1[0].grid()

        ax1[1].plot(self.plot_bpmRange, self.HPS[self.plot_bpmBins], 'b')
        ax1[1].set_ylabel('Linear')
        ax1[1].set_xlabel('Harmonic Product Spectrum')
        ax1[1].grid()

        return f1

    def plotTD(self, title=""):

        title = title + self.label + ' TD Signal'

        fig = pl.figure()
        pl.title(title)
        pl.plot(self.x)
        pl.xlabel('Time (ms)')
        pl.grid()

        return fig

    def plotHarmonicHist(self, title=""):

        title = title + self.label + ' Harmonic History'
        f1, ax1 = pl.subplots(3,sharex=True)

        f1.suptitle(title)

        ax1[0].plot(self.fft_har_hist)
        ax1[0].set_ylim([-0.05,1.05])
        ax1[0].grid()
        ax1[0].set_xlabel('Time')
        ax1[0].legend(['FFT HAR'])

        ax1[1].plot(self.hps_har_hist)
        ax1[1].set_ylim([-0.05,1.05])
        ax1[1].grid()
        ax1[1].set_xlabel('Time')
        ax1[1].legend(['HPS HAR'])

        ax1[2].plot(self.har_hist)
        ax1[2].set_ylim([-0.05,1.05])
        ax1[2].grid()
        ax1[2].set_xlabel('Time')
        ax1[2].legend(['HAR'])

        return f1



if __name__ == '__main__':
    
    
    parser = argparse.ArgumentParser()
    
    #peak filter parameters
    parser.add_argument('--file',help='input file',default=None)
    parser.add_argument('--bpm',help='test signal bpm',type=int,default=60)
    parser.add_argument('--fftLen',help='specify the fft length',type=int,default=8192)
    parser.add_argument('--useWelch',help='use welch''s method to compute power spectrum',
                        default=False, action='store_true')
    args = parser.parse_args()


    ps = PowerSpec(winLen=1000, fftLen=args.fftLen, useWelch=args.useWelch, numHarmonics=3, numPeaks=3)
    f = args.bpm/60.0

    #create a fundmental frequency and the first 2 harmonics
    N = 1000
    x=np.cos(2*np.pi*np.arange(0,N)*f/100) + \
        .5*np.cos(2*np.pi*np.arange(0,N)*2*f/100) + \
        .25*np.cos(2*np.pi*np.arange(0,N)*3*f/100)


    ps.getPowerSpec(x)
    ps.getHarmProdSpec()

    print('Spec Peaks: ', ps.specPeaks)
    print('HPS Peaks : ',ps.hpsPeaks)

    ps.plotTD()
    ps.plot()
    pl.show()


