% pre-Shuffle conditions, take random shuffling
function [] = get_shuffled_conditions()

consnumeric = [1     1     2     2     1     1     2     2     3     3     3     3     4     4     4, ...
     4     1     1     2     2     1     1     2     2     3     3     3     3     4     4, ...
     4     4     1     1     2     2     1     1     2     2     3     3     3     3     4, ...
     4     4     4];
 
for k = 1:50
        rnd_without_repetitions1 = [1 1]; % dummy repetition
        while any(diff(rnd_without_repetitions1)==0)
            [rnd_without_repetitions1, rnd1{k}] = Shuffle(consnumeric);
        end
        rnd_without_repetitions2 = [1 1]; % dummy repetition
        while any(diff(rnd_without_repetitions2)==0)
            [rnd_without_repetitions2, rnd2{k}] = Shuffle(consnumeric);
        end
end        

rnd.rnd1 = rnd1;
rnd.rnd2 = rnd2;
save('./stim/preshuffled_conditions.mat', 'rnd');
end


