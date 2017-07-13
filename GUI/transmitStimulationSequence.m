function transmitStimulationSequence(~, ~, bin, differentIntervals, whichInterval, msDelay, handles)
%table is the [rowSignal;columnSignal] signal for the 96 well plate
%msDelay is the delay, in milliseconds, between each time point
tic
global shocksArduino;
try
    fclose(shocksArduino)
    delete(shocksArduino)
    clear shocksArduino
catch
end

createArduinoCode(bin, differentIntervals, whichInterval, msDelay);

hmsg = msgbox('Close this message when you have flashed the Arduino');

while ishandle(hmsg)
    pause(0.3);
end

global shockPort;


try
    if ismac
        shocksArduino = serial('/dev/tty.usbmodemfa133');
    else
        shocksArduino = serial(shockPort);
    end
    pause(.5)
    shocksArduino.BaudRate=115200;
    shocksArduino.BytesAvailableFcn = @quickStoreAnalog;
    %     set(shocksArduino, 'Timeout', 0.01);
    fopen(shocksArduino);
    disp('Shock Arduino connected')
catch
    disp('no Shock arduino detected')
    try
        fclose(shocksArduino);
        delete(shocksArduino);
    catch
        
    end
end

%disp(['It took ' num2str(toc) 's to upload the shock sequence on the arduino'])

set(handles.SCHOCKSUPLOADED,'Value',1);
set(handles.EXECUTESHOCKS,'Enable','on');
end

