function AVT_Disconnect
% Disconnect AVT Camera
% Yuelong 2013-11

global AVT;
delete(AVT.Obj);
end