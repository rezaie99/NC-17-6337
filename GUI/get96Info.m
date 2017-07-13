function [screenInfo, X, Y] =get96Info()

Screen('CloseAll');

background=[0, 0, 0];

% Open onscreen window. We use the display with the highest number on
% multi-display setups:
screen=max(Screen('Screens'));
screen=1
% This will open a screen with default settings, aka black background,
% fullscreen, double buffered with 32 bits color depth:
[win, screenInfo] = Screen('OpenWindow', screen); % , 0, [0 0 800 600]);

% Hide the mouse cursor:
%HideCursor;

ShowCursor('Hand',win);


X=[];
Y=[];
KbName('UnifyKeyNames');

esc=KbName('ESCAPE');
space=KbName('SPACE');
right=KbName('RightArrow');
left=KbName('LeftArrow');

nkey=KbName('N');
ykey=KbName('Y');
zkey=KbName('Z');

while1 = true;

while while1
    
    % Clear screen to background color:
    Screen('FillRect', win, background);
    
    % Show instructions...
    tsize=20;
    Screen('TextSize', win, tsize);
    [textx0, texty0]=Screen('DrawText', win, 'Please click on two corners of the plate''s long side, the one with well indexes',40, 100);
    
    % Flip to show the startup screen:
    
    Screen('Flip',win);
    
    
    while2 = true;
    X=[];
    Y=[];
    while while2
        [clicks,x,y,whichButton] = GetClicks(win, 0);
        if whichButton==1 %left click
            X=[X x];
            Y=[Y y];
        elseif whichButton==2 % ?
            
        elseif whichButton== 3 % ?
            
        end
        
        if isequal(length(X),2)
            while2=false;
        end
    end
    
    
    Screen('DrawLine', win , [255 0 0 1], X(1), Y(1), X(2), Y(2) ,2);
    
    [textx, texty]=Screen('DrawText', win, 'Is this line correctly alligned ?',40, texty0+10+tsize);
    [textx, texty]=Screen('DrawText', win, 'Escape for NO => start again',40, texty+10+tsize);
    [textx, texty]=Screen('DrawText', win, 'Space for Yes => save values',40, texty+10+tsize);
    
    Screen('Flip',win);
    
    
    while3 = true;
    while while3
        [keyIsDown, secs, keyCode]=KbCheck; %#ok<ASGLU>
        if keyIsDown
            if (keyCode(nkey))
                % escape
                % wrong alignment, do it again
                while1 = true;
                % stop checking keyboard
                while3 = false;
            end;
            
            if (keyCode(ykey)) || (keyCode(zkey))
                % Toggle playback on space.
                %good allignment, quit
                while1 = false;
                % stop checking keyboard
                while3 = false;
            end;
            
            if (keyCode(esc)) 
                %escape pressed
                screenInfo = [];
                X=[];
                Y=[];
                Screen('CloseAll');
                return;
            end;
            
            % Wait for key-release:
            KbReleaseWait;
        end;
    end
    
    
    
    
end

Screen('CloseAll');

screenInfo=screenInfo/2;
X=X/2;
Y=Y/2;

end
