function varargout = BehavioralGUI(varargin)
% BEHAVIORALGUI MATLAB code for BehavioralGUI.fig
%      BEHAVIORALGUI, by itself, creates a new BEHAVIORALGUI or raises the existing
%      singleton*.
%
%      H = BEHAVIORALGUI returns the handle to a new BEHAVIORALGUI or the handle to
%      the existing singleton*.
%
%      BEHAVIORALGUI('CALLBACK',hObject,eventData,handles,...) calls the local
%      function named CALLBACK in BEHAVIORALGUI.M with the given input arguments.
%
%      BEHAVIORALGUI('Property','Value',...) creates a new BEHAVIORALGUI or raises the
%      existing singleton*.  Starting from the left, property value pairs are
%      applied to the GUI before BehavioralGUI_OpeningFcn gets called.  An
%      unrecognized property name or invalid value makes property application
%      stop.  All inputs are passed to BehavioralGUI_OpeningFcn via varargin.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES

% Edit the above text to modify the response to help BehavioralGUI

% Last Modified by GUIDE v2.5 12-Jun-2014 11:42:41

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
    'gui_Singleton',  gui_Singleton, ...
    'gui_OpeningFcn', @BehavioralGUI_OpeningFcn, ...
    'gui_OutputFcn',  @BehavioralGUI_OutputFcn, ...
    'gui_LayoutFcn',  [] , ...
    'gui_Callback',   []);
if nargin && ischar(varargin{1})
    gui_State.gui_Callback = str2func(varargin{1});
end

if nargout
    [varargout{1:nargout}] = gui_mainfcn(gui_State, varargin{:});
else
    gui_mainfcn(gui_State, varargin{:});
end
% End initialization code - DO NOT EDIT



% --- Executes just before BehavioralGUI is made visible.
function BehavioralGUI_OpeningFcn(hObject, eventdata, handles, varargin)
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   command line arguments to BehavioralGUI (see VARARGIN)

% Choose default command line output for BehavioralGUI
clc

if ispc
    addpath('..\MM');
else
    addpath('../MM');
end

global AVT;     % AVT Camera
global temperatureport;
global shockPort;

shockPort='COM5';
if ismac
    temperatureport = '/dev/tty.usbmodemfa131';
else
    temperatureport = 'COM4';
end

if ismac
    AVT.Connected = false;
else
    AVT.Connected = true;
end


%warning('off','all');

% Connect device
if AVT.Connected
    AVT_Connect;
end

% Play preview
handles.hImage = image(zeros(AVT.Height,AVT.Width),'Parent',handles.axes1);
if AVT.Connected
    try
        preview(AVT.Obj,handles.hImage);
        AVT.isWorking=1;
    catch me
        disp('I was not able to launch the preview !');
        disp(me)
        AVT.isWorking=0;
    end
end





create1stArduinoTimer(handles);



set(handles.GAININ,'String', AVT.Gain);
set(handles.EXPOSUREIN,'String', AVT.Exposure);
handles.defaultResultPath = 'D:\';
set(handles.RESULTPATH,'String',handles.defaultResultPath);

global whitelightready;
whitelightready = 0;
try
    IRon();
catch
end
handles.output = hObject;
% Update handles structure
guidata(hObject, handles);

% UIWAIT makes BehavioralGUI wait for user response (see UIRESUME)
% uiwait(handles.figure1);







function create1stArduinoTimer(handles)
global temperatureTimer;
global temperatureport;
global isArduino;
global s;% serial arduino for temperature and light control
try
    s = serial(temperatureport);
    pause(1)
    set(s,'BaudRate',115200);
    fopen(s);
    disp('First Arduino connected')
    handles.temperatureInterval = 0.5;
    temperatureTimer = timer;
    temperatureTimer.StartDelay = 0;
    temperatureTimer.Period = handles.temperatureInterval;
    temperatureTimer.ExecutionMode = 'fixedRate';
    temperatureTimer.BusyMode = 'drop';
    temperatureTimer.TimerFcn = {@getTempe, handles};
    %Start temperature measurement
    start(temperatureTimer);
    isArduino=1;
catch
    disp('no first arduino detected')
    try
        fclose(s);
        delete(s);
    catch
        
    end
    isArduino=0;
end









%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% ACQUISITION

% --- Executes on button press in Acquire.
function Acquire_Callback(hObject, eventdata, handles)

global guivar;
global AVT;
global isShock;
global resultsDir;
global videoCompression;
global videoExtension;
global isArduino;
global isPreview;
global timerObj;
global endTimer;
global temperatureTimer;
global shockTime;
global PimpshockTime;
shockTime=[];
PimpshockTime=[];

