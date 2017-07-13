function quickStoreAnalog(s, ~)
global AnalogInput;
global analogIndex;
% s.BytesAvailable
a=fscanf(s,'%d');
analogIndex=analogIndex+1;
AnalogInput(analogIndex,:)=[a toc];
end