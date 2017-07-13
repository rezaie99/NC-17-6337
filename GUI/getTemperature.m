function T=getTemperature(~, ~)
global temperatureArduino;
global wantedTemperatureValues;
bytes = temperatureArduino.BytesAvailable;
bytesPerValue = 2;%6;
T=NaN(1,wantedTemperatureValues);
if bytes>= wantedTemperatureValues*bytesPerValue
    trigger=getArduinoValue(temperatureArduino); %fscanf(temperatureArduino,'%d');
    v=0;
    if trigger==4242
        for v=1:1:wantedTemperatureValues
            T(v) = getArduinoValue(temperatureArduino)/100;
            %         T(v) =fscanf(temperatureArduino,'%d')/100;
        end
        displayTemperature(T);
        %     end
        %         for v=v+1:1:bytes/bytesPerValue
        %             getArduinoValue(temperatureArduino);%fscanf(temperatureArduino,'%d');
        %         end
        % else
        %     for v=1:1:bytes/bytesPerValue
        %         getArduinoValue(temperatureArduino);%fscanf(temperatureArduino,'%d',inf)
        %     end
    end
%     T
end
