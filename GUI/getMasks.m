function [mask, allMasks, columnMasks, lineMasks, leftUpCorner] = getMasks(angle, n)

mask96 = load('mask96.mat');

mask96=double(mask96.mask96);

mask96=mask96(:,:,1);

%make it RGB
width= size(mask96,2);

scale = n/width;

mask96=imresize(mask96, scale);

height= size(mask96,1);
width= size(mask96,2);

A1=ones(height, width);
A2=imrotate(A1,angle);
if angle>0
    A3=find(A2==1);
    leftUpCorner = [ceil(A3(1)/size(A2,1));mod(A3(1),size(A2,1))];
else
    A3=find(A2'==1);
    leftUpCorner = [mod(A3(1),size(A2',1));ceil(A3(1)/size(A2',1))];
end


mask96(mask96<0.5)=0;
mask96(mask96>=0.5)=255;

mask(:,:,1)=(mask96)/255;
mask(:,:,2)=(mask96)/255;
mask(:,:,3)=(mask96)/255;

horizontalSum = sum(mask(:,:,1),1);
verticalSum= sum(mask(:,:,1),2);

v = verticalSum > 0;
h = horizontalSum > 0;

t=v(2:end)-v(1:end-1);
indexv = find(t~=0);

t=h(2:end)-h(1:end-1);
indexh = find(t~=0);

I=0;
J=0;
count = 0;
nbOfmasks = (length(indexv)*length(indexh))/4;
for i=1:2:length(indexv)
    
    v_bound = indexv(i:i+1);
    I=I+1;
    for j=1:2:length(indexh)
        
        h_bound = indexh(j:j+1);
        
        currentMask = zeros(height, width);
        
        currentMask(v_bound(1):v_bound(2), h_bound(1):h_bound(2))=1;
        
        RGBcurrentMask(:,:,1)=currentMask;
        RGBcurrentMask(:,:,2)=currentMask;
        RGBcurrentMask(:,:,3)=currentMask;
        J=J+1;
        allMasks{I}{J} = imrotate(RGBcurrentMask.*mask,angle);
        count=count+1;
        disp([num2str(count) ' out of ' num2str(nbOfmasks) ' masks created']);
    end
    J=0;
end


height= size(allMasks{1}{1},1);
width= size(allMasks{1}{1},2);

for i=1:1:length(indexv)/2
    lineMasks{i}=zeros(height, width, 3);
    for j=1:1:length(indexh)/2
        lineMasks{i}=lineMasks{i}+allMasks{i}{j};
    end
end

for j=1:1:length(indexh)/2
    columnMasks{j}=zeros(height, width, 3);
    for i=1:1:length(indexv)/2
        columnMasks{j}=columnMasks{j}+allMasks{i}{j};
    end
end




mask=imrotate(mask,angle);
end

