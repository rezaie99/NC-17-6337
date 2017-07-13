function sendArduinoValue(serial, value)

value = dec2bin(value, 16);

highbyte = value(1:8);
lowbyte = value(9:16);

lowbyte = bin2dec(lowbyte);
highbyte = bin2dec(highbyte);

fwrite(serial,lowbyte);
fwrite(serial,highbyte);
end