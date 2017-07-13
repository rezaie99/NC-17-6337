function camerarestart(~,~)
global AVT;
stop(AVT.Obj);
start(AVT.Obj);
disp('camera driver was restarted for better stability');
end