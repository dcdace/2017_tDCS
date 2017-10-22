clear all

folder = fileparts(which(mfilename));
cd(folder);
% get Data directory name
dataDir = [folder filesep 'Data' filesep];

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

% opens on screen keyboard
if regexp(computer,'PCW\w*')
    system('%windir%\system32\osk.exe &'); % on Win
else
    system('open -n  /System/Library/Input\ Methods/KeyboardViewer.app'); % on Mac
end
% DIALOG BOX
title       = 'Enter details';
prompt      = {'psu'};
numlines    = [1,30];
answer      = inputdlg(prompt, title, numlines);
sID         = answer{1};
%

sIDDir = dir([dataDir sID '*tDCS']);
if isempty(sIDDir)
    display('Participant''s directody does not exist. Check psu number and try again');
else
    sIDDir = fullfile(dataDir, sIDDir.name);
    
    load(fullfile(sIDDir, 'demographics.mat'), 'participant');
    
    if exist(fullfile(sIDDir, 'lastday.mat'), 'file')
        load(fullfile(sIDDir, 'lastday.mat'))
        
        day = day + 1;
    else
        day = 1;
    end
    
    % DIALOG BOX
    title   = 'Check participant details';
    prompt  = {
        'psu',...                               % 1
        'Date', ...                             % 2
        'Age',...                               % 3
        'Gender ( f / m / other )',...          % 4
        'Right handed? ( yes / no / other )',...% 5
        'e-mail (optional)',...                 % 6
        'group', ...                            % 7
        'training day'                          % 8
        };              
    numlines        = [1,60];
    defaultanswer   = {sID, ...
        datetime, ...
        participant.age, ...
        participant.gender, ...
        participant.righthanded, ...
        participant.email, ...
        participant.group, ...
        num2str(day)
        };
    
    answer = inputdlg(prompt, title, numlines, defaultanswer);
    
    p.sID           = answer{1};
    p.datetime      = answer{2};
    p.age           = answer{3};
    p.gender        = answer{4};
    p.righthanded   = answer{5};
    p.email         = answer{6};
    p.group         = answer{7};
    
    participant     = p;
    % save
    filename        = fullfile(sIDDir, 'demographics.mat');
    save(filename, 'participant');
    
    % check if
    
    % OA training
    OATraining(sID, day);
end