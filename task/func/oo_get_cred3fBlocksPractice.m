function [blocks] = get_cred3fBlocksPractice(trialmat, nTrials, ncatch, diffCatch, ISI, frame_s)
% randomize order with the constraint that the topic (column 1 of file list) is not repeated in sucessive trials
trialsPerBlock = nTrials;

% randomize trial matrix
targetMatrix = [1:numel(trialmat.topic); trialmat.topic']'; % 6 x 80
tMat = nan(80,2,6);
for k = 1:6
    tMat(:,:,k) = Shuffle(targetMatrix(targetMatrix(:,2) == k, :),2);
end

indices = cell(2,1);
for n = 1:2
        tmp = tMat(((n-1)*2+1):((n-1)*2+1)+1, :, 1:6);
        tmp2 = reshape(shiftdim(tmp, 2), [12, 2]);
goodBlock = 0;
while ~goodBlock
    tmp3 = Shuffle(tmp2, 2); % randomize within blocks
    goodBlock = ~any(diff(tmp3(:,2))==0);
end
indices{n} =  tmp3(:,1)';   
end
allindices = [indices{:}];
randomMat = trialmat(allindices,:);

% get catch trials
nc    =  Sample(ncatch(1):ncatch(2));
goodCatchTrials = 0;
while ~goodCatchTrials
    catchT = sort(randsample(1:size(randomMat,1), nc));
    goodCatchTrials = ~any(diff(catchT) < diffCatch(1) | diff(catchT) > diffCatch(2));
end
cTrials = zeros(size(randomMat, 1), 1);
cTrials(catchT) = 1;

% add catch trials to randomized matrix, move to column 5
randomMat.catch = cTrials;
randomMat = movevars(randomMat, 'catch', 'Before', 6);

% compute frame-exact ISI
actualISI = randsample([ISI(1):frame_s:ISI(2)], size(randomMat,1), true) - frame_s/2; 
randomMat.ISI = actualISI';

blockStart = [1:trialsPerBlock:size(trialmat,1)];
blockStop  = [trialsPerBlock:trialsPerBlock:size(trialmat,1)];

blocks = cell(1,2);
for k = 1:2
blocks{k} = randomMat(blockStart(k):blockStop(k),:);
end
end