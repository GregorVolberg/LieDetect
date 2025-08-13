function [] = run04_spotlight_and_topoplot()

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

performance = importdata([RESULTSDIR,'classificationperformance.mat']);

%% cfg
cfgclassify = [];

%% timing
postmarker   = 0.4; % 0.4s post response
tsteps       = [0.8, 0.6, 0.4, 0.2];
[~, idx]     = max(performance, [], 2);
target_time  = tsteps(idx);

topo_participant = nan(62, numel(filelist));

rng(22);
%% loop over participants and channels
for k = 1:numel(filelist) 
    [dat, clabels, Fs, chans, nb] = get_dat_and_clabels(filelist{k});

    targetTimePoints = [size(dat, 3) - postmarker * Fs - target_time(k) * Fs, ...
                        size(dat, 3) - postmarker * Fs];
    mean_amplitude   = squeeze(mean(dat(:,:, targetTimePoints(1):targetTimePoints(2)),3));
    topo             = nan(size(mean_amplitude, 2), 1);

    for channel = 1:size(mean_amplitude, 2)
        chan_idx   = ismember({nb.label}, chans(channel));
        ngbr_idx   = find(ismember(chans, nb(chan_idx).neighblabel));
        target_idx = find(ismember(chans, chans(channel)));
        X          = mean_amplitude(:, [target_idx, ngbr_idx']);
        performance = mv_classify(cfgclassify, X, clabels);
        topo(channel) = performance;
    end
 topo_participant(:, k) = topo;   
end

mean_accuracy = mean(topo_participant, 2);

%% plot topography
dummy        = importdata(filelist{k});
tl_dummy     = ft_timelockanalysis([], dummy);
tl_dummy.avg = repmat(mean_accuracy, 1, size(tl_dummy.avg, 2));

cfgtopo = [];
cfgtopo.layout     = 'EEG1010.lay';
cfgtopo.parameter  = 'avg';      
cfgtopo.xlim       = [0 0.1];    
cfgtopo.zlim       = [0.45 0.55];
cfgtopo.comment    = 'no';
ft_topoplotER(cfgtopo, tl_dummy);
title('Mean accuracy');

set(gcf, 'Color', 'white');
colorbar;
fig = gcf;
print(fig, [RESULTSDIR,  'LDA_mean_accuracy_topo.svg'],'-dsvg');


%% ==============================
%% subfunction
    function[dat, clabels, Fs, chans, nb] = get_dat_and_clabels(infile)
    tmp        = importdata(infile);
    cfg        = [];
    cfg.trials = ~ismember(tmp.trialinfo.role, 'self');
    tmp        = ft_selectdata(cfg, tmp);
    Fs         = tmp.fsample;
    chans      = tmp.label;

    neighbours  = importdata('easycapM1_neighb.mat');
    actualchans = ismember({neighbours.label}, chans);
    nb          = neighbours(actualchans);


    dat     = [];
    clabels = tmp.trialinfo.class_label_nr; % 1 is lie, 2 is truth
    for trial = 1:numel(tmp.trial)
        dat(trial, :, :) = tmp.trial{trial}; % trial x chan x time
    end
end

end

