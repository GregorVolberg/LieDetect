function [] = EEG2bids_S01()
% from https://www.fieldtriptoolbox.org/example/other/bids_eeg/
bidsPath = '../../BIDS/';
rawPath  = '../../BIDS/sourcedata/';

%% per-subject information (modify these)
sub = 'S01';
%age = 20;
%sex = 'f';
capsize = 56;

%% files
eegfilename      = [rawPath, sub, '_Liedetect.vhdr'];
hdr              = ft_read_header(eegfilename);
protocolFileName = [rawPath, 'sub-', sub, '_task-Liedetector.mat'];
protocol         = importdata(protocolFileName);
personal_q_csv   = [rawPath, 'Liedetect_Persönliche_Fragen.csv'];
t                = readtable(personal_q_csv, ReadRowNames=true);
personal_q       = table2array(t(sub, 3:end)); clear t

allElecs         = ft_read_sens('easycap-M1.txt'); % in fieldtrip templates
removeElecs = find(~ismember(allElecs.label, hdr.label));
elecs  = allElecs;
elecs.chanpos(removeElecs,:) = [];
elecs.chantype(removeElecs)  = [];
elecs.chanunit(removeElecs)  = [];
elecs.elecpos(removeElecs,:) = [];
elecs.label(removeElecs)     = [];
elecs.label(63) = {'VEOG'};
elecs.chantype(63) = {'VEOG'};
elecs.chanpos(63,:) = [nan nan nan];
elecs.elecpos(63,:) = [nan nan nan];
elecs.chanunit(63) = elecs.chanunit(62);
elecs.label(64) = {'HEOG'};
elecs.chantype(64) = {'HEOG'};
elecs.chanpos(64,:) = [nan nan nan];
elecs.elecpos(64,:) = [nan nan nan];
elecs.chanunit(64) = elecs.chanunit(62);

%% events and onsets
event = ft_read_event(eegfilename);
event = ft_filter_event(event, 'type', 'Stimulus'); % 234 trials
event = event(ismember({event.value}, {'S 21', 'S 31'})); % keep only 

vpixxOffset_s       = 0.006; % fix offset of 6 ms at ViewPixx
vpixxOffset_samples = vpixxOffset_s / (1/hdr.Fs);

sample   = ([event(:).sample]-vpixxOffset_samples)'; 
onset    = ((sample - 1) * (1/hdr.Fs));
duration = zeros(numel(onset),1) + (1/hdr.Fs);
markerValue    = {event.value}';
markerType     = {event.type}';
cfgtable = table(sample, onset, duration, markerType, markerValue);
protocol.protocol.role      = cellstr(protocol.protocol.role);
protocol.protocol.condition = cellstr(protocol.protocol.condition);
protocol.protocol.feature   = cellstr(protocol.protocol.feature);
% add columns with class labels
lie_idx     = find((ismember(protocol.protocol.gamepick, [1, 3]) & protocol.protocol.keyCode == 54)|...
                   (ismember(protocol.protocol.gamepick, [2, 4]) & protocol.protocol.keyCode == 53));
class_label_nr = nan(size(protocol.protocol,1),1);
class_label_nr(~ismember(protocol.protocol.role, 'self')) = 2; % 2 is truth 
class_label_nr(lie_idx) = 1; % 1 is lie              
class_label     = cellstr(categorical(class_label_nr, 1:2, {'lie', 'truth'}));

personal_q_nr = nan(size(protocol.protocol,1),1);
personal_q_nr(~ismember(protocol.protocol.role, 'self')) = 0; % 2 is truth 
personal_q_nr(ismember(protocol.protocol.role, 'self'))  = personal_q + 1; % 1 is incorrect, 2 is correct
personal_q_label = cellstr(categorical(personal_q_nr, 1:2, {'incorrect', 'correct'}));
cl_lab = table(class_label, class_label_nr, personal_q_nr, personal_q_label);

alltable = [cfgtable, protocol.protocol, cl_lab]; % added information from stimulus protocol file


%% standard cfg for data2bids
cfg = [];
cfg.method    = 'copy';
cfg.suffix    = 'eeg';
cfg.dataset   = eegfilename;
cfg.bidsroot  = bidsPath;
cfg.sub       = sub;
cfg.scans.acq_time = datetime(protocol.date, 'Format', 'yyyy-MM-dd''T''HH:mm:ss''Z'''); % convert to RFC 3339, UTC+0

cfg.InstitutionName             = 'University of Regensburg';
cfg.InstitutionalDepartmentName = 'Institute for Psychology';
cfg.InstitutionAddress          = 'Universitaetsstrasse 31, 93053 Regensburg, Germany';
cfg.Manufacturer                = 'Brain Products GmbH, Gilching, Germany';
cfg.ManufacturersModelName      = 'BrainAmp MR plus';
cfg.dataset_description.Name    = 'Lie Detector';
cfg.dataset_description.Authors = {'Gregor Volberg', 'Susanne Gonzalez', 'Anna Weitzer', 'Janina Stegmüller'};

cfg.TaskName        = 'liedetector';
cfg.TaskDescription = 'Participants took roles as an offender or attestor in a game and responded correctly or incorrectly (lie) to statements regarding a crime. A classifier was trained on the data with the instructed lies and applied to a set of personal statements where participants could freely choose to lie or tell the truth.';

cfg.eeg.PowerLineFrequency = 50;   
cfg.eeg.EEGReference       = 'FCz';
cfg.eeg.EEGGround          = 'AFz'; 
cfg.eeg.CapManufacturer    = 'EasyCap'; 
cfg.eeg.CapManufacturersModelName = 'M1'; 
cfg.eeg.EEGChannelCount    = 62;
cfg.eeg.EOGChannelCount    = 2; 
cfg.eeg.RecordingType      = 'continuous';
cfg.eeg.EEGPlacementScheme = '10-10';
cfg.eeg.SoftwareFilters    = 'n/a';
cfg.eeg.HeadCircumference  = capsize; 

cfg.elec                   = elecs;
cfg.coordsystem.EEGCoordinateSystem = 'CapTrak'; % RAS orientation
cfg.coordsystem.EEGCoordinateUnits  = 'mm';

%% these do not work
%cfg.channels.low_cutoff    = 0.1;
%cfg.channels.high_cutoff    = 1000;
%cfg.electrodes.type        = 'ring';
%cfg.electrodes.material    = 'Ag/AgCl'; 

%%
%alltable.truth    = cellstr(alltable.truth);
%alltable.language = cellstr(alltable.language);
%alltable.visual   = cellstr(alltable.visual);
cfg.events = alltable;%cfgevt.event;

data2bids(cfg);
end