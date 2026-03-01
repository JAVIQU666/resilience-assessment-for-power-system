clear;
filename = '.\data\countydisasters.csv';
countrydisaster = readtable(filename);
load('ID_County_CN.mat');      % county_CN [lat, lon]
load('extf_upsampled.mat');    
load('exwind_upsampled.mat');  
load('extemp_upsampled.mat');  
load('scenariosnormal.mat');   
load('mpcdisasters.mat');
load('pr_sorted.mat');
period = [2025 2030 2035 2040 2045 2050];
numstage = length(period);

county_ids = unique(county_CN(:));
county_ids(county_ids==0) = []; 

numcounty = max(county_ids); 

%% gen month load of each county  (TWH)
filename = '.\data\loadcurvehourly2020.csv';
countydataload = readmatrix(filename, 'Encoding', 'UTF-8');
countydataload(1,:) = [];
numcounty = size(countydataload,1);
load_data = countydataload(:, 3:end);

days_in_month = [31, 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31];
hours_in_month = days_in_month * 24; 

monthly_average_load = zeros(size(countydataload,1), 12);
precalc = struct();

for i = 1:numcounty
    county_mask = (county_CN == i);  % [lat, lon] 
    if ~any(county_mask(:)), continue; end 

    for stage = 1:numstage
        
        fcoldlow   = squeeze(extemp_upsampled.ssp126.under_dayslow_all(stage,:,:));
        fcoldmid   = squeeze(extemp_upsampled.ssp126.under_daysmid_all(stage,:,:));
        fcoldhigh  = squeeze(extemp_upsampled.ssp126.under_dayshigh_all(stage,:,:));
        fheatlow   = squeeze(extemp_upsampled.ssp126.exceed_dayslow_all(stage,:,:));
        fheatmid   = squeeze(extemp_upsampled.ssp126.exceed_daysmid_all(stage,:,:));
        fheathigh  = squeeze(extemp_upsampled.ssp126.exceed_dayshigh_all(stage,:,:));
        ftflow     = squeeze(extf_upsampled.ssp126.low(stage,:,:));
        ftfmid     = squeeze(extf_upsampled.ssp126.mid(stage,:,:));
        ftfhigh    = squeeze(extf_upsampled.ssp126.high(stage,:,:));
        fwindlow   = squeeze(exwind_upsampled.ssp126.low(stage,:,:));
        fwindmid   = squeeze(exwind_upsampled.ssp126.mid(stage,:,:));
        fwindhigh  = squeeze(exwind_upsampled.ssp126.high(stage,:,:));

        % weight
        cold   = [mean(fcoldlow(county_mask),'omitnan'), mean(fcoldmid(county_mask),'omitnan'), mean(fcoldhigh(county_mask),'omitnan')];
        heat   = [mean(fheatlow(county_mask),'omitnan'), mean(fheatmid(county_mask),'omitnan'), mean(fheathigh(county_mask),'omitnan')];
        typhoon= [mean(ftflow(county_mask),'omitnan'), mean(ftfmid(county_mask),'omitnan'), mean(ftfhigh(county_mask),'omitnan')];
        exwind = [mean(fwindlow(county_mask),'omitnan'), mean(fwindmid(county_mask),'omitnan'), mean(fwindhigh(county_mask),'omitnan')];

         % weight
        cold_sum = sum(cold); if cold_sum==0, cold_sum=1; end
        cold_wt = cold / cold_sum;
        heat_sum = sum(heat); if heat_sum==0, heat_sum=1; end
        heat_wt = heat / heat_sum;
        typhoon_sum = sum(typhoon); if typhoon_sum==0, typhoon_sum=1; end
        typhoon_wt = typhoon / typhoon_sum;
        exwind_sum = sum(exwind); if exwind_sum==0, exwind_sum=1; end
        exwind_wt = exwind / exwind_sum;

        % prob
        CtgProb = zeros(7,1);
        duration = mpcdisasters.regcount.AverageDuration;
        for scen = 2:7
            slope = mpcdisasters.regcount.CountSlope(scen-1);
            count = mpcdisasters.regcount.Count2017(scen-1);
            ratioyear = 1 + slope*(period(stage)-2017);
            if ratioyear<0
                ratioyear = 0.01;
            end
            CtgProb(scen) = ratioyear*duration(scen-1)/8760;
        end
        CtgProbflood = CtgProb(4);

        % prob
        CtgProbcold    = sum(cold)/24;
        CtgProbexwind  = sum(exwind)/24;
        CtgProbheat    = sum(heat)/24;
        CtgProbtyphoon = sum(typhoon)/24;
        CtgProbnormal  = 1 - (CtgProbcold - CtgProbexwind - CtgProbheat - CtgProbtyphoon)/365 - CtgProbflood;

        % flood
        selectedRows = countrydisaster(countrydisaster{:, 1} == countydataload(i, 1), :);
        selectedRowsflood = selectedRows(selectedRows{:, 2} == "flood", :);
        fifthColumnData = selectedRowsflood{:, 5};
        count1 = sum(fifthColumnData == 1);
        count2 = sum(fifthColumnData == 1.5);
        count3 = sum(fifthColumnData == 2);
        if count1+count2+count3 ~= 0
            weightsloadflood = [count1,count2,count3]/(count1+count2+count3);
        else
            weightsloadflood = [0, 0, 0];
        end
        weightsloadfloodstage = weightsloadflood * pr_sorted(stage);

        % save to structure
        precalc(i, stage).cold_weight    = cold_wt;
        precalc(i, stage).heat_weight    = heat_wt;
        precalc(i, stage).typhoon_weight = typhoon_wt;
        precalc(i, stage).exwind_weight  = exwind_wt;
        precalc(i, stage).fl_weight = weightsloadfloodstage;

        precalc(i, stage).CtgProbcold    = CtgProbcold;
        precalc(i, stage).CtgProbexwind  = CtgProbexwind;
        precalc(i, stage).CtgProbheat    = CtgProbheat;
        precalc(i, stage).CtgProbtyphoon = CtgProbtyphoon;
        precalc(i, stage).CtgProbnormal  = CtgProbnormal;
        precalc(i, stage).CtgProbflood   = CtgProbflood;    
    end

end

save('county_disaster_precalc.mat','precalc','-v7.3');

