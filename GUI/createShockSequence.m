function varargout = createShockSequence(varargin)
% CREATESHOCKSEQUENCE MATLAB code for createShockSequence.fig
%      CREATESHOCKSEQUENCE, by itself, creates a new CREATESHOCKSEQUENCE or raises the existing
%      singleton*.
%
%      H = CREATESHOCKSEQUENCE returns the handle to a new CREATESHOCKSEQUENCE or the handle to
%      the existing singleton*.
%
%      CREATESHOCKSEQUENCE('CALLBACK',hObject,eventData,handles,...) calls the local
%      function named CALLBACK in CREATESHOCKSEQUENCE.M with the given input arguments.
%
%      CREATESHOCKSEQUENCE('Property','Value',...) creates a new CREATESHOCKSEQUENCE or raises the
%      existing singleton*.  Starting from the left, property value pairs are
%      applied to the GUI before createShockSequence_OpeningFcn gets called.  An
%      unrecognized property name or invalid value makes property application
%      stop.  All inputs are passed to createShockSequence_OpeningFcn via varargin.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES

% Edit the above text to modify the response to help createShockSequence

% Last Modified by GUIDE v2.5 29-Apr-2014 11:00:31

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
    'gui_Singleton',  gui_Singleton, ...
    'gui_OpeningFcn', @createShockSequence_OpeningFcn, ...
    'gui_OutputFcn',  @createShockSequence_OutputFcn, ...
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


% --- Executes just before createShockSequence is made visible.
function createShockSequence_OpeningFcn(hObject, eventdata, handles, varargin)
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   command line arguments to createShockSequence (see VARARGIN)

% Choose default command line output for createShockSequence
handles.output = hObject;

% Update handles structure
guidata(hObject, handles);

% UIWAIT makes createShockSequence wait for user response (see UIRESUME)
% uiwait(handles.figure1);


% --- Outputs from this function are returned to the command line.
function varargout = createShockSequence_OutputFcn(hObject, eventdata, handles)
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Get default command line output from handles structure
varargout{1} = handles.output;

% --- Executes when entered data in editable cell(s) in WELLPLATE.
function WELLPLATE_CellEditCallback(hObject, eventdata, handles)
% hObject    handle to WELLPLATE (see GCBO)
% eventdata  structure with the following fields (see UITABLE)
%	Indices: row and column indices of the cell(s) edited
%	PreviousData: previous data for the cell(s) edited
%	EditData: string(s) entered by the user
%	NewData: EditData or its converted form set on the Data property. Empty if Data was not changed
%	Error: error string when failed to convert EditData to appropriate value for Data
% handles    structure with handles and user data (see GUIDATA)

data=get(hObject,'Data');

in= eventdata.Indices;

if mod(in(1),2) ==1
    data(in(1)+1,in(2))=data(in(1),in(2));
    if mod(in(2),2) ==1
        data(in(1),in(2)+1)=data(in(1),in(2));
        data(in(1)+1,in(2)+1)=data(in(1),in(2));
    else
        data(in(1),in(2)-1)=data(in(1),in(2));
        data(in(1)+1,in(2)-1)=data(in(1),in(2));
    end
else
    data(in(1)-1,in(2))=data(in(1),in(2));
    if mod(in(2),2) ==1
        data(in(1),in(2)+1)=data(in(1),in(2));
        data(in(1)-1,in(2)+1)=data(in(1),in(2));
    else
        data(in(1),in(2)-1)=data(in(1),in(2));
        data(in(1)-1,in(2)-1)=data(in(1),in(2));
    end
end



set(hObject,'Data',data);

guidata(hObject, handles);


