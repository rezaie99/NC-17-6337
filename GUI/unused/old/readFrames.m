function varargout = readFrames(varargin)
% READFRAMES MATLAB code for readFrames.fig
%      READFRAMES, by itself, creates a new READFRAMES or raises the existing
%      singleton*.
%
%      H = READFRAMES returns the handle to a new READFRAMES or the handle to
%      the existing singleton*.
%
%      READFRAMES('CALLBACK',hObject,eventData,handles,...) calls the local
%      function named CALLBACK in READFRAMES.M with the given input arguments.
%
%      READFRAMES('Property','Value',...) creates a new READFRAMES or raises the
%      existing singleton*.  Starting from the left, property value pairs are
%      applied to the GUI before readFrames_OpeningFcn gets called.  An
%      unrecognized property name or invalid value makes property application
%      stop.  All inputs are passed to readFrames_OpeningFcn via varargin.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES

% Edit the above text to modify the response to help readFrames

% Last Modified by GUIDE v2.5 27-May-2014 13:34:49

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
    'gui_Singleton',  gui_Singleton, ...
    'gui_OpeningFcn', @readFrames_OpeningFcn, ...
    'gui_OutputFcn',  @readFrames_OutputFcn, ...
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


% --- Executes just before readFrames is made visible.
function readFrames_OpeningFcn(hObject, eventdata, handles, varargin)
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   command line arguments to readFrames (see VARARGIN)

% Choose default command line output for readFrames
handles.output = hObject;

% Update handles structure
guidata(hObject, handles);

% UIWAIT makes readFrames wait for user response (see UIRESUME)
% uiwait(handles.figure1);


% --- Outputs from this function are returned to the command line.
function varargout = readFrames_OutputFcn(hObject, eventdata, handles)
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Get default command line output from handles structure
varargout{1} = handles.output;

function updateImage(handles)
Vid = fopen([handles.PATHNAME,handles.FILENAME],'r');
fseek(Vid, (handles.currentFrame-1)*handles.frameHeight*handles.frameWidth, -1);
im=zeros(handles.frameHeight,handles.frameWidth);
for i=1:1:handles.frameHeight
    a=fread(Vid, handles.frameWidth,'uint8');
    im(i,:)=a;
end
fclose(Vid);
imshow(im);
drawnow;

% --- Executes on button press in FRAMESPATH.
function FRAMESPATH_Callback(hObject, eventdata, handles)
% hObject    handle to FRAMESPATH (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
[handles.FILENAME, handles.PATHNAME,~] = uigetfile();
handles.currentFrame=1;
updateImage(handles);
set(hObject,'String',handles.dir);
guidata(hObject, handles);

% --- Executes on button press in NEXTFRAME.
function NEXTFRAME_Callback(hObject, eventdata, handles)
% hObject    handle to NEXTFRAME (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
handles.currentFrame=handles.currentFrame+1;
updateImage(handles)
guidata(hObject, handles);


% --- Executes on button press in PREVIOUSFRAME.
function PREVIOUSFRAME_Callback(hObject, eventdata, handles)
% hObject    handle to PREVIOUSFRAME (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
handles.currentFrame=handles.currentFrame-1;
updateImage(handles)
guidata(hObject, handles);


% --- Executes on button press in PLAY.
function PLAY_Callback(hObject, eventdata, handles)
% hObject    handle to PLAY (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

handles.currentFrame=1;
while 1
    updateImage(handles)
    handles.currentFrame=handles.currentFrame+1;
end