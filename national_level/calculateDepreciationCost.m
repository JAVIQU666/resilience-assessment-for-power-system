function [depreciation_cost] = calculateDepreciationCost(inv, i, n, stage)

period = 5; %

annual_investment = inv * (i / (1 - (1 + i)^-n));

life = min(35-period*stage,n);
incre = 0;
for qq = 1:life
    incre = incre + (1+i)^-qq;
end
depreciation_cost = annual_investment * incre;

end
