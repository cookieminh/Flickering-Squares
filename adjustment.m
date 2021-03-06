%% Clear the workspace and the screen
sca;
close all;
clearvars;
PsychDefaultSetup(2);
screens = Screen('Screens');
%% added because of sync error
Screen('Preference', 'SkipSyncTests', 1);
%% set up keys
KbName('UnifyKeyNames');
upKey = KbName('UpArrow');
downKey = KbName('DownArrow');
enterKey = KbName('RETURN');
spaceKey = KbName('SPACE');
escapeKey = KbName('ESCAPE');
%% get subj
prompt = 'Subject initials: ';
subj = input(prompt);
%% window and screen set up
screenNumber = max(screens);
% screenNumber = 0 ;
black = BlackIndex(screenNumber);
[window, windowRect] = PsychImaging('OpenWindow', screenNumber, black+0.5);
% [window, windowRect] = PsychImaging('OpenWindow',screenNumber,black,[0 0 1000 500 ]);
[screenXpixels, screenYpixels] = Screen('WindowSize', window);
baseRect = [0 0 65 65]; %%stim squares size
rRect = [0 0 100 100];
fixation = [0 0 20 20];  %%fixation size
[xCenter, yCenter] = RectCenter(windowRect);%%center points

Screen('DrawText',window,'Press arrow keys to indicate which array of squares is flickering more quickly',xCenter/4,yCenter,[1 1 1])
Screen('DrawText',window,'Press Key to Continue',xCenter-150,yCenter+30,[1 1 1])
Screen('Flip', window);
HideCursor();
KbStrokeWait;
%% basic set up
rectColor = [1 1 1];
pStart = GetSecs;
experiment = 2;
curTrial = 0;
stairCount = 0;
%% parameters
nTrials = 25;
adapTime = .5;
topUp = 1;
testTime = 10;
upScale = 1.01;
downScale = 0.99;
reversals = 6;
%% blank matrices for data storage and response tracking
keyResp = zeros(60,1);
respOut = zeros(60,nTrials);
meanFreqMat = zeros(1,nTrials);
sdFreqMat = zeros(1,nTrials);
AdaptField = zeros(1,nTrials);
frequency = zeros(500,2);
allAdaptFreq = zeros(1,5); %%stores all the frequency values, will likely never use but that way we have it
allRespFreq = zeros(1,1);
%% means were determined by latin square calculator and are pulled from 5 pre-made .txt files: mean1.txt, mean2.txt, etc...
meanPick = randi([1,5]);
meanName = strcat('mean',int2str(meanPick));
meanid = fopen(strcat(meanName,'.txt'));
mean = fscanf(meanid,'%f');
meanR = rand*3; %starting response mean (mean for test field) is chosen randomly
%% phase is randomized, this variable is not stored
phaseMat = abs(rand(5,5).*10);
rLumVal = 0;
%% do it
for k = 1:nTrials
    %% puts adapt field either on left or right
    positionPick = randi([1,2]);
    if positionPick == 1 %% adapt field on the left
        %%distance away from fixation with these setting is 125 pixels
        xFSquares = xCenter-500;  %%location stim squares - overall width of square matix is 375
        yFSquares = yCenter-225;
        xRSquares = xCenter+175;  %%location response squares
        yRSquares = yCenter;
        AdaptField(1,k) = 1;
    else %% adapt field on the right
        xRSquares = xCenter-175;  %%location stim squares - overall width of square matix is 375
        yRSquares = yCenter;
        xFSquares = xCenter+50;  %%location response squares
        yFSquares = yCenter-225;
        AdaptField(1,k) = 2;
    end
    
    %% matrix of probabalistically distributed frequencies
    sd = mean(k,1)/3;
    freqMat = abs(normrnd(mean(k,1),sd,5,5)); %%frequency of stim squares
    allAdaptFreq = cat(1,allAdaptFreq,freqMat);
    meanFreq = sum(freqMat(:))/25;
    meanFreqMat(1,k) = meanFreq;
    sdFreqMat(1,k) = std(freqMat(:));
    respFreq = abs(rand*4);  %%response square freq
    respFreqnew = respFreq;
    
    %% moves to next trial after after 60, even if staircase isn't resolved
    while stairCount <= reversals && curTrial < 60
        curTrial = curTrial+1;
        pStart = GetSecs;
        while GetSecs - pStart < testTime;
            %% draw squares at at lum determined by sine function and timing
            time = GetSecs-pStart;
            for i = 1:5
                for j = 1:5
                    lumVal = 0.5+(0.5*sin(freqMat(i,j)*time*(2*pi)+(phaseMat(i,j))));
                    %             rectColor = [lumVal*rand lumVal*rand lumVal*rand];
                    rectColor = [lumVal lumVal lumVal];
                    xPos = xFSquares+i*75;
                    yPos = yFSquares+j*75;
                    centeredRect = CenterRectOnPointd(baseRect, xPos, yPos);
                    Screen('FillRect', window, rectColor, centeredRect);
                end
            end
            %% get key responses from response square
            KbCheck;
            [keyIsDown, seconds, keyCode ]  = KbCheck;
            if keyIsDown
                if keyCode(upKey) && positionPick ==1
                    respFreqnew = respFreq.*upScale;
                    keyResp(curTrial,1) = 'U';
                elseif keyCode(downKey) && positionPick == 2
                    respFreqnew = respFreq.*downScale;
                    keyResp(curTrial,1) = 'D';
                elseif keyCode(downKey) && positionPick == 1
                    respFreqnew = respFreq.*downScale;
                    keyResp(curTrial,1) = 'D';
                elseif keyCode(upKey) && positionPick == 2
                    respFreqnew = respFreq.*upScale;
                    keyResp(curTrial,1) = 'U';
                elseif keyCode(escapeKey)
                    close all;
                    sca;
                elseif keyCode(spaceKey)
                    stairCount = 7;
                end
            end
            respFreq = respFreqnew;
            %% draw response square, fixation point
            rLumValnew = rLumVal;
            rLumVal = 0.5+(0.5*sin(respFreq*(GetSecs-pStart)*(2*pi)+(rLumValnew)));
            respFreq
            reponseColor = [rLumVal rLumVal rLumVal];
            sideRect = CenterRectOnPointd(rRect, xRSquares,yRSquares);
            Screen('FillRect', window, reponseColor, sideRect);
            
            
            %% draw fixation
            fixRect = CenterRectOnPointd(fixation,xCenter,yCenter);
            Screen('FillOval',window, [.75 .75 .75],fixRect);
            %% screen flip
            Screen('Flip', window);
            allRespFreq = cat(1,allRespFreq,respFreq);
            meanRespFreq = sum(respFreq(:));
            respOut(curTrial,k) = meanRespFreq;
            %% increase staircase counter
            if curTrial > 4 && keyResp(curTrial,1) == 'U' && keyResp(curTrial-1,1) == 'D'
                stairCount = stairCount+1;
            elseif curTrial > 4 && keyResp(curTrial,1) == 'D' && keyResp(curTrial-1,1) == 'U'
                stairCount = stairCount+1;
            end
        end
    end
    %                 respFreq = respFreqnew;
    meanRespFreq = sum(respFreq(:));
