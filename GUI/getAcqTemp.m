function getAcqTemp(~,~)
global frmNb;
global Temperature;
T = getTemperature();
try
    Temperature(frmNb,:)=T;
catch
    Temperature(frmNb,:)=0;
end
% global setTemp;
% global temperatureArduino;
% global oneTime;
% if T(1)>setTemp-1
%     if oneTime==0
%         fwrite(temperatureArduino,0);
%         fwrite(temperatureArduino,0);
%         fwrite(temperatureArduino,T);
%         oneTime=1;
%     end
% end
end