%delete all remaining timer that may still be active
deleteInvisibleTimers();
%set the priority to the highest
Priority(MaxPriority(0));

try
    start(AVT.Obj);
catch
end

IRon();
lightoff();

f=get(handles.FORMATPOPUP,'Value');
videoExtension=handles.extensions{f};
videoCompression=handles.formats{f};

resultsDir = [get(handles.RESULTPATH,'String') '\results\'];
if ~exist(resultsDir,'dir')
    mkdir(resultsDir);
end

guivar.FrameRate = str2double(get(handles.FrmRate,'string'));
guivar.TimeLength = 60*str2double(get(handles.time,'string'));
guivar.FileNm = get(handles.Filename,'string');
guivar.RepeatNm = str2double(get(handles.repeat,'string'));
guivar.BreakTime = 60*str2double(get(handles.TimInt,'string'));
guivar.NumOfFrames = ceil(guivar.FrameRate*guivar.TimeLength);

isPreview = get(handles.PREVIEWON,'Value');
isShock = get(handles.EXECUTESHOCKS,'Value');

if isPreview==0
    stoppreview(AVT.Obj);
end
if isArduino
    stop(temperatureTimer);
end

tic
for i=1:1:guivar.RepeatNm
    [~,abort]=imcreateMM([AVT.Height,AVT.Width,guivar.NumOfFrames],[resultsDir, guivar.FileNm, '_t', num2str(i), '.bin'], 'uint8');
    if abort==1
       return;
    end
end
disp(['it took ' num2str(toc) 's to create the blank files']);

%timer for each repetition
IntervalTimer = timer;
IntervalTimer.StartDelay = 0;
IntervalTimer.TasksToExecute=guivar.RepeatNm;
IntervalTimer.Period = guivar.BreakTime+guivar.TimeLength;
IntervalTimer.ExecutionMode = 'fixedRate';
IntervalTimer.BusyMode = 'queue';
IntervalTimer.StartFcn = @(~,~)tic;

% if AVT.isWorking
% Set Interval Timer
IntervalTimer.TimerFcn = @SingleAcq;
IntervalTimer.StopFcn = @StopAcq;
% else
%     IntervalTimer.TimerFcn = @TempOnlySingleAcq;
%     IntervalTimer.StopFcn = @TempOnlyStopAcq;
% end

%timer for each frame
timerObj=timer;
timerObj.StartDelay = 1;
timerObj.Period = guivar.T;
timerObj.TasksToExecute = guivar.NumOfFrames;
timerObj.ExecutionMode = 'fixedRate';
timerObj.BusyMode = 'drop';
timerObj.TimerFcn = @CapSingleFrame;
timerObj.StopFcn = @StopRecording;

%new timer that trigger at the end of last recording
endTimer=timer;
endTimer.StartDelay = guivar.TimeLength+3;
endTimer.ExecutionMode = 'singleShot';
endTimer.BusyMode = 'queue';
endTimer.TimerFcn = @acquisitionEnd;
endTimer.StopFcn = @stopAcquisitionEnd;


%create message box telling the ending time of acquisition
global hmsg;
if ishandle(hmsg)
    close(hmsg);
end
oneSecond=1/(24*60*60);
[~,~,~,h,m,s]=datevec(now + oneSecond * ...
    (guivar.TimeLength*guivar.RepeatNm+(guivar.RepeatNm-1)*guivar.BreakTime));
hmsg = msgbox(['Don''t touch, the current recordings will end at: ' ...
    num2str(h) ':' num2str(m) ':' num2str(ceil(s))],'Recording...');


global shockstimerobj;
global paul;
paul=get(handles.PAUL,'Value')==1;
if paul==1
    %tests with paul
    shockstimerobj=timer;
    shockstimerobj.StartDelay = 3;
    shockstimerobj.Period = 1;
    shockstimerobj.TasksToExecute = 1;
    shockstimerobj.ExecutionMode = 'fixedRate';
    shockstimerobj.BusyMode = 'queue';
    shockstimerobj.TimerFcn = @testPaul;
end

%start acquisition
start(IntervalTimer);

% Hint: get(hObject,'Value') returns toggle state of Acquire


% --- Executes during object creation, after setting all properties.
function FORMATPOPUP_CreateFcn(hObject, eventdata, handles)
% hObject    handle to FORMATPOPUP (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

list{1}='Archival, no compression, mj2';
list{2}='Uncompressed AVI, avi';
list{3}='Grayscale AVI, avi';

handles.extensions={'mj2','avi','avi'};
handles.formats={'Archival','Uncompressed AVI','Grayscale AVI'};

guidata(hObject, handles);


set(hObject, 'String', list);

% 'Archival' 'Motion JPEG AVI''Motion JPEG 2000''MPEG-4''Uncompressed AVI''Indexed AVI'
%             'Grayscale AVI'



% --- Executes on button press in RESULTPATH.
function RESULTPATH_Callback(hObject, eventdata, handles)
% hObject    handle to RESULTPATH (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
DIRECTORYNAME = uigetdir(handles.defaultResultPath, 'Please select where the results will be saved');
set(hObject,'String',DIRECTORYNAME);


function FrmRate_Callback(hObject, eventdata, handles)
% hObject    handle to FrmRate (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of FrmRate as text
%        str2double(get(hObject,'String')) returns contents of FrmRate as a double
f=get(hObject,'String');
f=str2double(f);
t=floor(1000/f)/1000;
f=1/t;
set(hObject,'String', num2str(f));
set(handles.MSTIMETXT,'String',num2str(t*1000));
global guivar;
guivar.T=t;
guidata(hObject, handles);



function repeat_Callback(hObject, eventdata, handles)
% hObject    handle to repeat (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of repeat as text
%        str2double(get(hObject,'String')) returns contents of repeat as a double
if str2double(get(hObject,'String'))<1
    set(hObject,'String','1');
end























%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% CAMERA FUNCTIONS

% --- Executes on button press in PREVIEWSTART.
function PREVIEWSTART_Callback(hObject, eventdata, handles)
% hObject    handle to PREVIEWSTART (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
startprev(handles);

% --- Executes on button press in CAMTROUBLESHOOT.
function CAMTROUBLESHOOT_Callback(hObject, eventdata, handles)
% hObject    handle to CAMTROUBLESHOOT (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
disp('reset');
imaqreset;
pause (10);
disp('register');
imaqregister('C:\Program Files\Allied Vision Technologies\MatlabAdaptor\Adaptor\AVTMatlabAdaptor_R2010a.dll');
pause(10);

a=imaqhwinfo();
b=imaqhwinfo(a.InstalledAdaptors{1});
c=b.DeviceInfo;
d=c.SupportedFormats;
disp('driver reset done!');
for i=1:1:size(d,2)
   d{i} 
end


% --- Executes on selection change in binningPopup.
function binningPopup_Callback(hObject, eventdata, handles)
% hObject    handle to binningPopup (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns binningPopup contents as cell array
%        contents{get(hObject,'Value')} returns selected item from binningPopup

global AVT;
% Get bingnning before change to adjust gain
formal_binning = AVT.Format;
fbinn = str2double(formal_binning(end));
binn = get(hObject,'Value');
switch binn
    case 1
        AVT.Format = handles.binning{1};
        AVT.Height = 1024;
        AVT.Width = 1024;
        AVT.Exposure =2200;
    case 2
        AVT.Format = handles.binning{2};
        AVT.Height = 512;
        AVT.Width = 512;
        AVT.Exposure =500;
    case 3
        AVT.Format = handles.binning{3};
        AVT.Height = 256;
        AVT.Width = 256;
        AVT.Exposure =125;
    case 4
        AVT.Format = handles.binning{4};
        AVT.Height = 128;
        AVT.Width = 128;
        AVT.Exposure =30;
    otherwise
        AVT.Format = handles.binning{1};
        AVT.Height = 1024;
        AVT.Width = 1024;
        AVT.Exposure =2200;
end
stoppreview(AVT.Obj);
AVT_Disconnect;
pause(1);
AVT_Connect;
handles.hImage = image(zeros(AVT.Height,AVT.Width),'Parent',handles.axes1);
preview(AVT.Obj,handles.hImage);
disp('Binning changed')



function GAININ_Callback(hObject, eventdata, handles)
% hObject    handle to GAININ (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of GAININ as text
%        str2double(get(hObject,'String')) returns contents of GAININ as a double
global AVT;
stoppreview(AVT.Obj);
a=(get(hObject,'String'));
try
    gain=str2num(a{1});
catch
    gain=str2num(a(1));
end
AVT.Gain = gain;

set(AVT.src,'Gain',AVT.Gain);

handles.hImage = image(zeros(AVT.Height,AVT.Width),'Parent',handles.axes1);
preview(AVT.Obj,handles.hImage);

disp('Gain changed')

function EXPOSUREIN_Callback(hObject, eventdata, handles)
% hObject    handle to EXPOSUREIN (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of EXPOSUREIN as text
%        str2double(get(hObject,'String')) returns contents of EXPOSUREIN as a double
global AVT;
stoppreview(AVT.Obj);
a=get(hObject,'String');
try
    exp=str2num(a{1});
catch
    exp=str2num(a(1));
end
AVT.Exposure = exp;
% AVT_Disconnect;
% pause(1);
% AVT_Connect;
set(AVT.src,'ExtendedShutter',AVT.Exposure);
handles.hImage = image(zeros(AVT.Height,AVT.Width),'Parent',handles.axes1);
preview(AVT.Obj,handles.hImage);
disp('Exposure changed')


% --- Executes during object creation, after setting all properties.
function binningPopup_CreateFcn(hObject, eventdata, handles)
% hObject    handle to binningPopup (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

handles.binning{1} = 'Mono8_1024x1024_Binning_1x1';
handles.binning{2} = 'Mono8_512x512_Binning_2x2';
handles.binning{3} = 'Mono8_256x256_Binning_4x4';
handles.binning{4} = 'Mono8_128x128_Binning_8x8';

set(hObject,'String',handles.binning);


guidata(hObject, handles);
















%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% LIGHT AND IR CONTROL

% --- Executes on button press in IRON.
function IRON_Callback(hObject, eventdata, handles)
% hObject    handle to IRON (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
IRon();

% --- Executes on button press in IROFF.
function IROFF_Callback(hObject, eventdata, handles)
% hObject    handle to IROFF (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
IRoff();

% --- Executes on button press in LIGHTON.
function LIGHTON_Callback(hObject, eventdata, handles)
% hObject    handle to LIGHTON (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
lighton();

% --- Executes on button press in LIGHTOFF.
function LIGHTOFF_Callback(hObject, eventdata, handles)
% hObject    handle to LIGHTOFF (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
lightoff();

function lightoff()
global s;
fwrite(s,20);

function IRoff()
global s;
fwrite(s,10);

function lighton()
global s;
fwrite(s,21);

function IRon()
global s;
fwrite(s,11);

% --- Executes on button press in CREATELIGHTSEQUENCE.
function CREATELIGHTSEQUENCE_Callback(hObject, eventdata, handles)
% hObject    handle to CREATELIGHTSEQUENCE (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
createWhiteLightSequence;

% --- Executes on button press in UPLOADWHITESEQUENCE.
function UPLOADWHITESEQUENCE_Callback(hObject, eventdata, handles)
% hObject    handle to UPLOADWHITESEQUENCE (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

[FILENAME, PATHNAME, ~] = uigetfile('*.mat', 'Please Select White Light Sequence File');
load([PATHNAME FILENAME]);
handles.shocksequenceduration=dur;

firstShock = prog(:,1);
shockDur = prog(:,2)/100;
nbShocks = prog(:,3);
shockDelay = prog(:,4);
burstDelay = prog(:,5);
nbBursts = prog(:,6);

global BurstTimer;
global EndShockTimer;
global ShockTimer;

BurstTimer=timer;
BurstTimer.StartDelay = firstShock;
BurstTimer.ExecutionMode = 'fixedRate';
BurstTimer.Period = nbShocks *(shockDur+shockDelay) + burstDelay;
BurstTimer.BusyMode = 'queue';
BurstTimer.TimerFcn = {@BurstTimerF};
BurstTimer.UserData=nbBursts;

ShockTimer=timer;
ShockTimer.StartDelay = 0;
ShockTimer.ExecutionMode = 'fixedRate';
ShockTimer.Period = shockDur+shockDelay;
ShockTimer.BusyMode = 'queue';
ShockTimer.TimerFcn = {@ShockTimerF};
ShockTimer.UserData=nbShocks;

EndShockTimer=timer;
EndShockTimer.StartDelay = shockDur;
EndShockTimer.ExecutionMode = 'singleShot';
EndShockTimer.BusyMode = 'queue';
EndShockTimer.TimerFcn = {@EndShockTimerF};

global whitelightready;
whitelightready = 1;

set(handles.time,'String',num2str(ceil(handles.shocksequenceduration/(100*60))+1));
set(handles.TimInt,'String',num2str(1));
set(handles.repeat,'String',num2str(1));
set(handles.time,'Enable','off');
set(handles.TimInt,'Enable','off');
set(handles.repeat,'Enable','off');


guidata(hObject, handles);


% global shockingArduinoInit;
% try
%     stop(shockingArduinoInit);
% catch
% end
% shockingArduinoInit=timer;
% shockingArduinoInit.StartDelay = 0;
% shockingArduinoInit.ExecutionMode = 'singleShot';
% shockingArduinoInit.BusyMode = 'queue';
% shockingArduinoInit.TimerFcn = {@transmitStimulationSequence, nonBin, differentIntervals, whichInterval, 10, handles};
% set(handles.SCHOCKSUPLOADED,'Value',0);
% set(handles.EXECUTESHOCKS,'Enable','off');
% start(shockingArduinoInit);
% guidata(hObject, handles);
%












%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% SHOCKS CONTROL

% --- Executes on button press in EXECUTESHOCKS.
function EXECUTESHOCKS_Callback(hObject, eventdata, handles)
% hObject    handle to EXECUTESHOCKS (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of EXECUTESHOCKS

if get(hObject,'Value')==1
    
    set(handles.time,'String',num2str(ceil(handles.shocksequenceduration/(100*60))+1));
    set(handles.TimInt,'String',num2str(1));
    set(handles.repeat,'String',num2str(1));
    set(handles.time,'Enable','off');
    set(handles.TimInt,'Enable','off');
    set(handles.repeat,'Enable','off');
else
    set(handles.time,'Enable','on');
    set(handles.TimInt,'Enable','on');
    set(handles.repeat,'Enable','on');
end



% --- Executes on button press in UPLOADSHOCKS.
function UPLOADSHOCKS_Callback(hObject, eventdata, handles)
% hObject    handle to UPLOADSHOCKS (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
[FILENAME, PATHNAME, ~] = uigetfile('*.mat', 'Please Select Shock File');
load([PATHNAME FILENAME]);
handles.shocksequenceduration=dur;
global shockingArduinoInit;
try
    stop(shockingArduinoInit);
catch
end
shockingArduinoInit=timer;
shockingArduinoInit.StartDelay = 0;
shockingArduinoInit.ExecutionMode = 'singleShot';
shockingArduinoInit.BusyMode = 'queue';
shockingArduinoInit.TimerFcn = {@transmitStimulationSequence, nonBin, differentIntervals, whichInterval, 10, handles};
set(handles.SCHOCKSUPLOADED,'Value',0);
set(handles.EXECUTESHOCKS,'Enable','off');
start(shockingArduinoInit);
guidata(hObject, handles);


% --- Executes on button press in SHOCKTEST.
function SHOCKTEST_Callback(hObject, eventdata, handles)
% hObject    handle to SHOCKTEST (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
load('shockTest.mat');
global shockingArduinoInit;
try
    stop(shockingArduinoInit);
catch
end
shockingArduinoInit=timer;
shockingArduinoInit.StartDelay = 0;
shockingArduinoInit.ExecutionMode = 'singleShot';
shockingArduinoInit.BusyMode = 'queue';
shockingArduinoInit.TimerFcn = {@transmitStimulationSequence, nonBin, differentIntervals, whichInterval, 10, handles};
set(handles.SCHOCKSUPLOADED,'Value',0);
start(shockingArduinoInit);
while get(handles.SCHOCKSUPLOADED,'Value')==0
end



global s2;
pause(0.5);
fwrite(s2,1);%starts the sequence
pause(0.5);
%fscanf(s2,'%d')
i=1;
data=zeros(1,100000);
while true
    if s2.BytesAvailable>0
        ss=fscanf(s2,'%d')
        if ss==-42
            break;
        else
            data(i)=ss;
            i=i+1;
        end
    end
end
data(i:end)=[];

R = 250;

V=6;

U = data.*5./1023;

I = U./R;

Rw = (V-U)./I;
save('shockTestResults.mat');
fclose(s2)
delete(s2)
clear s2

figure
for i=1:1:9
    plot((i-1)*13+1:(i*13),Rw((i-1)*13+1:(i*13)))
    hold all
end
legend('row 1','row 2','row 3','row 4','row 5','row 6','row 7','row 8','row 9')
for i=1:1:9
    plot((i-1)*13+1:(i*13),Rw((i-1)*13+1:(i*13)),'o')
    hold all
end
% whichData=1;
% currents = zeros(size(rowCommands,2),1);
% timePoints = zeros(size(rowCommands,2),1);
% wellResistance = zeros(size(rowCommands,2),1);
% if whichData
%             V = fscanf(s2,'%d');
%             R=250;
%             Vin = 6;
%             currents(i) = V*5*1000/(1023*R);%current in mA
%             wellResistance(i) = (Vin-V)/currents(i);
%         else
%             timePoints(i)=fscanf(s2,'%d');
%             i=i+1;
%         end
%         whichData=1-whichData;
%     end
%     if i>size(rowCommands,2)
%         break;



% --- Executes on button press in MANUALMODEON.
function MANUALMODEON_Callback(hObject, eventdata, handles)
% hObject    handle to MANUALMODEON (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

if ispc
    winopen('..\Arduino Program\shockControlfor1channel\shockControlfor1channel.ino');
else
    macopen('../Arduino Program/shockControlfor1channel/shockControlfor1channel.ino');
end

hmsg=msgbox('Close this message when you have flashed the Arduino');

while ishandle(hmsg)
    pause(1);
end

global shockPort;
global s2;

try
    if ismac
        s2 = serial('/dev/tty.usbmodemfa133');
    else
        s2 = serial(shockPort);
    end
    pause(1)
    set(s2,'BaudRate',115200);
    fopen(s2);
    pause(1)
    disp('Second Arduino connected')
catch
    disp('no second arduino detected')
    try
        fclose(s2);
        delete(s2);
    catch
        
    end
end

set(handles.SCHOCKSUPLOADED,'Value',1);
%set(handles.EXECUTESHOCKS,'Enable','on');


% --- Executes on button press in MANUALSHOCKTRIGGER.
function MANUALSHOCKTRIGGER_Callback(hObject, eventdata, handles)
% hObject    handle to MANUALSHOCKTRIGGER (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

global s2;
global captime;
global shockTime;
[x,y]=max(captime(3:end));
shockTime = [shockTime y];
fwrite(s2,1);



% --- Executes on button press in PIMPTRIGGER.
function PIMPTRIGGER_Callback(hObject, eventdata, handles)
% hObject    handle to PIMPTRIGGER (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

global s2;
global captime;
global PimpshockTime;

[x,y]=max(captime(3:end));
PimpshockTime = [PimpshockTime y];

lighton

pause(0.1)

lightoff

pause(1)

fwrite(s2,1);
































%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% DEBUG

% --- Executes on button press in DEBUG.
function DEBUG_Callback(hObject, eventdata, handles)
% hObject    handle to DEBUG (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
clc
global AVT
try
    stoppreview(AVT.Obj);
catch
end
try
    stop(AVT.Obj);
catch
end

for i=[1 5 7]
    
    OutputPath = ['D:\',num2str(i)];
    switch i
        case 1
            comp='Archival';
            Vid = VideoWriter(OutputPath, comp);
        case 2
            Vid = VideoWriter(OutputPath, 'Motion JPEG AVI');
        case 3
            Vid = VideoWriter(OutputPath, 'Motion JPEG 2000');
        case 4
            Vid = VideoWriter(OutputPath, 'MPEG-4');
        case 5
            Vid = VideoWriter(OutputPath, 'Uncompressed AVI');
        case 6
            Vid = VideoWriter(OutputPath, 'Indexed AVI');
            set(Vid, 'Colormap',gray)
        case 7
            Vid = VideoWriter(OutputPath, 'Grayscale AVI');
    end
    Vid.FrameRate = 40;
    start(AVT.Obj);
    open(Vid);
    a=0;
    b=0;
    for j=1:1:1000
        tic
        Frm = getsnapshot(AVT.Obj);
        a=a+toc;
        tic
        writeVideo(Vid,Frm);
        b=b+toc;
    end
    a
    b
    c=a+b
    close(Vid);
    clear Vid
    clear Frm
    clear OutputPath
    stop(AVT.Obj);
    
end






function deleteInvisibleTimers()

alltimers=timerfindall('ObjectVisibility','off')
% alltimers=timerfindall()
try
    delete(alltimers);
catch
end


% --- Executes on button press in TIMERDELETE.
function TIMERDELETE_Callback(hObject, eventdata, handles)
% hObject    handle to TIMERDELETE (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
deleteInvisibleTimers();



function deleteInvisibleSerial()

allSerial=instrfindall('ObjectVisibility','off')
% allSerial=instrfindall()
try
    delete(allSerial);
catch
end

% --- Executes on button press in SERIALCLOSE.
function SERIALCLOSE_Callback(hObject, eventdata, handles)
% hObject    handle to SERIALCLOSE (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
deleteInvisibleSerial();


























%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% PROJECTOR STIMULATION

% --- Executes on button press in getPlatePosition.
function getPlatePosition_Callback(hObject, eventdata, handles)
% hObject    handle to getPlatePosition (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

Screen('CloseAll');

disp('getPlanePosition was called')

[handles.screenInfo, handles.X, handles.Y] =get96Info();
if ~isempty(handles.screenInfo)
    handles.norm = norm([handles.X(1)-handles.X(2);handles.Y(1)-handles.Y(2)]);
    handles.angle = -rad2deg(atan((handles.Y(2)-handles.Y(1))/(handles.X(2)-handles.X(1))));
    %angle1 = -rad2deg(atan2(Y(2)-Y(1),X(2)-X(1)));
    
    set(handles.screenWidth,'String', num2str(handles.screenInfo(3)));
    set(handles.screenHeight,'String', num2str(handles.screenInfo(4)));
    set(handles.plateAngle,'String', num2str(handles.angle));
    
end
Screen('CloseAll');

guidata(hObject, handles);



% --- Executes on button press in getMasks.
function getMasks_Callback(hObject, eventdata, handles)
% hObject    handle to getMasks (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

[handles.mask, handles.allMasks, handles.columnMasks, handles.lineMasks, handles.leftUpCorner] = getMasks(handles.angle, handles.norm);
guidata(hObject, handles);



% --- Executes on button press in getVideo.
function getVideo_Callback(hObject, eventdata, handles)
% hObject    handle to getVideo (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

outputVideoName = 'stimulationVideo';

writerObj = VideoWriter(outputVideoName);

videoLength = 1; %seconds

frameRate = 30;%frames per seconds

possibleFrequencies = find(mod(frameRate/2,1:1:frameRate/2)==0)

nbOfFrames = frameRate * videoLength;

width = size(handles.columnMasks{4},2);
height = size(handles.columnMasks{4},1);

im = zeros(height, width, 3);

for i=1:1:nbOfFrames
    videoFrames{i} = im;
end
%
% for i=1:1:length(possibleFrequencies)
%     switch mod(i,3)
%         case 0
%             videoFrames = addThisMaskToThisFrequency (videoFrames, handles.columnMasks{i}, red, possibleFrequencies(i), frameRate);
%         case 1
%             videoFrames = addThisMaskToThisFrequency (videoFrames, handles.columnMasks{i}, green, possibleFrequencies(i), frameRate);
%         case 2
%             videoFrames = addThisMaskToThisFrequency (videoFrames, handles.columnMasks{i}, blue, possibleFrequencies(i), frameRate);
%     end
% end


nbOfLines=10000;
formatIn = '%f %f %f %f %f %f';

[FILENAME, PATHNAME, FILTERINDEX] = uigetfile('.csv');

file_id = fopen([PATHNAME FILENAME]);
if ~feof(file_id)
    textscan(file_id, '%s %s %s %s %s %s', 1,'Delimiter',',');
end
while ~feof(file_id)
    segarray = textscan(file_id, formatIn, nbOfLines,'Delimiter',';');
end
fclose(file_id);

for i=1:1:size(segarray{1},1)
    disp([num2str(i) '/' num2str(size(segarray{1},1)) ' wells processed'])
    col=double(segarray{1}(i));
    row=double(segarray{2}(i));
    r=double(segarray{3}(i));
    g=double(segarray{4}(i));
    b=double(segarray{5}(i));
    f=double(segarray{6}(i));
    videoFrames = addThisMaskToThisFrequency (videoFrames, handles.allMasks{row}{col}, r,g,b, f, frameRate);
end

open(writerObj);

if handles.X(1)<handles.X(2)
    m=1;
else
    m=2;
end

left=floor(handles.X(m)-handles.leftUpCorner(1));
right= floor(left+width-1);

high =floor(handles.Y(m)-handles.leftUpCorner(2));
low=floor(high+height-1);

nbOfMinutes = str2double(get(handles.VIDEOLENGTH,'String'));

for j=0:1:nbOfMinutes-1
    for i=1:1:nbOfFrames
        disp([num2str(i+(j*nbOfFrames)) '/' num2str(nbOfMinutes*nbOfFrames) ' Frames added to the video'])
        if j==0
            currentZerosFilledFramw = zeros(handles.screenInfo(4),handles.screenInfo(3),3);
            currentZerosFilledFramw(high:low,left:right,:)=videoFrames{i};
            oneMinute{i}=currentZerosFilledFramw;
        end
        writeVideo(writerObj,oneMinute{i});
    end
end
close(writerObj);

guidata(hObject, handles);












%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% some gadget functions


function WANTEDTEMP_Callback(hObject, eventdata, handles)
% hObject    handle to WANTEDTEMP (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of WANTEDTEMP as text
%        str2double(get(hObject,'String')) returns contents of WANTEDTEMP as a double

T = str2double(get(hObject,'String'));
% T = temperatureConvertMercury2PID(T);
set(handles.TEMPTOSET,'String',num2str(T));


% --- Executes on button press in CLOSEALLFIG.
function CLOSEALLFIG_Callback(hObject, eventdata, handles)
% hObject    handle to CLOSEALLFIG (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
for i=1:1:1000
    try
        close(i);
    catch
    end
end

% --- Executes on button press in QUITnTRACK.
function QUITnTRACK_Callback(hObject, eventdata, handles)
% hObject    handle to QUITnTRACK (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
close(get(hObject,'Parent'));
cd ..
cd ..
cd tracking av
trackingGUI


% --- Executes on button press in VIDEOCONVERT.
function VIDEOCONVERT_Callback(hObject, eventdata, handles)
% hObject    handle to VIDEOCONVERT (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
close(get(get(hObject,'Parent'),'Parent'));
BINMM2vid

% --- Executes on button press in TRACKING.
function TRACKING_Callback(hObject, eventdata, handles)
% hObject    handle to TRACKING (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
close(get(hObject,'Parent'));
cd ..
cd ..
cd tracking av
trackingGUI

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% CLOSING FUNCTIONS

% --- Executes on button press in QUIT.
function QUIT_Callback(hObject, eventdata, handles)
% hObject    handle to QUIT (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
close(get(hObject,'Parent'));


% --- Executes when user attempts to close figure1.
function figure1_CloseRequestFcn(hObject, eventdata, handles)
% hObject    handle to figure1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: delete(hObject) closes the figure
try
    global temperatureTimer;
    stop(temperatureTimer);
    delete(temperatureTimer);
catch
    disp('temperatureTimer deletion was catched')
end

try
    global shockingArduinoInit;
    stop(shockingArduinoInit);
    delete(shockingArduinoInit);
catch
    disp('shockingArduinoInit deletion was catched')
end

try
    global s;
    fclose(s);
    delete(s);
catch
    disp('s deletion was catched')
end

try
    AVT_Disconnect;
catch
    disp('AVT_Disconnect was catched')
end

delete(hObject);


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% USELESS BUT MANDATORY FUNCTIONS




% --- Outputs from this function are returned to the command line.
function varargout = BehavioralGUI_OutputFcn(hObject, eventdata, handles)
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Get default command line output from handles structure
varargout{1} = handles.output;




% --- Executes during object creation, after setting all properties.
function FrmRate_CreateFcn(hObject, eventdata, handles)
% hObject    handle to FrmRate (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function time_Callback(hObject, eventdata, handles)
% hObject    handle to time (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of time as text
%        str2double(get(hObject,'String')) returns contents of time as a double


% --- Executes during object creation, after setting all properties.
function time_CreateFcn(hObject, eventdata, handles)
% hObject    handle to time (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes during object creation, after setting all properties.
function Filename_CreateFcn(hObject, eventdata, handles)
% hObject    handle to Filename (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


function Filename_Callback(hObject, eventdata, handles)
% hObject    handle to Filename (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of Filename as text
%        str2double(get(hObject,'String')) returns contents of Filename as a double


function TimInt_Callback(hObject, eventdata, handles)
% hObject    handle to TimInt (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of TimInt as text
%        str2double(get(hObject,'String')) returns contents of TimInt as a double


% --- Executes during object creation, after setting all properties.
function TimInt_CreateFcn(hObject, eventdata, handles)
% hObject    handle to TimInt (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end




% --- Executes during object creation, after setting all properties.
function repeat_CreateFcn(hObject, eventdata, handles)
% hObject    handle to repeat (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function VIDEOLENGTH_Callback(hObject, eventdata, handles)
% hObject    handle to VIDEOLENGTH (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of VIDEOLENGTH as text
%        str2double(get(hObject,'String')) returns contents of VIDEOLENGTH as a double


% --- Executes during object creation, after setting all properties.
function VIDEOLENGTH_CreateFcn(hObject, eventdata, handles)
% hObject    handle to VIDEOLENGTH (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes during object creation, after setting all properties.
function GAININ_CreateFcn(hObject, eventdata, handles)
% hObject    handle to GAININ (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end




% --- Executes during object creation, after setting all properties.
function EXPOSUREIN_CreateFcn(hObject, eventdata, handles)
% hObject    handle to EXPOSUREIN (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in RECORDTEMP.
function RECORDTEMP_Callback(hObject, eventdata, handles)
% hObject    handle to RECORDTEMP (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of RECORDTEMP


% --- Executes on button press in PREVIEWON.
function PREVIEWON_Callback(hObject, eventdata, handles)
% hObject    handle to PREVIEWON (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of PREVIEWON


% --- Executes on button press in SCHOCKSUPLOADED.
function SCHOCKSUPLOADED_Callback(hObject, eventdata, handles)
% hObject    handle to SCHOCKSUPLOADED (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of SCHOCKSUPLOADED


% --- Executes on selection change in FORMATPOPUP.
function FORMATPOPUP_Callback(hObject, eventdata, handles)
% hObject    handle to FORMATPOPUP (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns FORMATPOPUP contents as cell array
%        contents{get(hObject,'Value')} returns selected item from FORMATPOPUP


% --- Executes on button press in PAUL.
function PAUL_Callback(hObject, eventdata, handles)
% hObject    handle to PAUL (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of PAUL



% --- Executes during object creation, after setting all properties.
function WANTEDTEMP_CreateFcn(hObject, eventdata, handles)
% hObject    handle to WANTEDTEMP (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end
