function stopAcquisitionEnd(TimerObj,~)
disp('stopAcquisitionEnd was called');
global timerObj;
global cameraDriverTimer;
delete(cameraDriverTimer);
delete(timerObj);
delete(TimerObj);
end