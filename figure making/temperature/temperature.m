
load('C:\Users\Yanik\Desktop\HD E on 8.12.14\Temperature distribution\results\column 1 test 4_temperature_t1.mat');
t1=Temperature;
load('C:\Users\Yanik\Desktop\HD E on 8.12.14\Temperature distribution\results\column 11_temperature_t1.mat');
t11=Temperature;
t1(isnan(sum(t1,2)),:)=[];
t11(isnan(sum(t11,2)),:)=[];


t1(1191:end,:)=[];
t1(:,5:end)=[];
t11(:,5:end)=[];