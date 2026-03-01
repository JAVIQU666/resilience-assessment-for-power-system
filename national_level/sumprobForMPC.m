function prob = sumprobForMPC(countyresultnormal, mpcIndex, probdis)
prob_sum = zeros(6,6);
count = 0;

for i = 1:size(countyresultnormal, 1)

    if countyresultnormal{i, 2} == mpcIndex
        count = count + 1;
        for stage = 1:6
            res = probdis(countyresultnormal{i, 1},stage);
            prob_sum(2,stage) = prob_sum(2,stage) + res.CtgProbcold/365;
            prob_sum(3,stage) = prob_sum(3,stage) + res.CtgProbexwind/365;
            prob_sum(5,stage) = prob_sum(5,stage) + res.CtgProbheat/365;
            prob_sum(6,stage) = prob_sum(6,stage) + res.CtgProbtyphoon/365;
            prob_sum(1,stage) = prob_sum(1,stage) + res.CtgProbnormal;
            prob_sum(4,stage) = prob_sum(4,stage) + res.CtgProbflood;
        end
    end
end

if count > 0
    prob = prob_sum / count;
else
    prob = zeros(6,6);
end
end
