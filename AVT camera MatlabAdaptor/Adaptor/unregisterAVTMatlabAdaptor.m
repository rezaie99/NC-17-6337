% ---------------------------------
% unregister AVT Adaptor for Matlab
% ---------------------------------

% version check
if verLessThan('matlab','7.7')
    f = warndlg('Please check Matlab version.', 'AVT MAtlab Adaptor Kit', 'modal');
else
    if verLessThan('matlab','7.9')
        AVTadaptor = 'AVTMatlabAdaptor_R2009a.dll'
    else
        AVTadaptor = 'AVTMatlabAdaptor_R2010a.dll'
    end
    AVTadaptor = strcat(ADAPTORPATH,AVTadaptor)
    imaqregister(AVTadaptor,'unregister')
end

% ----------------
% refresh adaptorinfo
% ----------------
imaqreset

% ----------------
% cancel matlab 
% ----------------
quit
