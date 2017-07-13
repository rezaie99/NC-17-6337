function video = addThisMaskToThisFrequency (video, mask, R,G,B, frequency, fps)

minTimeDiff = (1/fps)*1000;

changePeriod = (1/(2*frequency))*1000;

colorMatrix=1-(0.*mask);
colorMatrix(:,:,1)=colorMatrix(:,:,1).*double(R);
colorMatrix(:,:,2)=colorMatrix(:,:,2).*double(G);
colorMatrix(:,:,3)=colorMatrix(:,:,3).*double(B);

if changePeriod < minTimeDiff
    disp('invalid frequency');
    return;
    elseif mod(changePeriod,minTimeDiff)<100^4
    
    timeSteps = (0:1:size(video,2)-1)*minTimeDiff;
    
    changeTimes1 = mod(timeSteps,1000/(2*frequency));%0 if need to change from 0 to 1
   
    changeTimes = changeTimes1 > 10^-4;
    
    active=0;
    
    for i = 1:1:size(video,2)
        if changeTimes(i)==0
            active=1-active;
        end
        if active==1
            video{i}=video{i}.*(1-mask)+mask.*colorMatrix;
        else
            video{i}=video{i}.*(1-mask);
        end
    end
    
else
    disp('invalid frequency');
    return;
end


end