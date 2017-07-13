%spikes2.mat contient une variable appelÃ©e spikes2 qui a deux colonnes channel puis time
clear all


load('spikes_NB_opto_10Hz.mat');
clc
close all

%Lecture du file
spikes2=spikes_NB_opto_10Hz;

spikes2(:,2) = spikes2(:,2)/100;
spikes = spikes2;




plot(spikes(:,2)/(60),spikes(:,1),'o');
figure


%Raster plot cell, avant, après et au total: initiation
raster1 = {};
raster2 = {};
rastertot = {};




for i = 1:64
    
%     2 cells: avant et après, per channel
       raster1(i)=  {spikes(find(spikes(:,1)==i & spikes(:,2)<60 & spikes(:,2)>49),2)};
    
    % si on veut check à l interieur 
%     raster2(i)=  {spikes(find(spikes(:,1)==i & spikes(:,2)>60 & spikes(:,2)<70),2)};
raster2(i)=  {spikes(find(spikes(:,1)==i & spikes(:,2)>60 & spikes(:,2)<70),2)};

rastertot(i)=  {spikes(find(spikes(:,1)==i),2)};

end




% Initiation table, somme des spikes per channel avant et après 

data1 = [];
data2 = [];  
data3 = [];  

% 
% for i = 1:8
%        for j = 1:8
%            data1(i,j) = length(cell2mat(raster1((i-1)*8+j)));
%            data2(i,j) = length(cell2mat(raster2((i-1)*8+j)));
% 
%        end
% end
% 



% duration xp in ms - Binage
bin = 180000;
NBpoints=bin/1000;


x1 = hist(raster1{33},60000);
x2 = hist(raster2{55},60000);

xtot = histc(rastertot{1,55},1:1800);

%plot frequency à l interieur d un channel
plot(histc(rastertot{1,54},1:1800));

%T-test entre avant et après
%Gerer le temps en sec
pvalues = [];
temp = [];
for i = 1:64
    FR = histc(rastertot{1,i},1:1800);
    dataTtest1 = FR(1:60);
    dataTtest2 = FR(61:120);
    [h temp] = ttest2(dataTtest1,dataTtest2);
    pvalues = [pvalues temp];
end


pvalues(find(isnan(pvalues)==1)) = 1;
pvalues(find(pvalues>0.0001)) = 1;
significant = find(pvalues<0.05);


PvaluesCell = {};

for i=1:64
   
    PvaluesCell(i) ={pvalues(i)};
    
end

%pour plot 3D et heatmap

for i = 1:8
       for j = 1:8
           data1(i,j) = length(cell2mat(raster1((i-1)*8+j)));
           data2(i,j) = length(cell2mat(raster2((i-1)*8+j)));
           data3(i,j) = cell2mat(PvaluesCell((i-1)*8+j));
       end
end



R= find(pvalues~=1);
Rnew={};
Rnew2=[];

for i=1:length(R)
   
    Rnew{i}= histc(rastertot{1,R(i)},1:1800);
    
end

Rnew2=cell2mat(Rnew);
Rfinale= sum(Rnew2,2);
figure
plot(Rfinale/length(R));



heatM={};
heatMfinal=[];



for i=1:64
   
    heatM{i}= histc(rastertot{1,i},1:1800);
    
end

for i=1:64
   if size(cell2mat(heatM(i)))== [1 1800] 
   heatM{i}= transpose(heatM{i});
   end
end


 heatMfinal=cell2mat(heatM);
 
 
heatMfinal2 = {};

for i=1:900
   
    heatMfinal2(i) ={heatMfinal(i)};
    
end




% x1 = hist(raster1{1,55},10000);
% temp = [];
% for i=1:64
%     temp = [temp; hist(raster2{1,i},10000);];
% end
% x1 = mean(temp);
% x2 = hist(raster2{1,55},10000);
% figure
% hist(raster1{1,55},20);
% ylim([0 30]);
% figure
% hist(raster2{1,55},20);
% ylim([0 30]);


Zlim=max(max(data2));

figure
title('Before stimulation');
h1=bar3(data1);
zlim([0 Zlim])
colorbar

for k = 1:length(h1)
    zdata = get(h1(k),'ZData');
    set(h1(k),'CData',zdata,...
             'FaceColor','interp')
end

figure
title('During stimulation');
h2=bar3(data2);
colorbar

for k = 1:length(h2)
    zdata = get(h2(k),'ZData');
    set(h2(k),'CData',zdata,...
             'FaceColor','interp')
end


figure
title('T test results');
h3=bar3(data3);
colorbar

for k = 1:length(h3)
    zdata = get(h3(k),'ZData');
    set(h3(k),'CData',zdata,...
             'FaceColor','interp')
end




zlim([0 Zlim])
% 
% figure
%     [t1 t2] = pmtm(xtot,2,[],100)
%     plot(t2,t1);
% % hold on    
%     [t1 t2] = pmtm(x2,2,[],1000)
%     plot(t2,t1,'r');