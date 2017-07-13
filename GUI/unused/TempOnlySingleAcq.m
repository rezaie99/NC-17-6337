function TempOnlySingleAcq(IntObj,~)

global captime;  % variable to store time for each frame
global tmpath;      % path to save time info
global guivar;      % GUI variables
global tempPath;
global temperatureTimer;
global Temperature;
global resultsDir;
global hmsg;        % messagebox handle
if ishandle(hmsg)
    close(hmsg);
end
oneSecond=1/(24*60*60);
[~,~,~,h,m,s]=datevec(now+guivar.TimeLength*oneSecond);
hmsg = msgbox(['Donnot touch, the current recording will end at: ' ...
    num2str(h) ':' num2str(m) ':' num2str(s)],'Recording...');

stop(temperatureTimer);
CurtInd = IntObj.TasksExecuted;
OutputPath = [resultsDir,guivar.FileNm,'_t',num2str(CurtInd),'0.mj2'];
tmpath = [resultsDir,guivar.FileNm,'_time_t',num2str(CurtInd),'.mat'];
tempPath = [resultsDir,guivar.FileNm,'_temperature_t',num2str(CurtInd),'.mat'];
NumOfFrames = ceil(guivar.FrameRate*guivar.TimeLength);
captime = zeros(1,NumOfFrames+2); % time information
Temperature = zeros(1,NumOfFrames);
captime(1) = guivar.TimeLength;
% Set Timer
timerObj=timer;
timerObj.StartDelay = 0;
timerObj.Period = 1/guivar.FrameRate;
timerObj.TasksToExecute = NumOfFrames;
timerObj.ExecutionMode = 'fixedRate';
timerObj.BusyMode = 'drop';
%timerObj.StartFcn=@StartRecording;
timerObj.TimerFcn = @TempOnlyCapSingleFrame;
timerObj.StopFcn = @TempOnlyStopRecording;

captime(2)=toc;
start(timerObj);
end