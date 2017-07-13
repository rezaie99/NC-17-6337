function mask=get1Masks(angle)

mask96 = double(imread('mask 96.jpeg'));

%make it RGB
mask(:,:,1)=(255-mask96)/255;
mask(:,:,2)=(255-mask96)/255;
mask(:,:,3)=(255-mask96)/255;

mask=imrotate(mask,angle);
end

