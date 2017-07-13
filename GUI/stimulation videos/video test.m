%%
clear all
close all
clc

outputVideoName = 'videoTest';

writerObj = VideoWriter(outputVideoName);

videoLength = 5; %seconds

frameRate = 30;%frames per seconds

nbOfFrames = frameRate * videoLength;

width = 1000;
height = 1000;

im = zeros(height, width, 3);
im2 = im;
im3=im;
im2(:,:,1)=ones(height, width);%Red
im3(:,:,2)=ones(height, width);%Green
im(:,:,3)=ones(height, width);%Blue


videoLength = 30; %seconds

%image(im)


%%
%open(writerObj);
clear allImages
%allImages = zeros(nbOfFrames, height, width, 3);

for i=1:1:nbOfFrames
    i
    currentImage =  zeros(height, width, 3);
    switch mod(i,3)
        case 0
            currentImage=im;
        case 1
            currentImage=im2;
        case 2
            currentImage=im3;
    end
    %image(currentImage);
    %allImages{i}=currentImage;
    allImages(i)=im2frame(currentImage);
    %allImages1(i)=getframe;
    %writeVideo(writerObj,currentImage);
end

%close(writerObj);
%%












