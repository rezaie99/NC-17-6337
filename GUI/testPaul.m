function testPaul(~,~)
global shocksArduino;
global captime;
global shockTime;
[x,y]=max(captime(3:end));
shockTime = [shockTime y];
fwrite(shocksArduino,1);
end