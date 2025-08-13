function [] = run00_combine_and_convert_to_BIDS()
% ==========================
% call individual preprocessing scripts as a batch
% ==========================

ftPath   = '../../../m-lib/fieldtrip/'; 
addpath(ftPath); ft_defaults;

filedir  = dir('./preproc/EEG2bids_S0*.m');
filelist = fullfile({filedir.folder}', {filedir.name}');

    for k = 1:numel(filelist)
        run(filelist{k});
    end

end