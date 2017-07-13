function setPIDoutput(obj, ~, outputTable)
global temperatureArduino;
try
    taskNum = obj.TasksExecuted;
    currentOutputToSend = outputTable(taskNum);%this has to be tested before
    %sending 250
    %because if it fails, it means the outputTable is over,
    %the arduino must not receive the 250 value in that case!
    sendArduinoValue(temperatureArduino, 250);
    sendArduinoValue(temperatureArduino, currentOutputToSend);
    disp('Temperature set')
end
end