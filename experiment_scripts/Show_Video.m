function Show_Video(win, rect, movie, movieduration)
% start timer to measure how long video has been playing
duration = 0;
tic;
% Open movie file
%[movie movieduration fps w h count] = Screen('OpenMovie', win, moviename);

Screen('PlayMovie', movie, 1, 0); % loop enabled

% Playback loop: Runs 'videoDuration' seconds long

while duration < movieduration
    duration = round(toc); % how long video has been playing already
    % Wait for next movie frame, retrieve texture handle to it
    [tex] = Screen('GetMovieImage', win, movie);
    
    % Valid texture returned? A negative value means end of movie reached:
    if tex <= 0
        % We're done, break out of loop:
        break;
    end;
    
    % Draw the new texture immediately to screen:
    Screen('DrawTexture', win, tex, []);
    % frameNum=round(timeindex*fps); % gets current frame number
    
    % Update display:
    vbl = Screen('Flip', win);
    
    % Release texture:
    Screen('Close', tex);
    % end;
end

% Update display:
vbl = Screen('Flip', win);

% Stop playback:
Screen('PlayMovie', movie, 0);

% Close movie:
Screen('CloseMovie', movie);
end