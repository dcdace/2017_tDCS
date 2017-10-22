function [sID, seqCond] = Day1
Screen('Preference', 'SkipSyncTests', 1);
rand('twister',sum(100*clock));

% change dir to the dir where this .m file is
[folder] = fileparts(which(mfilename));
cd(folder);

% ENTER PARTICIPANT
% opens on screen keyboard
if regexp(computer,'PCW\w*')
    system('%windir%\system32\osk.exe &'); % on Win
else
    system('open -n  /System/Library/Input\ Methods/KeyboardViewer.app'); % on Mac
end
% DIALOG BOX
        title       = 'Enter details';
        prompt      = {'psu','group a/b'};
        numlines    = [1,30];        
        answer      = inputdlg(prompt, title, numlines);
        sID         = answer{1};
        group       = answer{2};
        %

% PARTICIPANT DATA
[sIDDir, fs, seqCond] = getParticipant(sID,group);

%% =====================================================
% SCREEN & TEXT
% =====================================================
HideCursor;
expparam.white          = [255 255 255];
expparam.grey           = [240 240 240];
expparam.black          = [0 0 0];

expparam.ScreenColor    = expparam.grey;
expparam.ScreenID       = max(Screen('Screens'));

[expparam.win, expparam.rect] = Screen('OpenWindow',expparam.ScreenID, expparam.ScreenColor); % full screen
%[win, rect]= Screen('OpenWindow',ScreenID, ScreenColor, [0 0 1000 500]); % 1000x750 screen

% define text style
Screen('TextFont', expparam.win, 'Calibri');
Screen('TextSize', expparam.win, 42);
Screen('TextStyle', expparam.win, 0); % 0=normal,1=bold,2=italic,4=underline,8=outline,32=condense,64=extend
expparam.TextColor = expparam.black;
Screen('TextColor', expparam.win, expparam.TextColor);

% =====================================================
% PROCEDURE
% =====================================================

% % familiarisation
familiarise(fs);

% pre Training
preTest(sID, seqCond, sIDDir);
% 
% Instructions of what will happen in the scanner
familiariseOA(fs);

% set up tDCS
OATraining(sID, 1); % day1 training

% =====================================================
% EXIT
% =====================================================
clear Screen;
ShowCursor;
end