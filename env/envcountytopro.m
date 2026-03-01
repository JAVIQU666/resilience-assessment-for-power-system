for ppp=1:4
    if ppp == 1
        fn = 'county_disaster_precalc126.mat';
    elseif ppp == 2
        fn = 'county_disaster_precalc245.mat';
    elseif ppp == 3
        fn = 'county_disaster_precalc370.mat';
    elseif ppp == 4
        fn = 'county_disaster_precalc585.mat';
    end

    S = whos('-file', fn);
    mat_vars = {S.name};
    keep_vars = [{'ppp'}, mat_vars];

    load(fn);

    clearvars('-except', keep_vars{:})
    warning off
    num_provinces = 34;
    load('countyinfo.mat');
    CtgProbcold_prov_sum = zeros(num_provinces, 1);
    CtgProbexwind_prov_sum = zeros(num_provinces, 1);
    CtgProbheat_prov_sum = zeros(num_provinces, 1);
    CtgProbtyphoon_prov_sum = zeros(num_provinces, 1);
    CtgProbnormal_prov_sum = zeros(num_provinces, 1);
    CtgProbflood_prov_sum = zeros(num_provinces, 1);

    weightsloadcoldstage_prov_sum = zeros(num_provinces, 3);
    weightsloadexwindstage_prov_sum = zeros(num_provinces, 3);
    weightsloadtyphoonstage_prov_sum = zeros(num_provinces, 3);
    weightsloadfloodstage_prov_sum = zeros(num_provinces, 3);

    numlevel = 3;
    numstage = 6;
    numdisaster = 5;
    ProvDisasterStageLevel = zeros(num_provinces, numdisaster, numlevel, numstage);
    filename = '.\data\countydisasters.csv';
    countrydisaster = readtable(filename);
    %% gen month load of each county  (TWH)
    filename = '.\data\loadcurvehourly2020.csv';
    countydataload = readmatrix(filename, 'Encoding', 'UTF-8');
    countydataload(1,:) = [];
    numcounty = size(countydataload,1);
    load_data = countydataload(:, 3:end);
    days_in_month = [31, 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31];
    hours_in_month = days_in_month * 24;
    monthly_average_load = zeros(size(countydataload,1), 12);
    start_hour = 1;
    for month = 1:12
        end_hour = start_hour + hours_in_month(month) - 1;
        monthly_average_load(:,month) = mean(load_data(:, start_hour:end_hour), 2);
        start_hour = end_hour + 1; 
    end
    monthly_average_load = [countydataload(:,1:2),monthly_average_load];
    monthly_average_load(:,3:end) = monthly_average_load(:,3:end)*1000000; % TWH to MWH
    ProvCountyCounter = zeros(num_provinces, 1);
    for i = 1:numcounty
        temp = 0;
        temptotal = zeros(1,30);
        p = [];
        for row = 1:size(countyinfo, 1)
            current_list = countyinfo{row, 3};
            if ismember(monthly_average_load(i,1), current_list)
                p = row;
                temp = 1;
                break
            end
        end
        if temp == 0
            continue
        end

        %% pinlv
        selectedRows = countrydisaster(countrydisaster{:, 1} == monthly_average_load(i, 1), :);
        selectedRowsheat = selectedRows(selectedRows{:, 2} == "heatwave", :);
        selectedRowscold = selectedRows(selectedRows{:, 2} == "coldwave", :);
        selectedRowstyphoon = selectedRows(selectedRows{:, 2} == "tropical cyclone", :);
        selectedRowsexwind = selectedRows(selectedRows{:, 2} == "extreme wind", :);
        selectedRowsflood = selectedRows(selectedRows{:, 2} == "flood", :);
        %% heat
        fifthColumnData = selectedRowsheat{:, 5};
        count1 = sum(fifthColumnData <= 303 & fifthColumnData >= 300);
        count2 = sum(fifthColumnData > 303 & fifthColumnData <= 307);
        count3 = sum(fifthColumnData > 307);
        if count1+count2+count3 ~= 0
            weightsloadheatstage = [count1,count2,count3]/(count1+count2+count3);
        else
            weightsloadheatstage = [0, 0, 0];
        end

        %% cold
        fifthColumnData = selectedRowscold{:, 5};
        count1 = sum(fifthColumnData > 255 & fifthColumnData <= 260);
        count2 = sum(fifthColumnData > 250 & fifthColumnData <= 255);
        count3 = sum(fifthColumnData <= 250);
        if count1+count2+count3 ~= 0
            weightsloadcoldstage = [count1,count2,count3]/(count1+count2+count3);
        else
            weightsloadcoldstage = [0, 0, 0];
        end

        %% typhoon
        fifthColumnData = selectedRowstyphoon{:, 5};
        count1 = sum(fifthColumnData > 36.2 & fifthColumnData <= 41.6);
        count2 = sum(fifthColumnData > 41.7 & fifthColumnData <= 50.4);
        count3 = sum(fifthColumnData > 50.5);
        if count1+count2+count3 ~= 0
            weightsloadtyphoonstage = [count1,count2,count3]/(count1+count2+count3);
        else
            weightsloadtyphoonstage = [0, 0, 0];
        end
        if p == 10 || p == 13 || p == 14 || p == 16
            weightsloadtyphoonstage = [0, 0, 0];
        end
        %% exwind
        % The provincial-level average is higher than that of the distribution network.
        fifthColumnData = selectedRowsexwind{:, 5};
        count1 = sum(fifthColumnData > 22+2 & fifthColumnData <= 24.5+2);
        count2 = sum(fifthColumnData > 24.5+2 & fifthColumnData <= 29.5+2);
        count3 = sum(fifthColumnData > 29.5+2);
        if count1+count2+count3 ~= 0
            weightsloadexwindstage = [count1,count2,count3]/(count1+count2+count3);
        else
            weightsloadexwindstage = [0, 0, 0];
        end

        %% flood
        fifthColumnData = selectedRowsflood{:, 5};
        count1 = sum(fifthColumnData == 1);
        count2 = sum(fifthColumnData ==1.5);
        count3 = sum(fifthColumnData == 2);
        if count1+count2+count3 ~= 0
            weightsloadfloodstage = [count1,count2,count3]/(count1+count2+count3);
        else
            weightsloadfloodstage = [0, 0, 0];
        end

        for stage = 1:numstage
            res = precalc(monthly_average_load(i,1), stage);
            CtgProbcold    = res.CtgProbcold/365;
            CtgProbexwind  = res.CtgProbexwind/365;
            CtgProbheat    = res.CtgProbheat/365;
            CtgProbtyphoon = res.CtgProbtyphoon/365;
            CtgProbnormal  = res.CtgProbnormal;
            CtgProbflood   = res.CtgProbflood;

            for level = 1:numlevel
                ProvDisasterStageLevel(p, 1, level, stage) = ProvDisasterStageLevel(p, 1, level, stage) + weightsloadheatstage(level) * CtgProbheat;
                ProvDisasterStageLevel(p, 2, level, stage) = ProvDisasterStageLevel(p, 2, level, stage) + weightsloadcoldstage(level) * CtgProbcold;
                ProvDisasterStageLevel(p, 3, level, stage) = ProvDisasterStageLevel(p, 3, level, stage) + weightsloadtyphoonstage(level) * CtgProbtyphoon;
                ProvDisasterStageLevel(p, 4, level, stage) = ProvDisasterStageLevel(p, 4, level, stage) + weightsloadexwindstage(level) * CtgProbexwind;
                ProvDisasterStageLevel(p, 5, level, stage) = ProvDisasterStageLevel(p, 5, level, stage) + weightsloadfloodstage(level) * CtgProbflood;

            end

        end
        ProvCountyCounter(p) = ProvCountyCounter(p) + 1;
    end
    for p = 1:num_provinces
        for disaster = 1:numdisaster
            for level = 1:numlevel
                for stage = 1:numstage
                    if ProvCountyCounter(p) > 0
                        ProvDisasterStageLevel(p, disaster, level, stage) = ...
                            ProvDisasterStageLevel(p, disaster, level, stage) / ProvCountyCounter(p);
                    end
                end
            end
        end
    end
    if ppp == 1
        save('ProvDisasterStageLevel_126.mat', 'ProvDisasterStageLevel');
    elseif ppp == 2
        save('ProvDisasterStageLevel_245.mat', 'ProvDisasterStageLevel');
    elseif ppp == 3
        save('ProvDisasterStageLevel_370.mat', 'ProvDisasterStageLevel');
    elseif ppp == 4
        save('ProvDisasterStageLevel_585.mat', 'ProvDisasterStageLevel');
    end



end