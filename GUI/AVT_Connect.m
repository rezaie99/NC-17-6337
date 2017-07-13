
function AVT_Connect()
% Connect AVT Camera
% Yuelong 2013-11

global AVT;
try
    if AVT.Connected
        
        
        
        
        AVT.ADAPTOR = 'gentl';
        AVT.ID = 1;
        AVT.info = imaqhwinfo(AVT.ADAPTOR,AVT.ID);
        
        AVT.Format ='Mono8';
        AVT.type =8;
        AVT.Height = 512;
        AVT.Width = 512;
        
        %    AVT.Height = 340; %bining 3
        %    AVT.Width = 341;
        
        AVT.Exposure = 2000;
        AVT.Gain = 0;
        
        
        
        
        disp('attempt to connect the camera...');
        
        delete(imaqfind);
        imaqreset;
        AVT.Obj = videoinput(AVT.ADAPTOR,AVT.ID,AVT.Format);
        AVT.settings = get(AVT.Obj);
        AVT.src = getselectedsource(AVT.Obj);
        
        set(AVT.Obj,'FramesPerTrigger',1);
        triggerconfig(AVT.Obj,'manual');
        AVT.Obj.TriggerRepeat =Inf;
        AVT.Obj.FramesPerTrigger = 1;
        
        % set(AVT.src,'Gain',AVT.Gain);
        
        set(AVT.src,'BinningHorizontal',2);
        set(AVT.src,'BinningVertical',2);
        set(AVT.src,'ExposureTimeAbs',AVT.Exposure);
        set(AVT.src,'AcquisitionFrameRateAbs',190);
        
        disp('Camera connected');
    end
catch me
    disp('I was not able to connect to the camera !');
    disp(me.identifier);
    disp(me.message);
end
end