% =======================
% function[] = liedetect_experiment()
% ========================

%%  
function[] = liedetect_experiment()

clear all
testrun =0;
if testrun
    timeOut = 1;
else
    timeOut = inf;
end

% set up paths, responses, monitor, ...
addpath('./func'); 
%stimpath = '../stim/';
[vp, msgmapping, responseHand, ~, self, instruct_wo_Tasten] = get_experimentInfo();

computerName = getenv('COMPUTERNAME');
switch computerName
    case 'PC1012101290'
    MonitorSelection = 3;        
end
MonitorSelection = 6; % 6 in EEG, 3 in Gregor's office, 4 home office
MonitorSpecs = getMonitorSpecs(MonitorSelection); % subfunction, gets specification for monitor

%% PTB         
AssertOpenGL;
Screen('Preference', 'SkipSyncTests', 1); % Sync test will not work with Windows 10
Screen('Preference', 'TextRenderer', 1); 
PsychImaging('PrepareConfiguration');
PsychImaging('AddTask', 'General', 'FloatingPoint32BitIfPossible');
PsychImaging('FinalizeConfiguration');    

%% prepare ViewPixx marker write-out
topLeftPixel = [0 0 1 1];
VpixxMarkerZero = @(windowPointer) Screen('FillRect', windowPointer, [0 0 0], [0 0 1 1]); % viewpixx 
setVpixxMarker  = @(windowPointer, value) Screen('FillRect', windowPointer, [value 0 0], [0 0 1 1]); % viewpixx 

%% Response buttons
rkeys    = {'y', 'x', 'n', 'm'};
numkeys  = {'1!', '2@', '3#', '4$', '5%'};
KbName('UnifyKeyNames');
ZahlenCodes = KbName(numkeys);
TastenCodes    = KbName({[numkeys], 'ESCAPE'}); % numbers and ESC
NumberVector   = zeros(1,256); NumberVector(TastenCodes) = 1;
TastenCodes    = KbName({[rkeys], 'ESCAPE'}); % response keys and ESC
ResponseVector = zeros(1,256); ResponseVector(TastenCodes) = 1;

%% stimulus size
centCircleSize  = 0.05; % Size of central fixation dot
centCirclePixel = centCircleSize * MonitorSpecs.PixelsPerDegree;
textSize = 30;
targetRect = [0 0 80 80];
vspacing = 15;
yTargetPositions = [1:12]*(targetRect(3)+vspacing);

%% presentation parameters
ISI                = [1.5 2.5]; % in seconds
ISI2               = [4.5 5.5]; % ISI for second section of experiment
LampOn             = 3; % if lie was detected, turn on lamp for LampOn seconds
StimulusTime       = 1;  % seconds
BreakBetweenBlocks = 10; % in seconds
nblocks            = 2;  % number of blocks 
ntrials = 10;

%% stimuli
[places, characters, weapons, character_itemscell, weapon_itemscell, place_items, ~] = get_crime_stimuli_and_items();
allChoices     = {places.png, characters.png, weapons.png}; % randomize order?
folders        = {'./stim/places/', './stim/characters/', './stim/weapons/'};
rnd            = importdata('./stim/preshuffled_conditions.mat');
 
[tmpim, ~, tmpalpha] = imread('./stim/interrogation.png');
    if ~isempty(tmpalpha)
    tmpim(:,:,4) = tmpalpha; % add alpha channel
    end
interrogation = tmpim; clear tmpim

