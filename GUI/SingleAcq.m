function SingleAcq(IntObj,~)
disp('singleacqu was called');
global captime;  % variable to store time for each frame
global tmpath;      % path to save time info
global guivar;      % GUI variables
global tempPath;
global Temperature;
global resultsDir;
global isShock;
global isTemperature;
global whitelightready;
global frmNb;
global shocksArduino;
global BurstTimer;
global timerObj;
global endTimer;
global cameraDriverTimer;
global temperatureAcq;
global framesFile;
global shockstimerobj;
global paul;
global whiteLightLog;
global whitePath;
global wantedTemperatureValues;

taskNum = IntObj.TasksExecuted;

%create filenames for data
tmpath = [resultsDir,guivar.FileNm,'_time_t',num2str(taskNum),'.mat'];
tempPath = [resultsDir,guivar.FileNm,'_temperature_t',num2str(taskNum),'.mat'];
whitePath = [resultsDir,guivar.FileNm,'_whiteLight_t',num2str(taskNum),'.mat'];

currentVideoName = [guivar.FileNm, '_t', num2str(taskNum), '.bin'];
[hOffset,~,~] = getBinaryHeader([resultsDir,  currentVideoName]);
framesFile = fopen([resultsDir,  currentVideoName], 'r+');
fseek(framesFile, hOffset, -1);

captime = zeros(1,guivar.NumOfFrames+2);
captime(1) = guivar.TimeLength;
Temperature = NaN(guivar.NumOfFrames,wantedTemperatureValues);
whiteLightLog = NaN(guivar.NumOfFrames,2);

frmNb=1;
if taskNum==1
    start(cameraDriverTimer);%starts the timer that restarts the camera's driver
end
if isTemperature==1
   start(temperatureAcq);%starts the temperature acquisition timer
end
if taskNum == guivar.RepeatNm
    start(endTimer);%starts the timer that will close everything at the end of acq
end
if paul==1
   start(shockstimerobj);%starts paul's timer
end
if isShock==1
    fwrite(shocksArduino,1);%starts the shock sequence
end
if whitelightready==1
    start(BurstTimer);%starts the wight lights shock sequence
end
captime(2)=toc;%store the real starting time
start(timerObj);%starts the frame acquisition timer
end