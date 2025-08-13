function [] = checkESC()

    
  [pressed, timeVector] = KbQueueCheck; 
    
if pressed
    indices = find(timeVector); % find > 0, i.e. responses
    [~, i]  = sort(timeVector(indices)); % sort by time
    KEYvec  = indices(i); % key codes, sort ascending by time
    if ismember(KbName('ESCAPE'), KEYvec) % stop experiment if ESC is pressed
           sca; end
end
end