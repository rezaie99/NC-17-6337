function setNewK(Kp, Ki, Kd)
global temperatureArduino;
sendArduinoValue(temperatureArduino,150);
sendArduinoValue(temperatureArduino,Kp);
sendArduinoValue(temperatureArduino,Ki);
sendArduinoValue(temperatureArduino,Kd);
end