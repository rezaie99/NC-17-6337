%%


im=int8(floor(rand(600))*255);

createBlankFile('test.bin',1024^3);

f=fopen('test.bin','w');

tic
for i=1:1:1000
    fwrite(f,im,'int8')
end
disp(['binary write => ' num2str(toc) 's'])
fclose(f);

tic
for i=1:1:1000
    save(['test' num2str(i) '.mat'],'im','-v6');
end
disp(['save -v6 => ' num2str(toc) 's'])