end
%% Back to the beginning
stairCount = 0;
curTrial = 0;
meanR = rand*3;
Screen('FillOval',window, [.75 .75 .75],fixRect);
Screen('Flip', window);

%% save stuff
means = cat(1,mean.',meanFreqMat);
allAdaptFreq = cat(1,allAdaptFreq,zeros(1,5));
allRespFreq = cat(1,allRespFreq,zeros(1,1));
outAdapt = struct('means',means,'responses',respOut,'standevs',sdFreqMat,'rORlAdaptField',AdaptField,'allAdaptFreq',allAdaptFreq,'allRespFreq',allRespFreq);
saveFile = strcat(subj,'_Adapt_',date,'.mat');
save(saveFile,'outAdapt');

%% breaks every 5 trials
WaitSecs(3);
if k == 5
    Screen('DrawText',window,'You are 20% done. Feel free to take a break. Press Key to Continue',xCenter/4,yCenter,[1 1 1])
    Screen('Flip', window);
    KbStrokeWait;
elseif k==10
    Screen('DrawText',window,'You are 40% done. Feel free to take a break. Press Key to Continue',xCenter/4,yCenter,[1 1 1])
    Screen('Flip', window);
    KbStrokeWait;
elseif k==15
    Screen('DrawText',window,'You are 60% done. Feel free to take a break. Press Key to Continue',xCenter/4,yCenter,[1 1 1])
    Screen('Flip', window);
    KbStrokeWait;
elseif k==20
    Screen('DrawText',window,'You are 80% done. Feel free to take a break. Press Key to Continue',xCenter/4,yCenter,[1 1 1])
    Screen('Flip', window);
    KbStrokeWait;
end


Screen('DrawText',window,'You are done. Thank you for participating. Press Key to Continue',xCenter/4,yCenter,[1 1 1])
Screen('Flip', window);
KbStrokeWait;
sca;
% hist(freqMat);