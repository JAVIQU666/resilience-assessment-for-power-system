clc 
clear all
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
    period = [2025 2030 2035 2040 2045 2050];
    numstage = length(period);
    discountrate = 0.03;
    discount = 0;
    huilv = 7;
    drcost_factor   = 0.6;
    vollrate = 1016422.00126486/1015986;
    for i=1:5
        discount = discount + (1+discountrate)^(-i);
    end
    %% cost
    pdc = [166.813042	128.1966289	196.6759024	38.33816561	490.1155182	85.26086886	66.10649876	18.68898049	153.5702265	211.9938369	0	43.22429421	194.2512653	172.4320694	41.61427874	111.8001716	488.5558108	101.41199	0	87.6057043	17.8496309	12.64810843	210.2498065	116.8907941	343.4112896	149.7026849	84.70735697	56.28595486	0	64.44490862	8.440175967	94.78997465	300.2823314	101.0885387];
    %% data loading
    load('Scenariosra2.mat');
    load('Scenariodra2.mat');
    load('Scenariosrat2.mat');
    load('Scenariodrat2.mat');
    load('Scenariosri2.mat');
    load('Scenariodri2.mat');

    load('indexadjested.mat');

    load('countyinfo.mat');
    load('scenariosnormal.mat');
    load('scenariosheat.mat');
    load('scenarioscold.mat');
    load('scenariostyphoon.mat');
    load('scenariosexwind.mat');
    load('scenariosflood.mat');
    load('scenarioscoldnetwork.mat');

    load('ID_County_CN.mat'); % county_CN

    normal = scenariosnormal;
    heat = scenariosheat;
    cold = scenarioscold;
    typhoon = scenariostyphoon;
    wind = scenariosexwind;
    flood = scenariosflood;
    coldnetwork = scenarioscoldnetwork;

    numnormal = size(normal,2);
    numheat = size(heat,2);
    numcold = size(cold,2);
    numtyphoon = size(typhoon,2);
    numwind = size(wind,2);
    numflood = size(flood,2);
    numcoldnetwork = size(coldnetwork,2);
    load('indexpv.mat');

    filename = '.\data\countrygdp2020.csv';
    countrygdp2020 = readmatrix(filename, 'Encoding', 'UTF-8');

    filename = '.\data\countrypvlcoe.csv';
    countrypvlcoe = readmatrix(filename, 'Encoding', 'UTF-8');
    
    filename = '.\data\load_density.csv';
    countryload_density = readmatrix(filename, 'Encoding', 'UTF-8');

    load('loadcurve20to50.mat');
    for item =1:length(loadcurve20to50.CN50)-1
        
        rateload(item) = loadcurve20to50.CN50(item+1)/loadcurve20to50.CN50(1); %总负荷比率
        rateload = round(rateload, 2);

    end

    filename = '.\data\countydisasters.csv';
    countrydisaster = readtable(filename);

    load('mpcdisasters.mat');
    
    indexadjest = reshape(indexadjested,31,5);
    insert_rows = [11, 19, 29];

    
    new_indexadjest = [];

    
    current_row = 1;

    for i = 1:size(indexadjest,1) + length(insert_rows)
        if ismember(i, insert_rows)
            new_indexadjest(i,:) = zeros(1, size(indexadjest,2));
        else
            new_indexadjest(i,:) = indexadjest(current_row,:);
            current_row = current_row + 1;
        end
    end
    indexadjest_avg = mean(new_indexadjest, 2);
    %% gen month load of each county  (TWH)
    filename = '.\data\loadcurvehourly2020.csv';
    countydataload = readmatrix(filename, 'Encoding', 'UTF-8');
    countydataload(1,:) = [];
    numcounty = size(countydataload,1);
    load_data = countydataload(:, 3:end);

    days_in_month = [31, 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31];
    hours_in_month = days_in_month * 24; % 每个月的小时数

    monthly_average_load = zeros(size(countydataload,1), 12);

    start_hour = 1;
    for month = 1:12
        end_hour = start_hour + hours_in_month(month) - 1;
        monthly_average_load(:,month) = mean(load_data(:, start_hour:end_hour), 2);
        start_hour = end_hour + 1; 
    end
    monthly_average_load = [countydataload(:,1:2),monthly_average_load];
    monthly_average_load(:,3:end) = monthly_average_load(:,3:end)*1000000; % TWH to MWH
    countyresultopt = cell(size(monthly_average_load,1),3);
    countyresultoptinfo = cell(size(monthly_average_load,1),32);
    Tgencostnormal = zeros(1,6);
    Trelanormal = zeros(1,6);
    TDRcostnormal = zeros(1,6);
    Trigidcostnormal = zeros(1,6);
    Tdistributecostnormal = zeros(1,6);
    Tbscostnormal = zeros(1,6);
    numno = 0;
    for i=1:numcounty
        temp = 0;

        temptotal = zeros(1,30);
        found_row = [];
        for row = 1:size(countyinfo, 1)
            current_list = countyinfo{row, 3};
            if ismember(monthly_average_load(i,1), current_list)
                found_row = row;
                temp = 1;
                break
            end
        end
        if temp == 0
            numno = numno+1;
            continue
        end
        weightsload = countyinfo{found_row,4};
        weightsload = weightsload/sum(weightsload);
        %weightsnetwork = countyinfo{found_row,5};

        load_densitytotal = countryload_density((find(countryload_density(:,1)==monthly_average_load(i,1))),:);
        load_density_0_01 = ceil(load_densitytotal(3)/10);
        load_density_01_1 = ceil(load_densitytotal(5)/10);
        load_density_1_6 = ceil(load_densitytotal(7)/10);
        load_density_6_15 = ceil(load_densitytotal(9)/10);
        load_density_15_30 = ceil(load_densitytotal(11)/10);
        load_density30 = ceil(load_densitytotal(13)/10);
        load_density80 = ceil(load_densitytotal(15)/10);
        weightsnetwork = [load_density_0_01+0.5*load_density_01_1,
            0.5*load_density_01_1,
            0.7*load_density_1_6+0.3*load_density_6_15,
            0.2*load_density_1_6+0.4*load_density_6_15+0.5*load_density_15_30+0.3*load_density30,
            0.1*load_density_1_6+0.25*load_density_6_15+0.4*load_density_15_30+0.55*load_density30+0.30*load_density80,
            0.05*load_density_6_15+0.1*load_density_15_30+0.15*load_density30+0.70*load_density80];
        weightsnetwork = ceil(weightsnetwork'/0.8)*indexadjest_avg(found_row); 
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
        if found_row == 10 || found_row == 13 || found_row == 14 || found_row == 16
            weightsloadtyphoonstage = [0, 0, 0];
        end
        %% exwind
        fifthColumnData = selectedRowsexwind{:, 5};
        count1 = sum(fifthColumnData > 22 & fifthColumnData <= 24.5);
        count2 = sum(fifthColumnData > 24.5 & fifthColumnData <= 29.5);
        count3 = sum(fifthColumnData > 29.5);
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
        rant = [1,(1-0.03)^5,(1-0.03)^10,(1-0.03)^15,(1-0.03)^20,(1-0.03)^25];

        for stage = 1:numstage
            %% relibility cost
            % numnetwork = rateload(stage)*max(monthly_average_load(i,3:end))/3.9;
            numnetwork = rateload(stage);
            index = find(countrygdp2020(:,1) == monthly_average_load(i,1));
            if ~isempty(index)
                relapercost = countrygdp2020(index, 2)/monthly_average_load(i,2)/10*1.05^(period(stage)-2020);
            else
                relapercost = 100;
            end
            if isnan(relapercost)
                relapercost = 100;
            end
            if ~isempty(index)
                lcoecost = countrypvlcoe(index, 3);
            else
                lcoecost = 50;
            end
            if lcoecost == 0
                lcoecost = 50;
            end
            relapercost = pdc(found_row);
            relapercost = relapercost*vollrate;
            %% 持续时间演化
            res = precalc(monthly_average_load(i,1), stage);  
            % 概率
            CtgProbcold    = res.CtgProbcold/365;
            CtgProbexwind  = res.CtgProbexwind/365;
            CtgProbheat    = res.CtgProbheat/365;
            CtgProbtyphoon = res.CtgProbtyphoon/365;
            CtgProbnormal  = res.CtgProbnormal;
            CtgProbflood   = res.CtgProbflood;
            CtgProbnormal = 1 - CtgProbcold - CtgProbexwind - CtgProbflood - CtgProbheat - CtgProbtyphoon;
            %% normal
            pvtype = indexpv(find(indexpv(:,1)==found_row),2);
            indicespv = find(cell2mat(scenariosra2(1, 1:numnormal)) == pvtype);

            scenarioNames = {'scenariosra2', 'scenariodra2', 'scenariosrat2', 'scenariodrat2', 'scenariosri2', 'scenariodri2'};
            numScenarios = numel(scenarioNames);
            results = cell(numScenarios, 7);
            for j = 1:numScenarios
                scenarioData = eval([scenarioNames{j}, '(9, indicespv)']);
                leng = size(scenarioData, 2);
                results(j, :) = num2cell(calculatemulticost(scenarioData, leng, weightsload, days_in_month));
            end

            gencostnormal(stage) = CtgProbnormal*weightsnetwork*cell2mat(results(:, 1));
            relanormal(stage) = CtgProbnormal*weightsnetwork*cell2mat(results(:, 2));
            DRcostnormal(stage) = CtgProbnormal*weightsnetwork*cell2mat(results(:, 3));
            rigidcostnormal(stage) = CtgProbnormal*weightsnetwork*cell2mat(results(:, 4));
            distributecostbsnormal(stage) = CtgProbnormal*weightsnetwork*cell2mat(results(:, 5));
            distributecostpvnormal(stage) = lcoecost/0.362/1000*CtgProbnormal*weightsnetwork*cell2mat(results(:, 6));
            bscostnormal(stage) = CtgProbnormal*weightsnetwork*cell2mat(results(:, 7));
            gencostnormal(stage) = 0;
            relanormal(stage) = 0;
            DRcostnormal(stage) = 0;
            rigidcostnormal(stage) = 0;
            distributecostbsnormal(stage) = 0;
            distributecostpvnormal(stage) = 0;
            bscostnormal(stage) = 0;
            %% heat
            if CtgProbheat ~= 0
                scenario = scenariosra2(:, numnormal+1:numnormal+numheat);
                indicespv = find(cell2mat(scenario(1,:)) == pvtype)+numnormal;
                for j = 1:numScenarios
                    scenarioData = eval([scenarioNames{j}, '(14, indicespv)']);
                    leng = size(scenarioData, 2);
                    results(j, :) = num2cell(calculatemulticost(scenarioData, leng, weightsloadheatstage, days_in_month));
                end

                gencostheat(stage) = CtgProbheat*weightsnetwork*cell2mat(results(:, 1));
                relaheat(stage) = CtgProbheat*weightsnetwork*cell2mat(results(:, 2));
                DRcostheat(stage) = CtgProbheat*weightsnetwork*cell2mat(results(:, 3));
                rigidcostheat(stage) = weightsnetwork*cell2mat(results(:, 4));
                distributecostbsheat(stage) = weightsnetwork*cell2mat(results(:, 5));
                distributecostpvheat(stage) = lcoecost/0.362/1000*weightsnetwork*cell2mat(results(:, 6));
                bscostheat(stage) = weightsnetwork*cell2mat(results(:, 7));
            else
                gencostheat(stage) = 0;
                relaheat(stage) = 0;
                DRcostheat(stage) = 0;
                rigidcostheat(stage) = 0;
                distributecostbsheat(stage) = 0;
                distributecostpvheat(stage) = 0;
                bscostheat(stage) = 0;
            end
            %% cold
            if CtgProbcold~=0
                scenario = scenariosra2(:, numnormal+numheat+1:numnormal+numheat+numcold);
                indicespv = find(cell2mat(scenario(1,:)) == pvtype)+numnormal+numheat;
                for j = 1:numScenarios
                    scenarioData = eval([scenarioNames{j}, '(14, indicespv)']);
                    leng = size(scenarioData, 2);
                    results(j, :) = num2cell(calculatemulticost(scenarioData, leng, weightsloadcoldstage, days_in_month));
                end

                gencostcold(stage) = CtgProbcold*weightsnetwork*cell2mat(results(:, 1));
                relacold(stage) = CtgProbcold*weightsnetwork*cell2mat(results(:, 2));
                DRcostcold(stage) = CtgProbcold*weightsnetwork*cell2mat(results(:, 3));
                rigidcostcold(stage) = weightsnetwork*cell2mat(results(:, 4));
                distributecostbscold(stage) = weightsnetwork*cell2mat(results(:, 5));
                distributecostpvcold(stage) = lcoecost/0.362/1000*weightsnetwork*cell2mat(results(:, 6));
                bscostcold(stage) = weightsnetwork*cell2mat(results(:, 7));

                %% 2
                if found_row ~= 2 || found_row ~= 9 || found_row ~= 20 || found_row ~= 25 || found_row ~= 28 || found_row ~= 12 || found_row ~= 15 || found_row ~= 18
                    scenario = scenariosra2(:, numnormal+numheat+numcold+numtyphoon+numwind+numflood+1:numnormal+numheat+numcold+numtyphoon+numwind+numflood++numcoldnetwork);
                    indicespv = find(cell2mat(scenario(1,:)) == pvtype)+numnormal+numheat+numcold+numtyphoon+numwind+numflood;
                    for j = 1:numScenarios
                        scenarioData = eval([scenarioNames{j}, '(14, indicespv)']);
                        leng = size(scenarioData, 2);
                        results(j, :) = num2cell(calculatemulticost(scenarioData, leng, weightsloadcoldstage, days_in_month));
                    end

                    gencostcold(stage) = gencostcold(stage) + CtgProbcold*weightsnetwork*cell2mat(results(:, 1));
                    relacold(stage) = relacold(stage) + 2*CtgProbcold*weightsnetwork*cell2mat(results(:, 2));
                    DRcostcold(stage) = DRcostcold(stage) + CtgProbcold*weightsnetwork*cell2mat(results(:, 3));
                    rigidcostcold(stage) = rigidcostcold(stage) + weightsnetwork*cell2mat(results(:, 4));
                    distributecostbscold(stage) = distributecostbscold(stage) + weightsnetwork*cell2mat(results(:, 5));
                    distributecostpvcold(stage) = distributecostpvcold(stage) + lcoecost/0.362/1000*weightsnetwork*cell2mat(results(:, 6));
                    bscostcold(stage) = bscostcold(stage) + weightsnetwork*cell2mat(results(:, 7));
                end
            else
                gencostcold(stage) = 0;
                relacold(stage) = 0;
                DRcostcold(stage) = 0;
                rigidcostcold(stage) = 0;
                distributecostbscold(stage) = 0;
                distributecostpvcold(stage) = 0;
                bscostcold(stage) = 0;
            end
            %% typhoon
            if CtgProbtyphoon ~= 0
                scenario = scenariosra2(:, numnormal+numheat+numcold+1:numnormal+numheat+numcold+numtyphoon);
                indicestyphoon1 = find(ismember(cell2mat(scenario(5,:)), 1))+numnormal+numheat+numcold;
                indicestyphoon2 = find(ismember(cell2mat(scenario(5,:)), 2))+numnormal+numheat+numcold;
                indicestyphoon3 = find(ismember(cell2mat(scenario(5,:)), 3))+numnormal+numheat+numcold;
                for k=1:3
                    for j = 1:numScenarios
                        if k == 1
                            scenarioData = eval([scenarioNames{j}, '(14, indicestyphoon1)']);
                        elseif k == 2
                            scenarioData = eval([scenarioNames{j}, '(14, indicestyphoon2)']);
                        elseif k == 3
                            scenarioData = eval([scenarioNames{j}, '(14, indicestyphoon3)']);
                        end
                        leng = size(scenarioData, 2);
                        results(j, :) = num2cell(calculatemulticost(scenarioData, leng, weightsload, days_in_month));
                    end

                    gencost(k,1) = weightsnetwork*cell2mat(results(:, 1));
                    rela(k,1) = weightsnetwork*cell2mat(results(:, 2));
                    DRcost(k,1) = weightsnetwork*cell2mat(results(:, 3));
                    rigidcost(k,1) = weightsnetwork*cell2mat(results(:, 4));
                    distributecostbs(k,1) = weightsnetwork*cell2mat(results(:, 5));
                    distributecostpv(k,1) = weightsnetwork*cell2mat(results(:, 6));
                    bscost(k,1) = weightsnetwork*cell2mat(results(:, 7));
                end
                gencosttyphoon(stage) = CtgProbtyphoon*weightsloadtyphoonstage*gencost;
                relatyphoon(stage) =  CtgProbtyphoon*weightsloadtyphoonstage*rela;
                DRcosttyphoon(stage) =  CtgProbtyphoon*weightsloadtyphoonstage*DRcost;
                rigidcosttyphoon(stage) =  weightsloadtyphoonstage*rigidcost;
                distributecostbstyphoon(stage) =  weightsloadtyphoonstage*distributecostbs;
                distributecostpvtyphoon(stage) =  lcoecost/0.362/1000*weightsloadtyphoonstage*distributecostpv;
                bscosttyphoon(stage) =  weightsloadtyphoonstage*bscost;
            else
                gencosttyphoon(stage) = 0;
                relatyphoon(stage) =  0;
                DRcosttyphoon(stage) =  0;
                rigidcosttyphoon(stage) =  0;
                distributecostbstyphoon(stage) =  0;
                distributecostpvtyphoon(stage) =  0;
                bscosttyphoon(stage) =  0;
            end
            %% exwind
            if CtgProbexwind~= 0
                scenario = scenariosra2(:, numnormal+numheat+numcold+numtyphoon+1:numnormal+numheat+numcold+numtyphoon+numwind);
                indicesexwind1 = find(ismember(cell2mat(scenario(6,:)), 1))+numnormal+numheat+numcold+numtyphoon;
                indicesexwind2 = find(ismember(cell2mat(scenario(6,:)), 2))+numnormal+numheat+numcold+numtyphoon;
                indicesexwind3 = find(ismember(cell2mat(scenario(6,:)), 3))+numnormal+numheat+numcold+numtyphoon;
                for k=1:3
                    for j = 1:numScenarios
                        if k == 1
                            scenarioData = eval([scenarioNames{j}, '(14, indicesexwind1)']);
                        elseif k == 2
                            scenarioData = eval([scenarioNames{j}, '(14, indicesexwind2)']);
                        elseif k == 3
                            scenarioData = eval([scenarioNames{j}, '(14, indicesexwind3)']);
                        end
                        leng = size(scenarioData, 2);
                        results(j, :) = num2cell(calculatemulticost(scenarioData, leng, weightsload, days_in_month));
                    end

                    gencost(k,1) = weightsnetwork*cell2mat(results(:, 1));
                    rela(k,1) = weightsnetwork*cell2mat(results(:, 2));
                    DRcost(k,1) = weightsnetwork*cell2mat(results(:, 3));
                    rigidcost(k,1) = weightsnetwork*cell2mat(results(:, 4));
                    distributecostbs(k,1) = weightsnetwork*cell2mat(results(:, 5));
                    distributecostpv(k,1) = weightsnetwork*cell2mat(results(:, 6));
                    bscost(k,1) = weightsnetwork*cell2mat(results(:, 7));
                end
                gencostexwind(stage) =  CtgProbexwind*weightsloadexwindstage*gencost;
                relaexwind(stage) =  CtgProbexwind*weightsloadexwindstage*rela;
                DRcostexwind(stage) =  CtgProbexwind*weightsloadexwindstage*DRcost;
                rigidcostexwind(stage) =  weightsloadexwindstage*rigidcost;
                distributecostbsexwind(stage) =  weightsloadexwindstage*distributecostbs;
                distributecostpvexwind(stage) =  lcoecost/0.362/1000*weightsloadexwindstage*distributecostpv;
                bscostexwind(stage) =  weightsloadexwindstage*bscost;
            else
                gencostexwind(stage) =  0;
                relaexwind(stage) =  0;
                DRcostexwind(stage) =  0;
                rigidcostexwind(stage) =  0;
                distributecostbsexwind(stage) =  0;
                distributecostpvexwind(stage) =  0;
                bscostexwind(stage) =  0;
            end
            %% flood
            if CtgProbflood ~= 0
                scenario = scenariosra2(:, numnormal+numheat+numcold+numtyphoon+numwind+1:numnormal+numheat+numcold+numtyphoon+numwind+numflood);
                indicesflood1 = find(ismember(cell2mat(scenario(7,:)), 1))+numnormal+numheat+numcold+numtyphoon+numwind;
                indicesflood2 = find(ismember(cell2mat(scenario(7,:)), 2))+numnormal+numheat+numcold+numtyphoon+numwind;
                indicesflood3 = find(ismember(cell2mat(scenario(7,:)), 3))+numnormal+numheat+numcold+numtyphoon+numwind;
                for k=1:3
                    for j = 1:numScenarios
                        if k == 1
                            scenarioData = eval([scenarioNames{j}, '(14, indicesflood1)']);
                        elseif k == 2
                            scenarioData = eval([scenarioNames{j}, '(14, indicesflood2)']);
                        elseif k == 3
                            scenarioData = eval([scenarioNames{j}, '(14, indicesflood3)']);
                        end
                        leng = size(scenarioData, 2);
                        results(j, :) = num2cell(calculatemulticost(scenarioData, leng, weightsload, days_in_month));
                    end

                    gencost(k,1) = weightsnetwork*cell2mat(results(:, 1));
                    rela(k,1) = weightsnetwork*cell2mat(results(:, 2));
                    DRcost(k,1) = weightsnetwork*cell2mat(results(:, 3));
                    rigidcost(k,1) = weightsnetwork*cell2mat(results(:, 4));
                    distributecostbs(k,1) = weightsnetwork*cell2mat(results(:, 5));
                    distributecostpv(k,1) = weightsnetwork*cell2mat(results(:, 6));
                    bscost(k,1) = weightsnetwork*cell2mat(results(:, 7));
                end
                gencostflood(stage) =  CtgProbflood*weightsloadfloodstage*gencost;
                relaflood(stage) = CtgProbflood*weightsloadfloodstage*rela;
                DRcostflood(stage) = CtgProbflood*weightsloadfloodstage*DRcost;
                rigidcostflood(stage) = weightsloadfloodstage*rigidcost;
                distributecostbsflood(stage) = weightsloadfloodstage*distributecostbs;
                distributecostpvflood(stage) = lcoecost/0.362/1000*weightsloadfloodstage*distributecostpv;
                bscostflood(stage) = weightsloadfloodstage*bscost;
            else
                gencostflood(stage) =  0;
                relaflood(stage) = 0;
                DRcostflood(stage) = 0;
                rigidcostflood(stage) = 0;
                distributecostbsflood(stage) = 0;
                distributecostpvflood(stage) = 0;
                bscostflood(stage) = 0;
            end
            gencosttotal(stage) = rant(stage)*numnetwork*(gencostnormal(stage)+gencostheat(stage)+gencostcold(stage)+gencosttyphoon(stage)+gencostexwind(stage)+gencostflood(stage));
            relatotal(stage) = rant(stage)*relapercost/70*numnetwork*(relanormal(stage)+relaheat(stage)+relacold(stage)+0.3*relatyphoon(stage)+0.3*relaexwind(stage)+relaflood(stage));
            DRcosttotal(stage) = huilv*drcost_factor*rant(stage)*numnetwork*(DRcostnormal(stage)+DRcostheat(stage)+DRcostcold(stage)+DRcosttyphoon(stage)+DRcostexwind(stage)+DRcostflood(stage));
            rigidcosttotal(stage) = rant(stage)/numnetwork*(max([rigidcostnormal(stage),rigidcostheat(stage),rigidcostcold(stage),rigidcosttyphoon(stage),rigidcostexwind(stage),rigidcostflood(stage)]));
            distributecosttotal(stage) = rant(stage)*numnetwork*(max([distributecostbsnormal(stage),distributecostbsheat(stage),distributecostbscold(stage),distributecostbstyphoon(stage),distributecostbsexwind(stage),distributecostbsflood(stage)])+...
                huilv*max([distributecostpvnormal(stage),distributecostpvheat(stage),distributecostpvcold(stage),distributecostpvtyphoon(stage),distributecostpvexwind(stage),distributecostpvflood(stage)]));
            bscosttotal(stage) = huilv*rant(stage)*numnetwork*(max([bscostnormal(stage),bscostheat(stage),bscostcold(stage),bscosttyphoon(stage),bscostexwind(stage),bscostflood(stage)]));
            %x(stage) =rant(stage)*relapercost/70*numnetwork*relanormal(stage);

            temp1 = [rant(stage)*relapercost/70*numnetwork*[relanormal(stage),relaheat(stage),relacold(stage),0.3*relatyphoon(stage),0.3*relaexwind(stage),relaflood(stage)],
                7*0.6*rant(stage)*numnetwork*[DRcostnormal(stage),DRcostheat(stage),DRcostcold(stage),DRcosttyphoon(stage),DRcostexwind(stage),DRcostflood(stage)],
                0.9*rant(stage)/numnetwork*[rigidcostnormal(stage),CtgProbheat*rigidcostheat(stage),CtgProbcold*rigidcostcold(stage),CtgProbtyphoon*rigidcosttyphoon(stage),CtgProbexwind*rigidcostexwind(stage),CtgProbflood*rigidcostflood(stage)],
                huilv*rant(stage)*numnetwork*[distributecostbsnormal(stage)+distributecostpvnormal(stage),CtgProbheat*distributecostbsheat(stage)+CtgProbheat*distributecostpvheat(stage),CtgProbcold*distributecostbscold(stage)+CtgProbcold*distributecostpvcold(stage),CtgProbtyphoon*distributecostbstyphoon(stage)+CtgProbtyphoon*distributecostpvtyphoon(stage),CtgProbexwind*distributecostbsexwind(stage)+CtgProbexwind*distributecostpvexwind(stage),CtgProbflood*distributecostbsflood(stage)+CtgProbflood*distributecostpvflood(stage)],
                huilv*rant(stage)*numnetwork*[bscostnormal(stage),CtgProbheat*bscostheat(stage),CtgProbcold*bscostcold(stage),CtgProbtyphoon*bscosttyphoon(stage),CtgProbexwind*bscostexwind(stage),CtgProbflood*bscostflood(stage)]];

            row_vector = reshape(temp1',1,[]);
            temptotal = temptotal + row_vector;

            temprela(stage,:) = rant(stage)*relapercost/70*numnetwork*[relaheat(stage),relacold(stage),0.3*relatyphoon(stage),0.3*relaexwind(stage),relaflood(stage)];
            temprelapower(stage,:) = rant(stage)/70*numnetwork*[relaheat(stage),relacold(stage),0.3*relatyphoon(stage),0.3*relaexwind(stage),relaflood(stage)];
        end
        Tgencostnormal = Tgencostnormal+gencosttotal;
        Trelanormal = Trelanormal+relatotal;
        TDRcostnormal = TDRcostnormal+DRcosttotal;
        Trigidcostnormal = Trigidcostnormal+rigidcosttotal;
        Tdistributecostnormal = Tdistributecostnormal+distributecosttotal;
        Tbscostnormal = Tbscostnormal+bscosttotal;

        result.gencost = gencosttotal;
        result.rela = relatotal;
        result.DRcost = DRcosttotal;
        result.rigidcost = rigidcosttotal;
        result.distributecost = distributecosttotal;
        result.bscost = bscosttotal;
        countyresultopt{i,1} = monthly_average_load(i,1);
        countyresultopt{i,2} = found_row;
        countyresultopt{i,3} = result;

        weather_conditions = {'normal', 'heat', 'cold', 'typhoon', 'exwind', 'flood'};
        countyresultoptinfo{i,1} = monthly_average_load(i,1);
        countyresultoptinfo{i,2} = found_row;
        for j =1:length(temptotal)
            countyresultoptinfo{i,j+2} = temptotal(j);
        end

        resultrela.temprela = temprela;
        resultrelapower.temprela = temprelapower;
        countyrelaopt{i,1} = monthly_average_load(i,1);
        countyrelaopt{i,2} = found_row;
        countyrelaopt{i,3} = resultrela;
        countyrelaoptpower{i,1} = monthly_average_load(i,1);
        countyrelaoptpower{i,2} = found_row;
        countyrelaoptpower{i,3} = resultrelapower;
        i;
    end

    chinaresultopt = [Tgencostnormal;Trelanormal;TDRcostnormal;Trigidcostnormal;Tdistributecostnormal;Tbscostnormal];
    chinaresultopt = [chinaresultopt,sum(chinaresultopt,2)];
    chinaresultopt(4:end,7) = chinaresultopt(4:end,6);
    if ppp == 1
        save('countyresultoptinfo126.mat','countyresultoptinfo');
        save('countyresultopt126.mat','countyresultopt');
        save('chinaresultopt126.mat','chinaresultopt');
        save('countyrelaopt126.mat','countyrelaopt');%without bulk power system
        save('countyrelaoptpower126.mat','countyrelaoptpower');
    elseif ppp == 2
        save('countyresultoptinfo245.mat','countyresultoptinfo');
        save('countyresultopt245.mat','countyresultopt');
        save('chinaresultopt245.mat','chinaresultopt');
        save('countyrelaopt245.mat','countyrelaopt');
        save('countyrelaoptpower245.mat','countyrelaoptpower');
    elseif ppp == 3
        save('countyresultoptinfo370.mat','countyresultoptinfo');
        save('countyresultopt370.mat','countyresultopt');
        save('chinaresultopt370.mat','chinaresultopt');
        save('countyrelaopt370.mat','countyrelaopt');
        save('countyrelaoptpower370.mat','countyrelaoptpower');
    elseif ppp == 4
        save('countyresultoptinfo585.mat','countyresultoptinfo');
        save('countyresultopt585.mat','countyresultopt');
        save('chinaresultopt585.mat','chinaresultopt');
        save('countyrelaopt585.mat','countyrelaopt');
        save('countyrelaoptpower585.mat','countyrelaoptpower');
    end
end