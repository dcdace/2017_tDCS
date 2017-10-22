function [PreOA, PreUN] = preTest(sID, seqCond, sIDDir)
% perform (8) sequences, each 5x
Screen('Preference', 'SkipSyncTests', 1);

% change dir to the dir where this .m file is
[folder] = fileparts(which(mfilename));
cd(folder);
% get Data directory name
dataDir = [folder filesep 'Data' filesep];
% if Data dir doesn't exist, creat it

if ~exist(dataDir, 'dir')
    mkdir(dataDir);
    fprintf('Created ''Data'' folder %s \n', dataDir);
end
% Get date and time
time = clock;
if time(1,4) < 10
    hr = ['0' num2str(time(1,4))];
else
    hr = num2str(time(1,4));
end
if time(1,5) < 10
    minutes = ['0' num2str(time(1,5))];
else
    minutes = num2str(time(1,5));
end
datetime = [datestr(now,'yyyymmdd') '_' hr minutes];
%
%
% =====================================================
% PARAMETERS
% =====================================================
%sequences
AllSequences = [
    5,3,4,2,1, 1;     %1
    5,2,1,3,4, 2;     %2
    4,5,1,3,2, 3;     %3
    4,1,3,5,2, 4;     %4
    3,1,4,2,5, 5;     %5
    2,3,5,4,1, 6;     %6
    2,5,3,1,4, 7;     %7
    1,4,2,5,3, 8;     %8
    1,2,4,3,5, 9;     %9
    1,5,4,2,3, 10;    %10
    3,5,2,1,4, 11;    %11
    3,2,5,1,4, 12;    %12
    ];
Sequences = (AllSequences(seqCond,:));
% random order of sequences
% shuffle
Sequences   = Sequences(randperm(8),:);
% last number is sequence number
sNR         = Sequences(:,6);
% first 5 numbers are keys to be pressed
Sequences   = Sequences(:,1:5);
% sequences 1:4 = trained; 5:8 = untrained
OAs         = seqCond(1,1:4);
UNs         = seqCond(1,5:8);

% key names
% if Mac then getKeyboard
if regexp(computer,'PCW\w*')
    theKb = 0;
else
    theKb = GetKeyboard(0);
end
KbName('UnifyKeyNames');
spacebar = KbName('m');
k1 = KbName('y');
k2 = KbName('5%');
k3 = KbName('4$');
k4 = KbName('3#');
k5 = KbName('q');

keys = [k1,k2,k3,k4,k5]; % response keys

keylist = ones(1,256); % create a list of 256 zeros
%keylist(keys) = 1; % set keys you interested in to 1

KbQueueCreate(theKb,keylist); %Make kb queue

%% =====================================================
% SCREEN & TEXT
% =====================================================
HideCursor;
%     ListenChar(2); % suppresses any output of keypresses to Matlab
% create Screen
grey = [140 140 140];
black = [0 0 0];

ScreenColor = grey;
ScreenID = max(Screen('Screens'));

[win, rect]= Screen('OpenWindow',ScreenID, ScreenColor); % full screen
%[win, rect]= Screen('OpenWindow',ScreenID, ScreenColor, [0 0 1000 500]); % 1000x750 screen

% define text style
Screen('TextFont',win, 'Calibri');
Screen('TextSize',win, 42);
Screen('TextStyle', win, 0); % 0=normal,1=bold,2=italic,4=underline,8=outline,32=condense,64=extend
TextColor = black;
Screen('TextColor', win, TextColor);
%% =====================================================
% Instructions
% =====================================================
DrawFormattedText(win, ['Now you will need to tap 8 different sequences. \n '...
    'First memorise the sequence, then tap it FIVE times. \n\n Be as quick and accurate as possible. Your performance will be monitored. \n\n'...
    'Press Green to start'], 'center', 'center');
Screen('Flip', win);
% waits for spacebar
while KbCheck(-1); end % Wait until all keys are released
[keyIsDown, seconds, keyCode ] = KbCheck(-1);
while ~keyCode(spacebar)
    [keyIsDown, seconds, keyCode ] = KbCheck(-1);
end

%% =====================================================
% 5 SQUARE POSITIONS
% =====================================================
% square size
sw = 40; % square width in px
sh = 40; % square height
sg = 0; % gap between squares
sn = 5; %

[x,y] = RectCenter(rect);
% left and right border position for the first square
l = x - (sn/3+1)*(90/3) - (sn/3)*sw;
r = l + sw;
b = rect(1,4) - 10;
t = b - sh;

Squares=zeros(4,sn);
for i = 1 : sn
    Squares(:,i) = [l;t;r;b];
    l = l + sw + sg;
    r = r + sw + sg;
end
%border = [Squares(1,1), Squares(2,1), Squares(3,5), Squares(4,5)];

%% START
% six sequences
p               = 0; % each press
totalErrors     = 0;
Errors          = [];
MT              = [];
OUTPUT          = [];
allSeqSummary   = [];
allSeqAvgs      = [];
medianMT        = 0;

