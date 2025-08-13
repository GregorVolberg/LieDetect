% see OpenProject Wiki for Details

pyenv('Version', ... 
            'C:\Users\LocalAdmin\Documents\spk\Scripts\python', ... 
            'ExecutionMode','OutOfProcess')

sp = py.importlib.import_module('spkit'); 

EEG   = sp.load_data.eeg_sample_14ch();
Xf    = sp.filter_X(EEG{1}, band=[0.5]);
Xelim = sp.eeg.ATAR(Xf,verbose=0, OptMode='elim');

figure;
subplot(2,1,1);
plot(double(EEG{1})); ylim([-1200 600]);
subplot(2,1,2);
plot(double(Xelim)); ylim([-1200 600]);
