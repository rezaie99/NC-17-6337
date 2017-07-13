function val = getArduinoValue(serial)
lowbyte = fread(serial,1,'uint8');
highbyte = fread(serial,1,'uint8');

lowbyte = dec2bin(lowbyte,8);
highbyte = dec2bin(highbyte,8);

val = [highbyte lowbyte];
val = bin2dec(val);
end