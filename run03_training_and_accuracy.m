function [] = run03_training_and_accuracy()

% ft path
ft_path = '../../m-lib/fieldtrip';
addpath(ft_path); ft_defaults;

% MVPA path
mv_path = '../../m-lib/MVPA-Light/startup';
addpath(mv_path); startup_MVPA_Light;

% load files
RESULTSDIR = '../RESULTS/';
filedir    = dir([RESULTSDIR, 'sub-S0*_task-liedetector_segmented_corrected.mat']);
filelist   = fullfile({filedir.folder}', {filedir.name}');

% timing
postmarker   = 0.4; % 0.4s post response
tsteps       = [0.8, 0.6, 0.4, 0.2];
all_performance    = nan(numel(filelist), numel(tsteps));
for k = 1:numel(filelist)
    
    % subfunction
    [dat, clabels, Fs] = get_dat_and_clabels(filelist{k});
       
    % loop across timing steps
    rng(22);
    cfgclassify = [];
    performance        = nan(numel(tsteps),1);
    
    
    for nn = 1:numel(tsteps)
        XX = squeeze(mean(dat(:,:, (end - postmarker * Fs - tsteps(nn) * Fs):(end-postmarker * Fs)), 3));
        performance(nn) = mv_classify(cfgclassify, XX, clabels);
    end

    display(performance);
    [~, indF] = max(performance);
    all_performance(k, :) = performance;

    targetTimePoints = [size(dat, 3) - postmarker * Fs - tsteps(indF) * Fs, ...
                        size(dat, 3) - postmarker * Fs];
    XXX = squeeze(mean(dat(:,:, targetTimePoints(1):targetTimePoints(2)),3));
    
    parm = [];
    parm.reg = 'shrink';
    parm.lambda = 'auto';
    parm.prob = 1;
    parm.scale = 1;
    parm.form  = 'auto';
    trainedLDA = train_lda(parm, XXX, clabels);
    
    [fdir, fname, ~] = fileparts(filelist{k});
    save([fdir, filesep, fname, '_trainedLDA.mat'], 'trainedLDA');
    writematrix(classificationperformance, [fdir, filesep,'classificationperformance.csv']);
end 

save([fdir, filesep,'classificationperformance.mat'], 'all_performance');

%% subfunction
function[dat, clabels, Fs] = get_dat_and_clabels(infile)
    tmp        = importdata(infile);
    cfg        = [];
    cfg.trials = ~ismember(tmp.trialinfo.role, 'self');
    tmp        = ft_selectdata(cfg, tmp);
    Fs         = tmp.fsample;

    dat     = [];
    clabels = tmp.trialinfo.class_label_nr; % 1 is lie, 2 is truth
    for trial = 1:numel(tmp.trial)
        dat(trial, :, :) = tmp.trial{trial}; % trial x chan x time
    end
 end

end
