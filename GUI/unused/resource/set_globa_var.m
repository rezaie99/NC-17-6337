% Global Variables Settings
% Yuelong 2013-11
clear all;

% NARVITAR Controller
NAVITAR.Connected = true;

NAVITAR.id1 = 1; % Zooming& Focus
NAVITAR.id2 = 2; % Iris

NAVITAR.CurZoom = 0;    % Current Zooming
NAVITAR.CurFocus = 0;   % Current Focus
NAVITAR.CurIris = 0;    % Current Iris

NAVITAR.Settings.Iris = 10820;

NAVITAR.Settings.Zooming96IR = 6100;
NAVITAR.Settings.Zooming96LED = 6400;
NAVITAR.Settings.Zooming12IR = 11871;
NAVITAR.Settings.Zooming12LED = 11871;

NAVITAR.Settings.Focus96IR = 18700;
NAVITAR.Settings.Focus96LED = 19950;
NAVITAR.Settings.Focus12IR = 19700;
NAVITAR.Settings.Focus12LED = 19900;

STAGE.Connected = true;
STAGE.PORT = 'COM1';
STAGE.Terminator = {char(10),char(13)};
STAGE.Baud = 9600;
STAGE.DataBit = 8;
STAGE.StopBit = 2;
STAGE.XCenter = 0; 
STAGE.YCenter = 0;
STAGE.WellStep = 180000;
STAGE.Speed = 150000;

AVT.ADAPTOR = 'avtmatlabadaptor_r2010a';
AVT.Connected = true;
AVT.ID = 1;
AVT.Format = 'Mono8_512x512_Binning_2x2';
AVT.Exposure = 20000;
AVT.Height = 512;
AVT.Width = 512;
AVT.Gain = 4;

save('GlobalVars.mat');
