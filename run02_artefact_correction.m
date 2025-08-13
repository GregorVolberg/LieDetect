function [] = run02_artefact_correction()
% python env
pyenv('Version', ...
    'C:\Users\LocalAdmin\Documents\spk\Scripts\python', ...
    'ExecutionMode', 'OutOfProcess');
sp  = py.importlib.import_module('spkit');
%np  = py.importlib.import_module('numpy');

% set ft path
ft_path = '../../m-lib/fieldtrip';
addpath(ft_path); ft_defaults;

% parameters for baseline
postmarker     = 0.4; % 0.4s post response
bsl            = [0 0.2];
hdr.Fs         = 500;

% load files
RESULTSDIR = '../RESULTS/';
filedir    = dir([RESULTSDIR, 'sub-S0*_task-liedetector_segmented.mat']);
filelist   = fullfile({filedir.folder}', {filedir.name}');

for j =1:numel(filelist)
    eeg = importdata(filelist{j});
    disp(sprintf('reading %s\n', filelist{j}));
    
    eeg_artefactcorrected = cell(size(eeg.trial));
    [fpath, fname, fext] = fileparts(filelist{j});
    outfilename = [fpath, filesep, fname, '_corrected', fext];
    
    for trial = 1:numel(eeg.trial)
        tmp = eeg.trial{trial};
        disp(sprintf('processing trial %u out of %u', trial, numel(eeg.trial)));
        X       = py.numpy.array(tmp'); % transpose and make it an nparray. must be samp x chan
        Xf      = sp.filter_X(X, band=[0.5]); % filter
        Xelim   = sp.eeg.ATAR(Xf,verbose=0, OptMode='elim'); % ATAR
        Xc      = double(Xelim)'; % transpose back and make it a matlab array
        reref   = mean(Xc([60, 62],:), 1); % avg mastoids; 60 is TP9, 62 is TP10
        Xcr     = Xc - reref;
        bslvals = mean(Xcr(:, (end - postmarker*hdr.Fs):(end - postmarker*hdr.Fs + bsl(2)*hdr.Fs)), 2);
        Xcrb     = Xcr - bslvals; % baseline correction
        eeg_artefactcorrected{trial} = Xcrb;
    end
    eeg.trial = eeg_artefactcorrected;
    save(outfilename, 'eeg');
end

end