function StopAcq(TimerObj,~)
disp('function StopAcq was called');
delete(TimerObj);
end