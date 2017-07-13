function TempOnlyCapSingleFrame(TimerObj,~)
% Capture a single frame, work as TimerFcn for timer object
% Yuelong 2013-11

global captime;
global Temperature;
global temptext;
%trigger(AVT.Obj);
captime(TimerObj.TasksExecuted+2) = toc;

if toc-captime(3)>captime(1)
    stop(TimerObj);
end

T=quickGetTemp();
if ~isempty(T)
    Temperature(TimerObj.TasksExecuted)=T;
    set(temptext, 'String', num2str(T));
end
end