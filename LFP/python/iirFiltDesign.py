#!/usr/bin/env python
import argparse
import matplotlib.pyplot as pl
import numpy as np
from scipy import signal
import zplane
import signal as sig
import sys

def signal_handler(signal, frame):
    print('You pressed Ctrl+C!')
    # for p in jobs:
    #     p.terminate()
    sys.exit(0)
sig.signal(sig.SIGINT, sig.SIG_DFL)



def iirDesign( sampleRate, passBand, stopBand, passBandRipple_dB, 
               stopBandAttenuation_dB,ftype='ellip', showPlot=True):
    
    
    #normalize the filter bands to half of the sample rate
    passBand = np.float32(passBand)/(sampleRate/2)
    stopBand = np.float32(stopBand)/(sampleRate/2) 

    
    b,a=signal.iirdesign(passBand,stopBand,passBandRipple_dB,stopBandAttenuation_dB,ftype=ftype)
    w,h=signal.freqz(b,a)
    
    #return early if not plotting
    if showPlot == False:
        return b,a
    
    #plot poles and zeros
    #pl.figure()
    #zplane.zplane(b,a)
    
    fig2=pl.figure()
    pl.title('Filter Resp')
    ax1=fig2.add_subplot(111)

    #mag response
    f=(w*sampleRate)/(2*np.pi)
    pl.plot(f,20*np.log10(np.abs(h)))
    pl.ylabel('Mag in dB')
    pl.grid(True)
    
    #phase response
    ax1.twinx()
    angles = np.unwrap(np.angle(h))
    pl.plot(f, angles, 'g')
    pl.ylabel('Angle (radians)', color='g')
    pl.grid()
    pl.axis('tight')
    
    
    # Impulse response
    index = np.arange(0,1000)
    u = 1.0*(index==0)
    y = signal.lfilter(b, a, u)
    pl.figure()
    pl.stem(index,y)
    pl.title('Impulse response')
    
    return b,a
    
    

if __name__ == '__main__':
    
    

    parser = argparse.ArgumentParser()
    parser.add_argument('--file', help='data log file',default=None)
    parser.add_argument('--sampleRate', help='sample rate',default=100.0)
    parser.add_argument('--passBand', help='pass band freqency in Hz',nargs='+',default=np.float32([0.5,5]))
    parser.add_argument('--stopBand', help='stop band frequency in Hz',nargs='+',default=np.float32([0.0,20.0]))
    parser.add_argument('--passBandRipple', help='pass band ripple in dB',default=1)
    parser.add_argument('--stopBandAttenuation', help='stop band attenuation in dB',type=float,default=np.float32(20))
    parser.add_argument('--filterType', help='filter type: ellip, cheby, butter, ...etc',default='ellip')
    parser.add_argument('--show', help='show filter design plots',type=bool,default=False)
    args = parser.parse_args()
    
     
    print((args.show))
     
    
    
    b,a= iirDesign( args.sampleRate, args.passBand, args.stopBand, args.passBandRipple, 
               args.stopBandAttenuation,ftype=args.filterType)
     
    
    

    pl.show()