% --- Executes on button press in CREATEFILE.
function CREATEFILE_Callback(hObject, eventdata, handles)
% hObject    handle to CREATEFILE (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

plate = get(handles.WELLPLATE,'Data');
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


nbOfPrograms = size(prog,1);


dur = max(trialDuration);

stimulation = zeros(nbOfPrograms, dur);


usedProgram = 0;
for i=1:1:nbOfPrograms
    if sum(prog(i,:))>0
        signal = transformProgramIntoSignal(prog(i,:));
        stimulation (i,1:length(signal))=signal;
        usedProgram = usedProgram + 1;
    end
end

nbOfActiveWells = sum(sum(plate>0));

rowCommands = zeros(9,dur*nbOfActiveWells/4); %we are dealing with 4 wells at the same time
colCommands = zeros(13,dur*nbOfActiveWells/4);
for i=1:2:11
    for j=1:2:7
        choice = plate(j,i);
        if choice~=0
            s = stimulation(choice,:);%the stimulation to do
            rowCable = j+1;%on this row
            colCable = i+1;%and this column
            
            
            pos = 1;
            l = length(s);
            
            previousRowDiff = diff(sum(rowCommands,1));
            previousColDiff = diff(sum(colCommands,1));
            
            previousRowDiffChanges=previousRowDiff~=0;
            previousColDiffChanges=previousColDiff~=0;
            
%             previousRowDiff = previousRowDiff(previousRowDiffChanges);
%             previousColDiff = previousColDiff(previousColDiffChanges);
            while 1
                rowCommandsTest=rowCommands;
                colCommandsTest=colCommands;
                
                rowCommandsTest(rowCable,pos:pos+l-1)=rowCommandsTest(rowCable,pos:pos+l-1)+s;
                colCommandsTest(colCable,pos:pos+l-1)=colCommandsTest(colCable,pos:pos+l-1)+s;
                %verify conflict:
                if (sum(sum(rowCommandsTest,1)>1)==0 && sum(sum(colCommandsTest,1)>1)==0) || (i==1 && j==1)%only 1 row and 1 column at a time
                    
%                     currentRowDiff = diff(sum(rowCommandsTest,1));
%                     currentColDiff = diff(sum(colCommandsTest,1));
%                     currentRowDiff = currentRowDiff(previousRowDiffChanges);
%                     currentColDiff = currentColDiff(previousColDiffChanges);
                    
                    if (sum(sum(imdilate(rowCommandsTest,[1 1]),1)>1)==0 && sum(sum(imdilate(colCommandsTest,[1 1]),1)>1)==0) || (i==1 && j==1)%(isequal(currentRowDiff, previousRowDiff) && isequal(currentColDiff, previousColDiff)) || (i==1 && j==1)
                        %the new signal did not remove a change in state of a relay
                        %this means that the relays will always turn off
                        %after a stimulation, it avoid the stimulation of a
                        %well during the for loop on the arduino, where a
                        %well can still be on for a few ms where is should
                        %not
                        break;
                    end
                end
                pos=pos+1
            end
            
            rowCommands=rowCommandsTest;
            colCommands=colCommandsTest;
        end
    end
end

temp = find(sum(rowCommands,1)>0);

try
    rowCommands(:,temp(end)+10:end)=[];
    colCommands(:,temp(end)+10:end)=[];
catch
end


x = 1:1:size(colCommands,2);
x = repmat(x,size(colCommands,1),1);
x2 =  diff(colCommands,1,2);
x2 = [zeros(size(colCommands,1),1) x2];
x3 = x2.*x;

allActivations = [];
for i=1:1:13
   currentactivations = x3(i,:);
   currentactivations(currentactivations==0)=[];
   currentactivations=[abs(currentactivations);(currentactivations*0)+i;currentactivations>0];
   allActivations=[allActivations currentactivations];
end

[~,I]= sort(allActivations(1,:));
allActivations=allActivations(:,I);

x1 = 1:1:size(rowCommands,2);
x1 = repmat(x1,size(rowCommands,1),1);
x21 =  diff(rowCommands,1,2);
x21 = [zeros(size(rowCommands,1),1) x21];
x31 = x21.*x1;
allActivations1 = [];
for i=1:1:9
   currentactivations1 = x31(i,:);
   currentactivations1(currentactivations1==0)=[];
   currentactivations1=[abs(currentactivations1);(currentactivations1*0)+i;currentactivations1>0];
   allActivations1=[allActivations1 currentactivations1];
end

[~,I1]= sort(allActivations1(1,:));
allActivations1=allActivations1(:,I1);


rowActiv = allActivations1;
colActiv = allActivations;

activations = [rowActiv(1,:);rowActiv(2,:);colActiv(2,:)];
%first row is timePoint is 10ms
%third row is the row index
%fourth row is the column index


a=activations';
a=[num2str(a(:,3)) num2str(a(:,2))];

bin = char(zeros(size(a,1),8));
nonBin = zeros(size(a,1),1);
for i=1:1:size(a,1)
    bin(i,:) = dec2bin(str2double(a(i,:)),8);
    nonBin(i)=str2double(a(i,:));
end
s=colActiv';
bin(s(:,3)==0,:)=[];
nonBin(s(:,3)==0)=[];




a=[activations(1,1);diff(activations(1,:)')];
u= unique (a);
c=zeros(length(a),1);
for i=1:1:length(u)
    b=a==u(i);
    c(b)=i;
end
d=dec2bin(c,8);

differentIntervals = u;
whichIntervalBin=d;
whichInterval=c;


filename = get(handles.SHOCKFILENAME,'String');

if ~isequal(filename(end-3:end),'.mat')
    filename = [filename '.mat'];
    set(handles.SHOCKFILENAME,'String',filename);
end

if ispc
    save(['Electrical shocks\' filename], 'dur', 'rowCommands', 'colCommands', 'rowActiv', 'colActiv',...
        'activations','bin', 'differentIntervals', 'whichInterval','nonBin','whichIntervalBin');
else
    save(['Electrical shocks/' filename], 'dur', 'rowCommands', 'colCommands', 'rowActiv', 'colActiv',...
        'activations','bin', 'differentIntervals', 'whichInterval','nonBin','whichIntervalBin');
end

% save(['Electr' filename], 'dur', 'rowCommands', 'colCommands', 'rowActiv', 'colActiv',...
%     'activations','bin', 'differentIntervals', 'whichInterval','nonBin','whichIntervalBin');



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
