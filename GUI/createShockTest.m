%%
clc



rowCommands = zeros(9,200);

colCommands = zeros(13,200);

for i=1:1:9
    a=((i-1)*13+1);
    b=(i)*13;
    rowCommands(i,a:b)=1;
    for j=1:1:13
        c=((j-1)+1+(i-1)*13);
        d=((j)+(i-1)*13);
        colCommands(j,c:d)=1;
    end
end


rowCommands = [zeros(9,100) rowCommands];

colCommands = [zeros(13,100) colCommands];



x= zeros(size(rowCommands,1),size(rowCommands,2)*2);
y= zeros(size(colCommands,1),size(colCommands,2)*2);

x(:,2:2:end)=rowCommands;

y(:,2:2:end)=colCommands;

rowCommands=x;
colCommands=y;


x=1:1:size(colCommands,2);
x=repmat(x,size(colCommands,1),1);
x2 =  diff(colCommands,1,2);
x2=[zeros(size(colCommands,1),1) x2];
x3 = x2.*x;

allActivations = [];
for i=1:1:13
   currentactivations = x3(i,:);
   currentactivations(currentactivations==0)=[];
   currentactivations=[abs(currentactivations);(currentactivations*0)+i;currentactivations>0];
   allActivations=[allActivations currentactivations];
end

[~,I]= sort(allActivations(1,:));
allActivations=allActivations(:,I);

x1=1:1:size(rowCommands,2);
x1=repmat(x1,size(rowCommands,1),1);
x21 =  diff(rowCommands,1,2);
x21=[zeros(size(rowCommands,1),1) x21];
x31 = x21.*x1;
allActivations1 = [];
for i=1:1:9
   currentactivations1 = x31(i,:);
   currentactivations1(currentactivations1==0)=[];
   currentactivations1=[abs(currentactivations1);(currentactivations1*0)+i;currentactivations1>0];
   allActivations1=[allActivations1 currentactivations1];
end

[~,I1]= sort(allActivations1(1,:));
allActivations1=allActivations1(:,I1);


rowActiv = allActivations1;
colActiv = allActivations;

activations = [rowActiv(1,:);rowActiv(2,:);colActiv(2,:)];
%first row is timePoint is 10ms
%third row is the row index
%fourth row is the column index


a=activations';
a=[num2str(a(:,3)) num2str(a(:,2))];

bin = char(zeros(size(a,1),8));
nonBin = zeros(size(a,1),1);
for i=1:1:size(a,1)
    bin(i,:) = dec2bin(str2double(a(i,:)),8);
    nonBin(i)=str2double(a(i,:));
end
s=colActiv';
bin(s(:,3)==0,:)=[];
nonBin(s(:,3)==0)=[];




a=[activations(1,1);diff(activations(1,:)')];
u= unique (a);
c=zeros(length(u),1);
for i=1:1:length(u)
    b=a==u(i);
    c(b)=i;
end
d=dec2bin(c,8);

differentIntervals = u;
whichIntervalBin=d;
whichInterval=c;


nonBin(end:-1:1)=nonBin;


save('shockTest.mat', 'rowCommands', 'colCommands', 'rowActiv', 'colActiv',...
    'activations','bin', 'differentIntervals', 'whichInterval','nonBin','whichIntervalBin');


%%
figure
for i=1:1:9
    plot(i+rowCommands(i,:))
    hold all
end
figure
for j=1:1:13
    plot(j+colCommands(j,:))
    hold all
end