%% stimulus positions
tPos = cell(1, numel(allChoices));
for ch = 1:numel(allChoices)
    for item = 1:numel(allChoices{ch})
    [tmpim, ~, tmpalpha] = imread([folders{ch}, allChoices{ch}{item}]);
    if ~isempty(tmpalpha)
    tmpim(:,:,4) = tmpalpha; % add alpha channel
    end
    im{ch, item} = tmpim;
    end
    xTargetPositions =  [1:numel(allChoices{ch})]*targetRect(3)*2;
    tPos{ch} = CenterRectOnPoint(targetRect, xTargetPositions', ...
                             repmat(yTargetPositions((ch-1)*2+2), 1, numel(xTargetPositions))');
end
tPosPicked = CenterRectOnPoint(targetRect, [[1:numel(allChoices)]*targetRect(3)*2]', ...
                             repmat(yTargetPositions(9), 1, numel(allChoices))');


%% condition list
condition  = char([repmat({'place'}, 1, numel(places.png)), ...
                   repmat({'character'}, 1, numel(characters.png)), ... 
                   repmat({'weapon'}, 1, numel(weapons.png)), ...
                   repmat({'self'}, 1, numel(self.text))]');
featureC   = char([places.con, characters.con, weapons.con, self.con]);
picked(1)  = Sample(1:numel(places.png)); % place is drawn

%% messages
msgStart  = 'Bitte warte, bis die Untersucherin die EEG-Aufnahme gestartet hat.\n\n Das Experiment beginnt bald.';
msgEnd    = '--- Ende des Experiments ---\n\nBitte warte, bis die EEG-Aufnahme gestoppt wurde.';
msgBreak  = 'Ruhe dich aus (10 s)';
msgInstruct1 = ['Der Mord hat ', places.text{picked(1)}, ' stattgefunden.\n'];
msgInstruct2 = 'Wähle deinen Character (Zahl 1 bis 4):\n';
msgInstruct3 = 'Wähle deinen Gegenstand (Zahl 1 bis 4):\n';
msgPicked1   = 'Dein Ort, Character und Gegenstand:\n';
msgPicked2   = 'Starte das Spiel mit einer Antworttaste!\n';
msgChoose = {msgInstruct1, msgInstruct2, msgInstruct3};

msgPicked1_2   = 'Anderer Character und Gegenstand:\n';


%% results file
liedetect      = [];
timeString  = datestr(clock,30);
outfilename = ['sub-', vp, '_task-lieDetector.mat'];

try
    Priority(1);
    %[win, MonitorDimension] = Screen('OpenWindow', MonitorSpecs.ScreenNumber, 127, [0 0 1920/2 1080/2]); 
    [win, MonitorDimension] = Screen('OpenWindow', MonitorSpecs.ScreenNumber, 127); 
    HideCursor(MonitorSpecs.ScreenNumber);
    Screen('BlendFunction', win, GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);
    Screen('TextSize', win, 18);
    if isfield(MonitorSpecs, 'gammaTable')
        Screen('LoadNormalizedGammaTable', win, MonitorSpecs.gammaTable); % correct gamma
    end   
    [xCenter, yCenter] = RectCenter(MonitorDimension);
    hz = Screen('NominalFrameRate', win);
    frame_s = (1/hz);
        
    %% prepare blocks, images, and textures
    % compute fliptime for target
    PTBStimulusTime = StimulusTime - (frame_s * 0.5);

    % Construct and start response queue
    KbQueueCreate([],ResponseVector);
    KbQueueStart;
     
    % show startup screen and wait for key press (investigator)
    KbQueueFlush;        
    Screen('TextSize', win, textSize);
    DrawFormattedText(win, msgStart, 'center', 'center', [255 255 255]);
    VpixxMarkerZero(win);
    Screen('Flip', win);
    KbQueueWait();
    
    % show startup screen and wait for key press (participant)
    KbQueueFlush;        
    Screen('TextSize', win, textSize);
    DrawFormattedText(win, msgmapping, 'center', 'center', [255 255 255]);
    VpixxMarkerZero(win);
    Screen('Flip', win);
    KbQueueWait();
    
    interrogation_pos = CenterRectOnPoint(targetRect*4, xCenter, yCenter/2);

    KbQueueStop;

    % show blank for smooth transition to next page
    VpixxMarkerZero(win);
    Screen('Flip', win);
       
    % results table
    fullTable = [];
        KbQueueCreate([], NumberVector);
        KbQueueStart;
        KbEventFlush();

        Screen('TextSize', win, textSize);
        k=1;
        DrawFormattedText(win, msgChoose{k}, targetRect(3), yTargetPositions((k-1)*2+1)+targetRect(3)/2, [255 255 255]);
        texturePlace = Screen('MakeTexture', win, im{k, picked(1)});
        Screen('DrawTextures', win, texturePlace,[], tPos{k}(1,:)'); 

        %% choose character and weapon
        for k = 2:3
        numberOfStimuli = sum(~cellfun(@isempty, im(k, :)));
        texture = double(numberOfStimuli);
            for m = 1:numberOfStimuli
            texture(k, m) = Screen('MakeTexture', win, im{k, m});
            end
        Screen('TextSize', win, textSize);
        DrawFormattedText(win, msgChoose{k}, targetRect(3), yTargetPositions((k-1)*2+1)+targetRect(3)/2, [255 255 255]);
        Screen('DrawTextures', win, texture(k, :),[], tPos{k}');  
        KbQueueFlush;    
        t0 = Screen('Flip', win, [], 1);
            keyCode = 0;
            while ~ismember(keyCode, ZahlenCodes(1:numberOfStimuli))
            [keyCode, ~] = get_timeOutResponse(t0, timeOut);
            end
        picked(k) = find(ismember(ZahlenCodes, keyCode));
        end
        KbQueueStop;

    

        
   %% loop over blocks
    protocol = [];
    for nblock = 1:nblocks
WaitSecs(0.5);
Screen('Flip', win, 127);
    %% select other character and weapon
    picked2(1) = Sample(setdiff(1:numel(characters.png), picked(2))); % character is drawn
    picked2(2) = Sample(setdiff(1:numel(weapons.png), picked(3))); % weapon is drawn
    

        if mod(nblock, 2) == 1
            roleC.text = 'Täter';
            roleC.con  = 'offender';
            roleC.instruction = 'Täter ... \n\n- Lügen bei Fragen zur Tat\n\n- Sagen die Wahrheit bei Fragen zu ihrer Person';
            character_items = character_itemscell{1};
            weapon_items = weapon_itemscell{1};
        elseif mod(nblock, 2) == 0
            roleC.text = 'Zeuge';
            roleC.con  = 'attestor';
            roleC.instruction = 'Zeugen ... \n\n- Sagen die Wahrheit bei Fragen zur Tat\n\n- Lügen bei Fragen zu ihrer Person';
            character_items = character_itemscell{2};
            weapon_items = weapon_itemscell{2};
        end

        %% show chosen character, place, weapon
        % Construct and start new response queue
        KbQueueCreate([], ResponseVector);
        KbQueueStart;
    
        DrawFormattedText(win, msgPicked1, targetRect(3), yTargetPositions(8)+targetRect(3)/2, [255 255 255]);
        for n = 1:3
            tex = Screen('MakeTexture', win, im{n, picked(n)});
            Screen('DrawTexture', win, tex,[], tPosPicked(n,:));  
        end

        DrawFormattedText(win, msgPicked1_2, targetRect(3)+xCenter, yTargetPositions(8)+targetRect(3)/2, [255 255 255]);
        for n = 2:3
            tex = Screen('MakeTexture', win, im{n, picked2(n-1)});
            Screen('DrawTexture', win, tex,[], OffsetRect(tPosPicked(n-1,:), xCenter, 0));  
        end

        txtblock = ['Deine Rolle in diesem Abschnitt: ', roleC.text, '. '];
        DrawFormattedText(win, txtblock, targetRect(3), yTargetPositions(1)+targetRect(3)/2, [255 255 255]);
        DrawFormattedText(win, roleC.instruction, targetRect(3), yTargetPositions(2)+targetRect(3)/2, [255 255 255]);
        
        DrawFormattedText(win, msgPicked2, targetRect(3), yTargetPositions(6)+targetRect(3)/2, [255 255 255]);
         
        VpixxMarkerZero(win);
        KbQueueFlush;
        Screen('Flip', win);
        KbQueueWait();

        
        %% construct condition matrix
        gamepick = zeros(size(condition,1), 1);
        role    = repmat(roleC.con, numel(gamepick), 1);
        gamepick([picked(1), picked(2) + numel(places.png), ...
                  picked(3) + numel(places.png) + numel(characters.png)])=1;
        gamepick([picked2(1)+ numel(places.png), ...
                  picked2(2) + numel(places.png) + numel(characters.png)])=2;
        
        block = repmat(nblock, numel(gamepick), 1);
        feature_nr = [1:4, 1:4, 1:4, 1:4]';
        item_nr    = [randsample(numel(place_items), 4, false);
                      randsample(numel(character_items), 4, false);
                      randsample(numel(weapon_items),4, false);
                      randsample(numel(self.text),4, false)];
        item_lfdnr = 1:16;
        crime_scene      = repmat(places.con{picked(1)}, 16, 1);
        T = table(block, role, condition, gamepick, crime_scene, feature_nr, featureC, item_nr);
        T = renamevars(T, "featureC", "feature");
        T(1:4,:) = []; % remove places
        T.gamepick(ismember(T.condition, {'self'})) = 3;
        T2 = T(ismember(T.condition, {'self'}),:);
        T2.gamepick(ismember(T2.condition, {'self'})) = 4;
        TT = [T;T2];
        %TT.condition(TT.gamepick == 3,:) = 'self_corr'
        T = TT(TT.gamepick ~= 0,:);
        T = [T(1:4,:); T];
        T = [T, table(item_lfdnr')];
        itemnr_c = randsample(numel(character_items), 4, false);
        itemnr_w = randsample(numel(weapon_items), 4, false);
        T.item_nr(1:2:7) = itemnr_c;
        T.item_nr(2:2:8) = itemnr_w;
        T.item_nr(9:16) = NaN;
        %% prepare text
        for trl = 1:size(T, 1)
            con = deblank(T.condition(trl,:));
            switch con
                case 'character'
                   items{trl} = strrep(char(character_items(T.item_nr(trl))), '#', char(characters.text(T.feature_nr(trl))));
                case 'weapon'
                   items{trl} = strrep(char(weapon_items(T.item_nr(trl))), '#', char(weapons.text(T.feature_nr(trl))));
                case 'self'
                    if (T.gamepick(trl) == 3) & strncmp(deblank(T.feature(trl,:)), 'handeness', 10)
                       items{trl} =  self.text{1};
                    elseif (T.gamepick(trl) == 3) & strncmp(deblank(T.feature(trl,:)), 'age', 10)
                       items{trl} =  self.text{2};
                    elseif (T.gamepick(trl) == 3) & strncmp(deblank(T.feature(trl,:)), 'body_height', 10)
                       items{trl} =  self.text{3};
                    elseif (T.gamepick(trl) == 3) & strncmp(deblank(T.feature(trl,:)), 'eye_color', 10)
                       items{trl} =  self.text{4};
                    end

                    if (T.gamepick(trl) == 4) & strncmp(deblank(T.feature(trl,:)), 'handeness', 10)
                       f_hand = self.hand_choose{setdiff(1:numel(self.hand_choose), self.pick{1})}
                        items{trl} =  ['Bist du ', f_hand, '?'];
                    elseif (T.gamepick(trl) == 4) & strncmp(deblank(T.feature(trl,:)), 'age', 10)
                       f_age = self.pick{2} + randsample([-1,1],1) * randsample(1:4,1);
                        items{trl} =  ['Bist du ', num2str(f_age), ' Jahre alt?'];
                    elseif (T.gamepick(trl) == 4) & strncmp(deblank(T.feature(trl,:)), 'body_height', 10)
                       f_height = self.pick{3} + randsample([-1,1],1) * randsample(5:10,1);
                        items{trl} =  ['Bist du ', num2str(f_height), ' cm groß?'];
                    elseif (T.gamepick(trl) == 4) & strncmp(deblank(T.feature(trl,:)), 'eye_color', 10)
                       f_auge = randsample(self.auge_choose(setdiff(1:numel(self.auge_choose), self.pick{4})),1);
                       items{trl} =  ['Hast du ', char(f_auge), 'e Augen?'];                       ;
                    end
            end
        end

        %items  = items';
        tmpconmat = [T items'];
        tmpconmat = renamevars(tmpconmat, ["Var1", "Var10"], ["lfdnr", "item_text"]);
        tmpconmat = repmat(tmpconmat, 3, 1);
        
        consnumeric = single(size(tmpconmat, 1));
        consnumeric(ismember(tmpconmat.condition, {'character'})) = 1;
        consnumeric(ismember(tmpconmat.condition, {'weapon'})) = 2;
        consnumeric(ismember(tmpconmat.condition, {'self'}) & ismember(tmpconmat.gamepick, 3)) = 3;
        consnumeric(ismember(tmpconmat.condition, {'self'}) & ismember(tmpconmat.gamepick, 4)) = 4;

%         rnd_without_repetitions1 = [1 1]; % dummy repetition
%         while any(diff(rnd_without_repetitions1)==0)
%             [rnd_without_repetitions1, rnd1] = Shuffle(consnumeric);
%         end
%         rnd_without_repetitions2 = [1 1]; % dummy repetition
%         while any(diff(rnd_without_repetitions2)==0)
%             [rnd_without_repetitions2, rnd2] = Shuffle(consnumeric);
%         end

        rndnum = Sample(1:numel(rnd.rnd1));
        rnd_without_repetitions1 = rnd.rnd1{rndnum};
        rnd_without_repetitions2 = rnd.rnd2{rndnum};
        if mod(nblock, 2) == 1
        conmat = tmpconmat(rnd_without_repetitions1,:);
        elseif mod(nblock, 2) == 0
        conmat = tmpconmat(rnd_without_repetitions2,:); % use the same items in attestor condition
        conmat.block = repmat(nblock, numel(conmat.block),1);
        conmat.role  = repmat('attestor', size(conmat.role, 1),1);
        end

        

        % clear protocolMatrix     
        protocolTable = [];
        
        % prepare FixcrossWin
        FixCrossWin = Screen('OpenOffscreenWindow', win, 127);
        Screen('gluDisk', FixCrossWin, [0 0 0], xCenter, yCenter, centCirclePixel);
        for n = 1:3
            tex = Screen('MakeTexture', win, im{n, picked(n)});
            Screen('DrawTexture', FixCrossWin, tex,[], tPosPicked(n,:));  
        end
        tex2 = Screen('MakeTexture', win, interrogation);
        Screen('DrawTexture', FixCrossWin, tex2,[], interrogation_pos);  
        VpixxMarkerZero(FixCrossWin);
        
        % prepare QuestionWin
        QuestionWin = Screen('OpenOffscreenWindow', win, 127);
        for n = 1:3
            tex = Screen('MakeTexture', win, im{n, picked(n)});
            Screen('DrawTexture', QuestionWin, tex,[], tPosPicked(n,:));  
        end
        Screen('DrawTexture', QuestionWin, tex2,[], interrogation_pos);  
        
        %% loop over trials    
        for ntrial = 1:ntrials %size(conmat, 1)


           


            % check if ESC is pressed and stop if yes
            checkESC;

            % draw and show fixation
            Screen('DrawTexture', win, FixCrossWin);
            [FixationStart] = Screen('Flip', win);
 
            % prepare and show text
            Screen('DrawTexture', win, QuestionWin);
            DrawFormattedText(win, conmat.item_text{ntrial}, 'center', 'center', [255 255 255]);
%            setVpixxMarker(win, 1);
            KbQueueFlush;
            [TargetStart] = Screen('Flip', win, FixationStart + ISI(1) + (ISI(2)-ISI(1)).*rand(1)); % random uniform in ISI interval
            
            % get reponse
            [empkeyCode, RT] = get_timeOutResponse(TargetStart, timeOut);
            
            % after keypress, wait for 0.5 sec
            WaitSecs(0.5);

            % compute presentation timesempkey
            kCode(ntrial) = empkeyCode;
            rtime(ntrial) = RT;

           % for feedback
           % 89 is for 'yes', 88 is for 'no' - response
           % 53 is for 'yes', 54 is for 'no'
           if all(deblank(conmat.role(ntrial,:)) == 'offender')
               if (conmat.gamepick(ntrial) == 1) & (empkeyCode == 54) 
                   feedb = {'Gut! Täter lügen über die Tat.'}; feedbcolor = [0 255 0];
               elseif (conmat.gamepick(ntrial) == 1) & (empkeyCode == 53) 
                   feedb = {'Schlecht! Täter lügen über die Tat.'}; feedbcolor = [255 0 0];
               elseif (conmat.gamepick(ntrial) == 2) & (empkeyCode == 53) 
                   feedb = {'Gut! Täter lügen über die Tat.'};feedbcolor = [0 255 0];
               elseif (conmat.gamepick(ntrial) == 2) & (empkeyCode == 54) 
                   feedb = {'Schlecht! Täter lügen über die Tat.'}; feedbcolor = [255 0 0];
               elseif (conmat.gamepick(ntrial) == 3) & (empkeyCode == 53) 
                   feedb = {'Gut! Täter sagen die Wahrheit bei Fragen zu ihrer Person.'};feedbcolor = [0 255 0];
               elseif (conmat.gamepick(ntrial) == 3) & (empkeyCode == 54) 
                   feedb = {'Schlecht! Täter sagen die Wahrheit bei Fragen zu ihrer Person.'}; feedbcolor = [255 0 0];
               elseif (conmat.gamepick(ntrial) == 4) & (empkeyCode == 53) 
                   feedb = {'Schlecht! Täter sagen die Wahrheit bei Fragen zu ihrer Person.'}; feedbcolor = [255 0 0];
               elseif (conmat.gamepick(ntrial) == 4) & (empkeyCode == 54) 
                   feedb = {'Gut! Täter sagen die Wahrheit bei Fragen zu ihrer Person.'};feedbcolor = [0 255 0];
               end
           elseif all(deblank(conmat.role(ntrial,:)) == 'attestor')
               if (conmat.gamepick(ntrial) == 1) & (empkeyCode == 53) 
                   feedb = {'Gut! Zeugen sagen die Wahrheit über die Tat.'};feedbcolor = [0 255 0];
               elseif (conmat.gamepick(ntrial) == 1) & (empkeyCode == 54) 
                   feedb = {'Schlecht! Zeugen sagen die Wahrheit über die Tat.'}; feedbcolor = [255 0 0];
               elseif (conmat.gamepick(ntrial) == 2) & (empkeyCode == 53) 
                   feedb = {'Schlecht! Zeugen sagen die Wahrheit über die Tat.'}; feedbcolor = [255 0 0];
               elseif (conmat.gamepick(ntrial) == 2) & (empkeyCode == 54) 
                   feedb = {'Gut! Zeugen sagen die Wahrheit über die Tat.'};feedbcolor = [0 255 0];
               elseif (conmat.gamepick(ntrial) == 3) & (empkeyCode == 53) 
                   feedb = {'Schlecht! Zeugen lügen bei Fragen zu ihrer Person.'}; feedbcolor = [255 0 0];
               elseif (conmat.gamepick(ntrial) == 3) & (empkeyCode == 54) 
                   feedb = {'Gut! Zeugen lügen bei Fragen zu ihrer Person.'};feedbcolor = [0 255 0];
               elseif (conmat.gamepick(ntrial) == 4) & (empkeyCode == 53) 
                   feedb = {'Gut! Zeugen lügen bei Fragen zu ihrer Person.'};feedbcolor = [0 255 0];
               elseif (conmat.gamepick(ntrial) == 4) & (empkeyCode == 54) 
                   feedb = {'Schlecht! Zeugen lügen bei Fragen zu ihrer Person.'}; feedbcolor = [255 0 0];
               end
           end
        DrawFormattedText(win, feedb{1}, 'center', 'center', feedbcolor);
        Screen('Flip', win, TargetStart + RT + 0.5); % random uniform in ISI interval
WaitSecs(2);
        end
        
            %end
            
            
  

        % copy all trial information into one table
        %kCode = table(kCode', 'VariableNames', {'keyCode'});
        %rtime = table(rtime', 'VariableNames', {'rtime'});
        %protocolTable = [conmat, kCode, rtime];
        
        % unsuspicious = sum(kCode.keyCode(ismember(conmat.gamepick,  [1 4])) == KbName(rkeys(2))) + ...
        %                sum(kCode.keyCode(ismember(conmat.gamepick,  [2 3])) == KbName(rkeys(1)));    
        % fraction_false = 1-(round(unsuspicious / size(conmat,1), 2));
        % if fraction_false < 0.1
        % msg = 'Gut gemacht, du bist unverdächtig.';
        % else
        % msg = 'Du hast dich durch widersprüchliche Aussagen verdächtig gemacht.';
        % end
        % clear kCode rtime

        % write protocol table 
        %fullTable = [fullTable; protocolTable];
        %clear protocolTable
        
        % show blank screen
        VpixxMarkerZero(win);
        Screen('Flip', win);

            % show break message
            WaitSecs(2);
            %if nblock < nblocks
                Screen('TextSize', win, textSize);
                %DrawFormattedText(win, msg, 'center', yCenter/4, [255 255 255]);
                DrawFormattedText(win, msgBreak, 'center', 'center', [255 255 255]);
                %DrawFormattedText(win, instruct_wo_Tasten, 'center', yCenter*6/4, [255 255 255]);
                VpixxMarkerZero(win);
                Screen('Flip', win);
                WaitSecs(BreakBetweenBlocks);
            %end
            % 
        WaitSecs(1);
        KbQueueStop;

    end  % end blocks
    %% personal lie items
% msgAbschnitt2 = 'Nun beginnt der zweite Abschnitt des Experiments.\n\nBeantworte alle Fragen mit ''korrekt'' oder ''nicht korrekt''.\n\n';
% DrawFormattedText(win, msgAbschnitt2, 'center', yCenter/4, [255 255 255]);
% DrawFormattedText(win, instruct_wo_Tasten, 'center', yCenter, [255 255 255]);
% 
% KbQueueStart;
% KbQueueFlush;
% Screen('Flip', win);
% KbQueueWait();
% 
% section2_conmat = array2table(NaN(numel(luegenitems), size(conmat, 2)));
% section2_conmat = renamevars(section2_conmat, section2_conmat.Properties.VariableNames, conmat.Properties.VariableNames);
% section2_conmat.lfdnr = randperm(numel(luegenitems))';
% section2_conmat.item_nr = [1:numel(luegenitems)]';
% section2_conmat.item_text = luegenitems;
% section2_conmat.block = repmat(nblocks+1, numel(luegenitems), 1);
% section2_conmat = sortrows(section2_conmat, 'lfdnr'); % random order
% 
% clear kCode rtime
% 
% for lueg_item = 1:size(section2_conmat, 1)
% 
%               % check if ESC is pressed and stop if yes
%             checkESC;
% 
%             % draw and show fixation
%             Screen('gluDisk', win, [0 0 0], xCenter, yCenter, centCirclePixel);
%             VpixxMarkerZero(win);
%             [FixationStart] = Screen('Flip', win);
% 
%            % prepare and show text
%             DrawFormattedText(win, section2_conmat.item_text{lueg_item}, 'center', 'center', [255 255 255]);
%             setVpixxMarker(win, 1);
%             KbQueueFlush;
%             [TargetStart] = Screen('Flip', win, FixationStart + ISI2(1) + (ISI2(2)-ISI2(1)).*rand(1)); % random uniform in ISI interval
% 
%             % get reponse
%             [empkeyCode, RT] = get_timeOutResponse(TargetStart, timeOut);
% 
%             % after keypress, wait for 0.5 sec
%             WaitSecs(0.5);
% 
%             % compute presentation times
%             kCode(lueg_item) = empkeyCode;
%             rtime(lueg_item) = RT;
% 
% 
 %end
% 
% 
% 
%       kCode = table(kCode', 'VariableNames', {'keyCode'});
%       rtime = table(rtime', 'VariableNames', {'rtime'});
% 
%       section2_Table = [section2_conmat, kCode, rtime];
%       section2_Table.role = repmat('self    ', numel(luegenitems),1);
%       section2_Table.condition = repmat('test     ', numel(luegenitems), 1);
%       section2_Table.crime_scene = repmat('none    ', numel(luegenitems), 1);
%       section2_Table.feature = repmat('none        ', numel(luegenitems), 1);
%       fullTable = [fullTable; section2_Table];
% 
% 
% % write results and supplementary information to structure
% liedetect.experiment         = 'task-lieDetection';
% liedetect.participant        = vp;
% liedetect.date               = timeString;
% liedetect.protocol           = fullTable;
% liedetect.response_hand      = responseHand;
% liedetect.yes_key            = KbName('y');
% liedetect.monitor_refresh    = hz;
% liedetect.MonitorDimension   = MonitorDimension;
% 
% save(outfilename, 'liedetect');
% 
% outtable = [fullTable table(repmat(vp, size(fullTable,1),1), 'VariableNames', {'vp'}) ...
%            table(repmat(timeString, size(fullTable,1),1), 'VariableNames', {'time_stamp'}) ...
%            table(repmat(responseHand, size(fullTable,1),1), 'VariableNames', {'response_hand'}) ...
%            table(repmat(KbName('y'), size(fullTable,1),1), 'VariableNames', {'yes_key'})];
% writetable(outtable, [outfilename, '.csv']);

% show ending message
KbQueueFlush; 
Screen('TextSize', win, textSize);
DrawFormattedText(win, msgEnd, 'center', 'center', [255 255 255]);
VpixxMarkerZero(win);
Screen('Flip', win);
KbQueueWait();     

catch
    Screen('CloseAll');
    psychrethrow(psychlasterror);
end
Screen('CloseAll');
end

