function [sIDDir, Fs, seqCond] = getParticipant(sID, group)
% change dir to the dir where this .m file is
[folder] = fileparts(which(mfilename));
cd(folder);

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

% find if participants folder already exists
% find all directories
folderNames = dir('Data');
folderNames = {folderNames.name};

for i = 1 : length(folderNames)
    thisName    = folderNames{i};
    split       = regexp(thisName, '_');
    if ~isempty(split)
        sIDnames{i} = thisName(1:split-1);
    end
end

if isempty(find(strcmp(sIDnames,sID), 1))
    participantExists = 0;
else
    participantExists   = 1;
    sIDnr               = find(strcmp(sIDnames,sID), 1);
end

switch participantExists
    case 1
        % If participant exists, get all parameters
        if isempty(regexp(folderNames{sIDnr}, 'tDCS', 'once'))
            % att 'tDCS' at the end of the folder name
            movefile(fullfile(folder, 'Data', folderNames{sIDnr}), ...
                strrep(fullfile(folder, 'Data', folderNames{sIDnr}), folderNames{sIDnr}, [folderNames{sIDnr} 'tDCS']));
            sIDDir = [fullfile(folder, 'Data', folderNames{sIDnr}) 'tDCS'];
        else
            sIDDir = fullfile(folder, 'Data', folderNames{sIDnr});
        end
        load(fullfile(sIDDir, 'E3parameters.mat'), 'Fs', 'seqCond');
        
        % check and change demographics
        load(fullfile(sIDDir, 'demographics.mat'), 'participant');
        participant.group = group;
        
        if isfield(participant, 'handed')
            participant.righthanded = participant.handed;
            participant = rmfield(participant, 'handed');
        end
        
        % DIALOG BOX
        title           = 'Check participant details';
        prompt          = {
            'psu',...                               % 1
            'Date', ...                             % 2
            'Age',...                               % 3
            'Gender ( f / m / other )',...          % 4
            'Right handed? ( yes / no / other )',...% 5
            'e-mail (optional)',...                 % 6
            'group'                                 % 7
            };                               
        numlines        = [1,60];
        defaultanswer   = {
            sID, ...
            datetime, ...
            participant.age, ...
            participant.gender, ...
            participant.righthanded, ...
            participant.email, ...
            participant.group, ...
            };
        
        answer          = inputdlg(prompt, title, numlines, defaultanswer);
        %
        p.sID           = answer{1};
        p.datetime      = answer{2};
        p.age           = answer{3};
        p.gender        = answer{4};
        p.righthanded   = answer{5};
        p.email         = answer{6};
        p.group         = answer{7};
        
        participant     = p;
        
        % save
        filename = fullfile(sIDDir, 'demographics.mat');
        save(filename, 'participant');
        
    case 0
        % If participant does not exist, generate parameters
        % =====================================================
        % PARAMETERS
        % =====================================================
        % generates which sequences to use
        X       = Shuffle(1:12);
        seqCond = X(1,1:8);
        % sequences 11 and 12 can't be in the same condition
        while (sum(ismember([11,12],seqCond (1:4)))==2 || (sum(ismember([11,12],seqCond (5:8)))==2))
            X       = Shuffle(1:12);
            seqCond = X(1,1:8);
        end
        % which sequence to use for familiarisation
        seq             = (1:12);
        seq(seqCond)    = [];
        Fs              = seq(1);
        
        sIDDir = [fullfile(folder, 'Data', sID) '_tDCS'];
        if ~exist(sIDDir, 'dir')
            mkdir(sIDDir);
        end
        save(fullfile(sIDDir, 'E3parameters.mat'), 'Fs' ,'seqCond');
        
        % DIALOG BOX
        title = 'Enter participant details';
        prompt={
            'psu',...                                       % 1
            'Date', ...                                     % 2
            'Age',...                                       % 3
            'Gender ( f / m / other )',...                  % 4
            'Are you right handed? ( yes / no / other )',...% 5
            'Your e-mail (optional)',...                    % 6
            'group'                                         % 7
            };              
        numlines        = [1,60];
        defaultanswer   = {sID datetime '' '' '' '' group};
        answer          = inputdlg(prompt, title, numlines, defaultanswer);
        %
        p.sID           = answer{1};
        p.datetime      = answer{2};
        p.age           = answer{3};
        p.gender        = answer{4};
        p.righthanded   = answer{5};
        p.email         = answer{6};
        p.group         = answer{7};
        
        participant     = p;
        
        % save
        filename = fullfile(sIDDir, 'demographics.mat');
        save(filename, 'participant');
end

