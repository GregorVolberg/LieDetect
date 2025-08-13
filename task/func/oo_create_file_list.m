function[out] = create_file_list(stimpath)
tmp  = dir([stimpath, '*.png']);
file_names = {tmp(:).name}';
for k = 1:numel(tmp)
    tmp2 = strsplit(tmp(k).name, '.');
    tmp3 = strsplit(tmp2{1}, '-');
    [a, b, c, d, e, f, g] = deal(tmp3{:}, file_names{k});
    [topic(k), truth{k}, language{k}, example(k), visual{k}, CSS(k), fn{k}] = deal(str2num(a), b, c, str2num(d), e, str2num(f), g);
end

truth(ismember(truth, 't')) = {'true'}; 
truth(ismember(truth, 'f')) = {'fake'};
language(ismember(language, 'lh')) = {'l_high'}; 
language(ismember(language, 'll')) = {'l_low'};
visual(ismember(visual, 'vh')) = {'v_high'}; 
visual(ismember(visual, 'vl')) = {'v_low'};
flist = sortrows(table(topic', char(truth'), char(language'), char(visual'), example', CSS', fn', ...
    'VariableNames',["topic" "truth" "language" "visual" "variant" "CSS" "file_name"]));
save([stimpath, 'stimuli_file_list.mat'], 'flist');
end
% topics
% 1:= Foreign labor in eastern Germany
% 2:= Sewage plants do not filter out pharmaceuticals
% 3:= 3D-printed meat
% 4:= Gene therapy for hemophilia
% 5:= Changes in "Deutschlandticket"
% 6:= Lack of barrier-free conditions

