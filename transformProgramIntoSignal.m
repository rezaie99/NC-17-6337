function signal = transformProgramIntoSignal(progLine)

%time first shock
%shock duration
%nb of shock per burst
%delay between burst shocks
%delay between bursts
%nb of bursts



firstShock = progLine(:,1)*100;%unit is 10ms, 100Hz
shockDur = progLine(:,2);
nbShocks = progLine(:,3);
shockDelay = progLine(:,4)*100;
burstDelay = progLine(:,5)*100;
nbBursts = progLine(:,6);

burstSize = (shockDur + shockDelay) .* nbShocks;

trialDuration = firstShock + (burstSize + burstDelay).*nbBursts;

signal = zeros(1,trialDuration);

oneBurst = zeros(1,burstSize);

oneShock= ones(1,shockDur);

shockStart = 1;
for i=1:1:nbShocks
    oneBurst(shockStart:shockStart+shockDur-1) = oneShock;
    shockStart = shockStart + shockDur + shockDelay;
end

burstStart = firstShock;
for i=1:1:nbBursts
    signal(burstStart:burstStart+burstSize-1) = oneBurst;
    burstStart = burstStart + burstSize + burstDelay;
end
% figure
% plot(signal);
% axis([1 trialDuration -1 2]);
% xlabel('time [ms]')
% ylabel('signal')
%

end
