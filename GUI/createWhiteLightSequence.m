function varargout = createWhiteLightSequence(varargin)
% CREATEWHITELIGHTSEQUENCE MATLAB code for createWhiteLightSequence.fig
%      CREATEWHITELIGHTSEQUENCE, by itself, creates a new CREATEWHITELIGHTSEQUENCE or raises the existing
%      singleton*.
%
%      H = CREATEWHITELIGHTSEQUENCE returns the handle to a new CREATEWHITELIGHTSEQUENCE or the handle to
%      the existing singleton*.
%
%      CREATEWHITELIGHTSEQUENCE('CALLBACK',hObject,eventData,handles,...) calls the local
%      function named CALLBACK in CREATEWHITELIGHTSEQUENCE.M with the given input arguments.
%
%      CREATEWHITELIGHTSEQUENCE('Property','Value',...) creates a new CREATEWHITELIGHTSEQUENCE or raises the
%      existing singleton*.  Starting from the left, property value pairs are
%      applied to the GUI before createWhiteLightSequence_OpeningFcn gets called.  An
%      unrecognized property name or invalid value makes property application
%      stop.  All inputs are passed to createWhiteLightSequence_OpeningFcn via varargin.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES

% Edit the above text to modify the response to help createWhiteLightSequence

% Last Modified by GUIDE v2.5 11-May-2014 17:55:36

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
    'gui_Singleton',  gui_Singleton, ...
    'gui_OpeningFcn', @createWhiteLightSequence_OpeningFcn, ...
    'gui_OutputFcn',  @createWhiteLightSequence_OutputFcn, ...
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


% --- Executes just before createWhiteLightSequence is made visible.
function createWhiteLightSequence_OpeningFcn(hObject, eventdata, handles, varargin)
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   command line arguments to createWhiteLightSequence (see VARARGIN)

% Choose default command line output for createWhiteLightSequence
handles.output = hObject;

% Update handles structure
guidata(hObject, handles);

% UIWAIT makes createWhiteLightSequence wait for user response (see UIRESUME)
% uiwait(handles.figure1);


% --- Outputs from this function are returned to the command line.
function varargout = createWhiteLightSequence_OutputFcn(hObject, eventdata, handles)
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Get default command line output from handles structure
varargout{1} = handles.output;


function signal = transformProgramIntoSignal(progLine)

%time first shock
%shock duration
%nb of shock per burst
%delay between burst shocks
%delay between bursts
%nb of bursts


firstShock = progLine(:,1)*100;%unit is 10ms, 100Hz
shockDur = progLine(:,2);
nbShocks = progLine(:,3);
shockDelay = progLine(:,4)*100;
burstDelay = progLine(:,5)*100;
nbBursts = progLine(:,6);

burstSize = (shockDur + shockDelay) .* nbShocks;

trialDuration = firstShock + (burstSize + burstDelay).*nbBursts;

signal = zeros(1,trialDuration);

oneBurst = zeros(1,burstSize);

oneShock= ones(1,shockDur);

shockStart = 1;
for i=1:1:nbShocks
    oneBurst(shockStart:shockStart+shockDur-1) = oneShock;
    shockStart = shockStart + shockDur + shockDelay;
end

burstStart = firstShock;
for i=1:1:nbBursts
    signal(burstStart:burstStart+burstSize-1) = oneBurst;
    burstStart = burstStart + burstSize + burstDelay;
end
% figure
% plot(signal);
% axis([1 trialDuration -1 2]);
% xlabel('time [ms]')
% ylabel('signal')



% --- Executes on button press in CREATEFILE.
function CREATEFILE_Callback(hObject, eventdata, handles)
% hObject    handle to CREATEFILE (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

prog = get(handles.PROGRAMS,'Data');

%time first shock
%shock duration
%nb of shock per burst
%delay between burst shocks
%delay between bursts
%nb of bursts


firstShock = prog(:,1)*100;%unit is 10ms, 100Hz
shockDur = prog(:,2);
nbShocks = prog(:,3);
shockDelay = prog(:,4)*100;
burstDelay = prog(:,5)*100;
nbBursts = prog(:,6);

if firstShock == 0
    warndlg('Time of first shock has to be greater than 0');
    return;
end

trialDuration = firstShock + (((shockDur + shockDelay) .* nbShocks) + burstDelay).*nbBursts;


nbOfPrograms = 1;


dur = max(trialDuration);

stimulation = zeros(1, dur);


usedProgram = 0;
if sum(prog(1,:))>0
    signal = transformProgramIntoSignal(prog(1,:));
    stimulation(1,1:length(signal))=signal;
    usedProgram=1;
end

changes=diff(stimulation)~=0;

linear=1:1:length(stimulation)-1;

changes=linear.*changes;

changes(changes==0)=[];
a=[changes(1) diff(changes)];
interv = unique(a);

c=zeros(length(a),1);
for i=1:1:length(interv)
    b=a==interv(i);
    c(b)=i;
end

differentIntervals=interv;
whichInterval=c;
nbOfIntervals = length(c);
interval = 10;

filename = get(handles.SHOCKFILENAME,'String');

if ~isequal(filename(end-3:end),'.mat')
    filename = [filename '.mat'];
    set(handles.SHOCKFILENAME,'String',filename);
end
if ispc
    outputfile=[ 'White light sequences\' filename];
else
    outputfile=[ 'White light sequences/' filename];
end
save(outputfile, 'prog', 'dur', 'differentIntervals', 'whichInterval', 'nbOfIntervals', 'interval');






%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%Exit functions


% --- Executes on button press in QUIT.
function QUIT_Callback(hObject, eventdata, handles)
% hObject    handle to QUIT (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
close(get(hObject,'Parent'));


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% useless but mandatory functions


function DURATION_Callback(hObject, eventdata, handles)
% hObject    handle to DURATION (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of DURATION as text
%        str2double(get(hObject,'String')) returns contents of DURATION as a double



% --- Executes during object creation, after setting all properties.
function DURATION_CreateFcn(hObject, eventdata, handles)
% hObject    handle to DURATION (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


function TIMEINTERVAL_Callback(hObject, eventdata, handles)
% hObject    handle to TIMEINTERVAL (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of TIMEINTERVAL as text
%        str2double(get(hObject,'String')) returns contents of TIMEINTERVAL as a double


% --- Executes during object creation, after setting all properties.
function TIMEINTERVAL_CreateFcn(hObject, eventdata, handles)
% hObject    handle to TIMEINTERVAL (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function SHOCKFILENAME_Callback(hObject, eventdata, handles)
% hObject    handle to SHOCKFILENAME (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of SHOCKFILENAME as text
%        str2double(get(hObject,'String')) returns contents of SHOCKFILENAME as a double


% --- Executes during object creation, after setting all properties.
function SHOCKFILENAME_CreateFcn(hObject, eventdata, handles)
% hObject    handle to SHOCKFILENAME (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end
