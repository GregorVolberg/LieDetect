%% demo polling from pc1012....
% ft_realtime_fileproxy is running on pc1012...
% using Data source X:\Volberg\GraspMI\bids\sourcedata\sub-01....vhdr mit S
% 20 - Markern

% todo:
% - copy code to PTB code and read header, evt, data right after stim
% presenation
% - change location to 'buffer://pc1011407841:1972' for EEG
% - write out the sample (onset) where an event occurred
% - implement "classify" from fieldtrip realtime examples
mv_path = '../../m-lib/MVPA-Light/startup';
addpath(mv_path); startup_MVPA_Light;

terminate(pyenv);
pyenv('Version',...
    '../spkit/bin/python', ...
    'ExecutionMode', 'OutOfProcess');
sp  = py.importlib.import_module('spkit');
np  = py.importlib.import_module('numpy');

bufferOffice = 'buffer://pc1012101290:1972';
bufferEEG    = 'buffer://pc1011407841:1972';
buff = bufferOffice;
onset_sample   = 0;
trialcount     = 0;
premarker      = 1; %1 sec pre
postmarker     = 0.4; % 0.5s post
bsl            = [0 0.2];


while trialcount < 10 %isempty(evt(end).value) | ~sucess
WaitSecs(1);
hdr = ft_read_header(buff);
evt = ft_read_event(buff);
if ~ isempty(evt(end).value) % necessary because "New Segment" event has empty value
sucess = ismember({evt(end).value}, {'S 20'}) & (evt(end).sample > onset_sample(end));
if sucess 
    strt = GetSecs; WaitSecs(postmarker+0.3); % liest daten alle 0.25 sec 
    trialcount = trialcount + 1;
    onset_sample(trialcount) = evt(end).sample;
    val  = evt(end).value;
    stp = GetSecs();
    display([val, '     ', num2str(onset_sample(trialcount)), '   ', num2str(stp-strt)]);
    tmp = ft_read_data(buff, 'begsample', onset_sample(trialcount) - premarker*hdr.Fs, 'endsample', onset_sample(trialcount) + postmarker*hdr.Fs);
    %dat{trialcount} = ft_read_data(buff, 'begsample', onset_sample - 0.5*hdr.Fs, 'endsample', onset_sample);
    tmp(63:64,:) = []; % exclude HEOG and VEOG
X       = py.numpy.array(tmp'); % transpose and make it an nparray. must be samp x chan
Xf      = sp.filter_X(X, band=[0.5]); % filter
Xelim   = sp.eeg.ATAR(Xf,verbose=0, OptMode='elim'); % ATAR
Xc      = double(Xelim)'; % transpose back and make it a matlab array
reref   = mean(Xc([60, 62],:), 1); % avg mastoids; 60 is TP9, 62 is TP10
Xcr     = Xc - reref;
bslvals = mean(Xcr(:, (end - postmarker*hdr.Fs):(end - postmarker*hdr.Fs + bsl(2)*hdr.Fs)), 2);
Xcrb     = Xcr - bslvals; % baseline correction
dat(trialcount, :,:) = Xcrb;
end
end
end

% end of part 1 of experiment
rng(22);
cfg = [];
perf = [];
clabel = Shuffle([zeros(1,5)+1, zeros(1,5)+2]);
% avg across time
tsteps = [0.8, 0.6, 0.4, 0.2];
for nn = 1:numel(tsteps)
    XX = squeeze(mean(dat(:,:, (end - postmarker*hdr.Fs - tsteps(nn)*hdr.Fs):(end-postmarker*hdr.Fs)), 3));
    perf(nn) = mv_classify(cfg, XX, clabel);
end

[~,indF] = max(perf);
targetTimePoints = [size(dat, 3) - postmarker*hdr.Fs - tsteps(indF)*hdr.Fs, ...
                    size(dat, 3) - postmarker*hdr.Fs]
XXX = squeeze(mean(dat(:,:, targetTimePoints(1):targetTimePoints(2)),3));
XXX = repmat(XXX, 10,1); % to avoid error 
clabel1 = repmat(clabel, 1, 10);

parm = [];
parm.reg = 'shrink';
parm.lambda = 'auto';
parm.prob = 1;
parm.scale = 1;
parm.form  = 'auto';
trainedLDA = train_lda(parm, XXX, clabel1);

testtrial = squeeze(mean(dat(1,:, targetTimePoints(1):targetTimePoints(2)),3));
[xlab,~, prob] = test_lda(trainedLDA, testtrial)
