function T = temperatureConvertFromArduino2Mercury(T)

T = 1.0859 * T - 2.6676 -0.5;%mercury
% T = 1.1258 * T - 3.3623;%EtOH

end