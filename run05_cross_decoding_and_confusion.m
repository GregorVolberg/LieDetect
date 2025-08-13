function [] = run05_cross_decoding_and_confusion()

% ft path
ft_path = '../../m-lib/fieldtrip';
addpath(ft_path); ft_defaults;

% MVPA path
mv_path = '../../m-lib/MVPA-Light/startup';
addpath(mv_path); startup_MVPA_Light;

% % export_fig path
% expf_path = '../../m-lib/export_fig';
% addpath(expf_path); 
% 
% % svg
% svg_path = '../../m-lib/fig2svg/src';
% addpath(svg_path); 


% load files
RESULTSDIR = '../RESULTS/';
RESULTSDIR = ['..', filesep, 'RESULTS', filesep]
filedir    = dir([RESULTSDIR, 'sub-S0*_task-liedetector_segmented_corrected.mat']);
filelist   = fullfile({filedir.folder}', {filedir.name}');
subs       = regexp(filelist, 'sub-S[0-9]+[0-9]+', 'match');
subs       = [subs{:}]';

LDAdir    = dir([RESULTSDIR, 'sub-S0*_task-liedetector_segmented_corrected_trainedLDA.mat']);
LDAlist   = fullfile({LDAdir.folder}', {LDAdir.name}');

performance = importdata([RESULTSDIR,'classificationperformance.mat']);

%% timing
postmarker   = 0.4; % 0.4s post response
tsteps       = [0.8, 0.6, 0.4, 0.2];
[~, idx]     = max(performance, [], 2);
target_time  = tsteps(idx);

%% loop over participants and trials
for k = 1:numel(filelist)
    if (k == 3 | k == 1)
        disp('No data for S01 and S03.')
    else
        [dat, clabels, Fs, ~, ~] = get_dat_and_clabels(filelist{k});
        targetTimePoints = [size(dat, 3) - postmarker * Fs - target_time(k) * Fs, ...
                            size(dat, 3) - postmarker * Fs];
        mean_amplitude   = squeeze(mean(dat(:,:, targetTimePoints(1):targetTimePoints(2)),3));
    
        trained_LDA = importdata(LDAlist{k});
    
        cross_decoding_results = nan(numel(clabels), 4);
        % clabels:  1 is incorrect, 2 is correct
        % xlabel: 1 is lie, 2 is truth
        for trl = 1:numel(clabels)
             [xlabel,~, prob] = test_lda(trained_LDA, squeeze(mean_amplitude(trl,:)));
             if (xlabel == 1 && clabels(trl) == 2) | (xlabel == 2 && clabels(trl) == 1)
                ground_truth = 1;
             elseif (xlabel == 2 && clabels(trl) == 2) | (xlabel == 1 && clabels(trl) == 1)
                 ground_truth = 2;
             end
             cross_decoding_results(trl, :) = [clabels(trl), ground_truth, xlabel, prob];
        end
        CM = confusionmat(cross_decoding_results(:,2), cross_decoding_results(:,3));
        confusionchart(CM, {'lie', 'truth'});
        set(gcf, 'Color', 'white');

        cross_dec = [];
        cross_dec.cross_decoding_results = cross_decoding_results;
        cross_dec.confusion_matrix       = CM;
        [fdir, fname, ~] = fileparts(filelist{k});
        save([fdir, filesep, fname, '_cross_decoding.mat'], 'cross_decoding_results');
        print(gcf, [RESULTSDIR,  subs{k}, '_confusion_matrix.svg'],'-dsvg');
        

    end
end

%% ==============================
%% subfunction
function[dat, clabels, Fs, chans, nb] = get_dat_and_clabels(infile)
    tmp        = importdata(infile);
    cfg        = [];
    cfg.trials = ismember(tmp.trialinfo.role, 'self');
    tmp        = ft_selectdata(cfg, tmp);
    Fs         = tmp.fsample;
    chans      = tmp.label;

    neighbours  = importdata('easycapM1_neighb.mat');
    actualchans = ismember({neighbours.label}, chans);
    nb          = neighbours(actualchans);

    dat     = [];
    clabels = tmp.trialinfo.personal_q_nr; % 1 is incorrect, 2 is correct

    for trial = 1:numel(tmp.trial)
        dat(trial, :, :) = tmp.trial{trial}; % trial x chan x time
    end
end

end