for s = 1 : 8 %8 how many sequences
    thisSeqSummary = [];
    % fixation cross
    Screen('Flip', win);
    WaitSecs(0.2);
    %Screen('FrameRect', win, black, border );
    DrawFormattedText(win, ' * ', Squares(1,3), Squares(2,3), TextColor);
    Screen('Flip', win);
    WaitSecs(1);
    % sequence
    %Screen('FrameRect', win, black, border );
    for i = 1:5
        DrawFormattedText(win, [' ' num2str(Sequences(s,i))], Squares(1,i), Squares(2,i)-7,TextColor);
    end
    Screen('Flip', win);
    WaitSecs(2.7);
    % produce each sequence 5 times
    for r = 1:5 % 5 repetitions
        E = 0;
        % 5 black asterix
        for i = 1:5
            DrawFormattedText(win, ' * ', Squares(1,i), Squares(2,i)-40, TextColor);
        end
        %Screen('FrameRect', win, black, border );
        DrawFormattedText(win, ' * ', Squares(1,3), Squares(2,3));
        ssTime = Screen('Flip', win); % sequence start time
        % sets asterix colors to default (black)
        
        % 5 keys in each sequence
        acolor(1:3,1:5) = 0;
        TimeSequenceStarted = GetSecs;
        KbQueueStart(); %start listening
        KbQueueFlush(); %removes all keyboard presses
        
        for k = 1:5 % 5 keys
            e = 0; % error yes or no
            % the correct key = Sequences(s,k)
            % WAITS RESPONSE
            
            [pressed, firstPress] = KbQueueCheck(); %check response
            % if pressed
            while ~pressed
                [pressed, firstPress] = KbQueueCheck(); %check response
            end
            tp = GetSecs;
            tpSinceSeqStart = tp - TimeSequenceStarted;
            p = p + 1;
            if k == 1
                tfp = tp; % time first key pressed
                gap = tpSinceSeqStart;
            end
            if any(find(firstPress) ~= keys(Sequences(s,k)))
                e = 1;
                E = 1;
                totalErrors = totalErrors + 1;
            end
            OUTPUT = [OUTPUT; s k tpSinceSeqStart e sNR(s)];
            % sequence execution time
            % if sequence was not executed correctly the asteriks is red
            if e
                acolor(:,k) = [255 0 0]; % red
                % Screen('FrameRect', win, black, border );
                DrawFormattedText(win, ' * ', Squares(1,3), Squares(2,3));
                % redraw all 5 asteriks
                for i = 1:5
                    DrawFormattedText(win, ' * ', Squares(1,i), Squares(2,i)-40, acolor(:,i));
                end
                Screen('Flip', win);
            else % if correct the asteriks ir green
                acolor(:,k) = [0 255 0]; % green
                %Screen('FrameRect', win, black, border );
                DrawFormattedText(win, ' * ', Squares(1,3), Squares(2,3));
                % redraw all 5 asteriks
                for i = 1:5
                    DrawFormattedText(win, ' * ', Squares(1,i), Squares(2,i)-40, acolor(:,i));
                end
                Screen('Flip', win);
                
            end
        end
        KbQueueStop();
        lastMT          = tp - tfp;
        percMTdiff      = (lastMT/medianMT-1)*100; % difference in % between the lastMT and median MT
        MT              = [MT; lastMT];
        medianMT        = median(MT);
        Errors          = [Errors;E];
        allSeqSummary   = [allSeqSummary; sNR(s) r lastMT E gap];
        thisSeqSummary  = [thisSeqSummary; sNR(s) lastMT E gap];
        % asterix for 800ms
        % if there was an error then red, if not - green or blue
        % Screen('FrameRect', win, black, border );
        if E
            DrawFormattedText(win, ' * ', Squares(1,3), Squares(2,3), [255 0 0]);
        else
            % if faster than median MT, then 3 green asteriks
            if percMTdiff < -20
                DrawFormattedText(win, '  * * * ', Squares(1,2), Squares(2,2), [0 255 0]);
            else
                % if faster than median MT, then 3 blue asteriks
                if percMTdiff > 20
                    DrawFormattedText(win, '  * * * ', Squares(1,2), Squares(2,2), [0 0 255]);
                else
                    % if within 20% difference then just one green asteriks
                    DrawFormattedText(win, ' * ', Squares(1,3), Squares(2,3), [0 255 0]);
                end
            end
        end
        Screen('Flip', win); %sequence end time
        WaitSecs(0.8);
    end
    % allSeqAvgs = [sNR meanMT meanCorrMT totalErrors adjMT meanGaps];
    % mean of correct responses
    meanMT      = nanmean(thisSeqSummary(:,2));
    meancorrMT  = nanmean(thisSeqSummary(thisSeqSummary(:,3)== 0,2));
    allSeqAvgs  = [allSeqAvgs; sNR(s) meanMT meancorrMT sum(thisSeqSummary(:,3)) meancorrMT/((5-sum(thisSeqSummary(:,3)))/5) nanmean(thisSeqSummary(:,4))];
    
    seTime      = GetSecs - ssTime; % trial execution time (5 repetitions of one sequence)
end
DrawFormattedText(win, 'Well done! \n\n Press Green to continue', 'center', 'center', TextColor);
Screen('Flip', win);
% waits for spacebar
while KbCheck(-1); end % Wait until all keys are released
[keyIsDown, seconds, keyCode ] = KbCheck(-1);
while ~keyCode(spacebar)
    [keyIsDown, seconds, keyCode ] = KbCheck(-1);
end
Gaps        = OUTPUT((OUTPUT(:,3)==1),4);
% all sequences per condition means
PreOAavgs   = allSeqAvgs(dsearchn(allSeqAvgs(:,1),OAs'),:);
PreUNavgs   = allSeqAvgs(dsearchn(allSeqAvgs(:,1),UNs'),:);
% condition means
%[sID meanMT meanCorrMT totalErrors adjMT meanGaps]
PreOA       = nanmean(PreOAavgs(:,2:6));
PreUN       = nanmean(PreUNavgs(:,2:6));

filename    = fullfile(sIDDir, [sID '_preTest_' datetime '.mat']);
save(filename);
% get back to Matlab
clear Screen;
ShowCursor;
end