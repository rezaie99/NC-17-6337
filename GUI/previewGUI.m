function varargout = previewGUI(varargin)
% PREVIEWGUI MATLAB code for previewGUI.fig
%      PREVIEWGUI, by itself, creates a new PREVIEWGUI or raises the existing
%      singleton*.
%
%      H = PREVIEWGUI returns the handle to a new PREVIEWGUI or the handle to
%      the existing singleton*.
%
%      PREVIEWGUI('CALLBACK',hObject,eventData,handles,...) calls the local
%      function named CALLBACK in PREVIEWGUI.M with the given input arguments.
%
%      PREVIEWGUI('Property','Value',...) creates a new PREVIEWGUI or raises the
%      existing singleton*.  Starting from the left, property value pairs are
%      applied to the GUI before previewGUI_OpeningFcn gets called.  An
%      unrecognized property name or invalid value makes property application
%      stop.  All inputs are passed to previewGUI_OpeningFcn via varargin.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES

% Edit the above text to modify the response to help previewGUI

% Last Modified by GUIDE v2.5 11-Jul-2014 23:06:56

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1; 
gui_State = struct('gui_Name',       mfilename, ...
    'gui_Singleton',  gui_Singleton, ...
    'gui_OpeningFcn', @previewGUI_OpeningFcn, ...
    'gui_OutputFcn',  @previewGUI_OutputFcn, ...
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


% --- Executes just before previewGUI is made visible.
function previewGUI_OpeningFcn(hObject, eventdata, handles, varargin)
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   command line arguments to previewGUI (see VARARGIN)

% Choose default command line output for previewGUI
handles.output = hObject;
global AVT;
try
    stoppreview(AVT.Obj);
catch 
end
try
    stop(AVT.Obj);
catch
end
AVT.isWorking=0;
disp('Attempt to launch the preview...');
if AVT.Connected
    try
        handles.hImage = image(zeros(AVT.Height,AVT.Width),'Parent',handles.axes1);
        preview(AVT.Obj,handles.hImage);
        AVT.isWorking=1;
        disp('Preview started!');
    catch me
        disp('I was not able to launch the preview !');
        disp(me.identifier)
        disp(me.message)
        AVT.isWorking=0;
    end
else
    disp('AVT.Connnected = 0');
    AVT.isWorking=0;
end
% Update handles structure
guidata(hObject, handles);

% UIWAIT makes previewGUI wait for user response (see UIRESUME)
% uiwait(handles.figure1);


% --- Outputs from this function are returned to the command line.
function varargout = previewGUI_OutputFcn(hObject, eventdata, handles)
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Get default command line output from handles structure
varargout{1} = handles.output;


% --- Executes when user attempts to close figure1.
function figure1_CloseRequestFcn(hObject, eventdata, handles)
% hObject    handle to figure1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
global AVT;
try
    stoppreview(AVT.Obj);
catch 
end
try
    stop(AVT.Obj);
catch
end

% Hint: delete(hObject) closes the figure
delete(hObject);
