function [] = run01_segmentation()
% =================
% read BIDS eeg data
% remove trials with response time above 8s threshold
% remove VEOG and HEOG
% segment from -1 to 0.4s relative to response
% make data a fieldtrip preprocessing structure 'eeg'
% write 'eeg' to file '../RESULTS/sub-Sxy_task-liedetector_segmented.mat'
% =================

%% paths and files
FTPATH   = '../../m-lib/fieldtrip/'; 
addpath(FTPATH); ft_defaults;

BIDSPATH = '../BIDS/';
RTIME_TRESHOLD = 8; % max 8 seconds rt

%% get subject names
subs = get_subs(BIDSPATH); % subfunction

%% loop over participants
for n = 1:numel(subs)
    eegfilename = [BIDSPATH, subs{n}, '/eeg/', subs{n}, '_task-liedetector_eeg.eeg'];
    evtfilename = [BIDSPATH, subs{n}, '/eeg/', subs{n}, '_task-liedetector_events.tsv'];
    hdr         = ft_read_header(eegfilename);
    evt         = ft_read_tsv(evtfilename);
    
    remove_trials = find(evt.rtime > RTIME_TRESHOLD);
    evt.rtime (remove_trials) = 0;
    
    %% define segments
    cfg = [];
    cfg.dataset             = eegfilename;
    cfg.trialdef.prestim    = 1; 
    cfg.trialdef.poststim   = 0.4 + round(max(evt.rtime));
    cfg.trialfun.markertype = 'Stimulus';
    cfg.trialfun            = 'ft_trialfun_bids';
    cfg = ft_definetrial(cfg);
    
    %% segmenting
    pp  = ft_preprocessing(cfg);
    
    %% redefine segment: set t0 to rtime
    cfg        = [];
    cfg.offset = -round(evt.rtime * hdr.Fs);
    ppredef    = ft_redefinetrial(cfg, pp);
    
    %% select data from -1 to 0.4s
    cfg         = [];
    cfg.trials  = setdiff(1:numel(ppredef.trial), remove_trials);
    cfg.latency = [-1 0.4];
    cfg.channel = {'all', '-VEOG', '-HEOG'};
    eeg         = ft_selectdata(cfg, ppredef);
    clear pp ppredef
    
    save(['..', filesep, 'RESULTS', filesep, subs{n}, '_task-liedetector_segmented.mat'], 'eeg');
end
end

%% subfunctions
function [subs] = get_subs(dirname)
dirs          = dir(dirname);
regexp_dirs   = regexp({dirs([dirs.isdir]).name}', 'sub-S[0-9]+', 'match');
no_match      = cellfun('isempty', regexp_dirs);
subs          = regexp_dirs(~no_match);
subs           = [subs{:}]';
end

