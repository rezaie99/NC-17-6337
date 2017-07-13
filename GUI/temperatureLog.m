function temperatureLog(obj,~)

taskNum = obj.TasksExecuted;
T = getTemperature();
global TemperatureLog;
try
    TemperatureLog(taskNum,:)=[now  T];
catch
    TemperatureLog(taskNum,:)=0;
end


end