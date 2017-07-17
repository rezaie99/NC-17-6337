#!/usr/bin/env python

__author__ = 'mostafa'


import sys
import os
import argparse
import logging
import warnings
import numpy as np
import iirFiltDesign as iir
import matplotlib.pyplot as pl
from matplotlib.mlab import PCA
from collections import OrderedDict
from notchFilterDesign import *
import time
import powerSpec as pspec



def getMinDistPeak(peaks,state):

    optDist = [np.abs(state-i) for i in peaks if i!=0]

    if len(optDist) > 0:
        minLoc = np.argmin(optDist)
        peak = peaks[minLoc]
    else:
        peak = -1

    return peak

#
# ---------------------------------------------------------
#


if __name__ == '__main__':

    startTime = time.time()

    parser = argparse.ArgumentParser()
    parser.add_argument('file', help='data log file', default=None)
    parser.add_argument('--ftype', help='file type - use for the early prototypes like mark2,mark3,etc...', default=None)
    parser.add_argument('--truthFile', help='heart strap data', default=None)
    parser.add_argument('--alphaFile', help='heart strap data from mio alpha', default=None)
    parser.add_argument('--utc', help='plot hr vs. utc time', default=None)

    #high pass filter parameters
    parser.add_argument('--hpassBand', help='high pass pass band freqency in Hz', nargs='+', default=np.float32([3.0]))
    parser.add_argument('--hstopBand', help='high pass stop band frequency in Hz', nargs='+', default=np.float32([.01]))
    parser.add_argument('--hpassBandRipple', help='high pass pass band ripple in dB', default=1)
    parser.add_argument('--hstopBandAttenuation', help='high pass stop band attenuation in dB', default=60, type=np.float32)
    parser.add_argument('--hfilterType', help='high pass filter type: ellip, cheby, butter, ...etc', default='ellip')

    #low pass filter parameters
    parser.add_argument('--lpassBand', help='low pass pass band freqency in Hz', nargs='+', default=np.float32([4.0]))
    parser.add_argument('--lstopBand', help='low pass stop band frequency in Hz', nargs='+', default=np.float32([10.0]))
    parser.add_argument('--lpassBandRipple', help='low pass pass band ripple in dB', default=1)
    parser.add_argument('--lstopBandAttenuation', help='low pass stop band attenuation in dB', default=60.0, type=np.float32)
    parser.add_argument('--lfilterType', help='low pass filter type: ellip, cheby, butter, ...etc', default='ellip')






    args = parser.parse_args()



    bh, ah = iir.iirDesign(sampleRate, args.hpassBand, args.hstopBand, args.hpassBandRipple,
                           args.hstopBandAttenuation, ftype=args.hfilterType, showPlot=args.showFilters)
    bhTD, ahTD = iir.iirDesign(sampleRate, np.float32([1.0]), args.hstopBand, args.hpassBandRipple,
                               args.hstopBandAttenuation, ftype=args.hfilterType, showPlot=args.showFilters)


    bl, al = iir.iirDesign(sampleRate, args.lpassBand, args.lstopBand, args.lpassBandRipple,
                           args.lstopBandAttenuation, ftype=args.lfilterType, showPlot=args.showFilters)

    bh_acc, ah_acc = iir.iirDesign(sampleRate,np.float32([.1]),np.float32([0.01]), args.lpassBandRipple,
                                   args.lstopBandAttenuation, ftype=args.lfilterType, showPlot=args.showFilters)
    rawData = data.opt

    sampleTime = (data.optTime - data.optTime[0])/1000
    rawData_flp = signal.lfilter(bl, al, rawData)

    rawData_f = signal.lfilter(bh, ah, rawData_flp)

    rawData_fTD = -1*signal.lfilter(bhTD, ahTD, rawData_flp)

    arr_length = len(rawData)
    fftLen = 8192
    window_size = 1000
    sampleRate = 100.0
    windowStepSize = sampleRate  # Lets keep this at 1 second so that everything lines up
    overlapFactor = window_size/windowStepSize

    number_of_windows = int((arr_length-window_size)/windowStepSize)


    sig_peaks = np.zeros((number_of_windows,numSigFreqsToPick,))
    windowTimeStamp         = np.zeros((number_of_windows,))




    peak = 40


    sigPS = pspec.PowerSpec(winLen=window_size, fftLen=fftLen, sampleRate=sampleRate, numHarmonics=numHarmonics,
                            numPeaks=numSigFreqsToPick, peakLo=40, label='sigPS')


    for k in np.arange (0,number_of_windows):

        start = k*windowStepSize
        stop = window_size + start

        if stop > len(rawData_f):
            break

        windowTimeStamp[k] = optTime[start]

        sig_peaks[k,:] = sigPS.getPowerSpec(sig_data)
        sigPS.getHarmProdSpec()

        fd_peak = getMinDistPeak(sigPS.specPeaks, peak)
        peak = fd_peak










