function [key_code, RT] = get_timeOutResponse(FlipTime, timeOut)

    KbQueueFlush(); pressed = 0; % flush queue
    while ~pressed && ((GetSecs - FlipTime) < timeOut)
         [pressed, timeVector] = KbQueueCheck; 
    end
    
if pressed
    indices = find(timeVector); % find > 0, i.e. responses
    [~, i]  = sort(timeVector(indices)); % sort by time
    KEYvec  = indices(i); % key codes, sort ascending by time
    RTvec   = timeVector(indices(i)); % response time relative to last KbFlush, sort ascending by time, 
    key_code = KEYvec(1);
    RT       = RTvec(1) - FlipTime;
        if ismember(KbName('ESCAPE'), KEYvec) % stop experiment if ESC is pressed
           sca; end
elseif ~pressed
    RT = NaN;
    key_code = NaN;
end
end