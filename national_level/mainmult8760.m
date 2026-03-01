for ppp = 1:4
    clc
    clearvars -except ppp
    warning off

    load('mpc_model_load20.mat');
    load('mpc.mat');
    load('loadcurve20to50.mat');
    load('equipment.mat');
    load('mpcre.mat');
    load('mpcrelcoe.mat');
    load('mpcdisasters.mat');
    load('wtld1_lv8760.mat');
    load('pvcurve8760.mat');
    if ppp == 1
        load('countyresultnormal.mat');
        load('countyreladisasterpower126.mat');
        load('countyrelabspower126.mat');
        load('countyrelarigidpower126.mat');
        load('countyrelamicropower126.mat');
        load('countyrelaoptpower126.mat');
        load('county_disaster_precalc126.mat');
    elseif ppp == 2
        load('countyresultnormal.mat');
        load('countyreladisasterpower245.mat');
        load('countyrelabspower245.mat');
        load('countyrelarigidpower245.mat');
        load('countyrelamicropower245.mat');
        load('countyrelaoptpower245.mat');
        load('county_disaster_precalc245.mat');
    elseif ppp == 3
        load('countyresultnormal.mat');
        load('countyreladisasterpower370.mat');
        load('countyrelabspower370.mat');
        load('countyrelarigidpower370.mat');
        load('countyrelamicropower370.mat');
        load('countyrelaoptpower370.mat');
        load('county_disaster_precalc370.mat');
    elseif ppp == 4
        load('countyresultnormal.mat');
        load('countyreladisasterpower585.mat');
        load('countyrelabspower585.mat');
        load('countyrelarigidpower585.mat');
        load('countyrelamicropower585.mat');
        load('countyrelaoptpower585.mat');
        load('county_disaster_precalc585.mat');
    end

    time = [2025 2030 2035 2040 2045 2050];
    timetotal = 8760;
    % Provincial power exchange, used to represent the interconnection status
    powerinter = [-0.203050858	-0.633787933	-0.117001779	0.55212585	-0.51696143	-0.013188125	0.134992479	0.2052349	0.248555352	-0.09058991	0	0.684323876	-0.028639784	-0.346457508	0.320926969	-0.243197187	-0.275720076	0.722650517	0	0.853591749	0.709490114	0.97855314	0.039857471	0.083428618	-0.280454492	-0.349840391	0.345459389	-0.323495841	0	0.132633669	0.118511168	0.726395945	-0.318913344	-0.518921643];
    firpower = 10*[5561	1136	3478	2308	9582	2344	3560	546	5391	7068	0	2423	3316	2269	1852	2455	10079	3643	0	9374	3326	393	1596	4993	11135	2450	6878	1668	0	6337	43	1517	6358	1545];
    for scen = 2:2
        if scen == 1
            for item =1:length(loadcurve20to50.NDC)-1

                year = sprintf('yr%d', time(item));
                rateload(item) = loadcurve20to50.NDC(item+1)/loadcurve20to50.CN50(1);
                rateload = round(rateload, 2);
                load('NDCmpcmodelnor.mat');
                load('NDCmpcmodeldis.mat');
                modelnor = mpcnormodel;
                modeldis = mpcdismodel;
            end
        elseif scen == 2
            for item =1:length(loadcurve20to50.CN50)-1

                year = sprintf('yr%d', time(item));
                rateload(item) = loadcurve20to50.CN50(item+1)/loadcurve20to50.CN50(1);
                rateload = round(rateload, 2);
                load('CN50mpcmodelnor.mat');
                load('CN50mpcmodeldis.mat');

                modelnor = mpcnormodel;
                modeldis = mpcdismodel;
            end
        elseif scen == 3
            for item =1:length(loadcurve20to50.GM20)-1

                year = sprintf('yr%d', time(item));
                rateload(item) = loadcurve20to50.GM20(item+1)/loadcurve20to50.GM20(1);
                rateload = round(rateload, 2);
                load('GM20mpcmodelnor.mat');
                load('GM20mpcmodeldis.mat');
                modelnor = mpcnormodel;
                modeldis = mpcdismodel;
            end
        end
        for mpcIndex=1:34
            if (mpcIndex ~= 19) && (mpcIndex ~= 11) && (mpcIndex ~= 29)
                mpcname = sprintf('mpc%d', mpcIndex);
                mpc0 = mpc.(mpcname);
                mpcre0 = mpcre.(mpcname);
                mpcrelcoe0 = mpcrelcoe.(mpcname);
                mpc_model_load200 = mpc_model_load20.(mpcname);
                mpcdisasters0 = mpcdisasters;
                mpcmodelnor = modelnor.(mpcname);
                mpcmodeldis = modeldis.(mpcname);

                n_Ebus = size(mpc0.bus,1);
                n_Ebranch = size(mpc0.branch,1);
                n_Egen = size(mpc0.gen,1);
                Pload365 = zeros(n_Ebus,8760);
                Pload365(find(mpc0.bus(:,3)~=0),:) = mpc0.bus(find(mpc0.bus(:,3)~=0),3)/sum(mpc_model_load20.(mpcname).loadcurve8760)*mpc_model_load20.(mpcname).loadcurve8760;
                Pload365 = Pload365*10^6;%MW

                Pload = zeros(n_Ebus,8760);
                Ploadterm = mpc_model_load20.(mpcname).loadcurve8760;

                [sorted_PVterm, sort_idx] = sort(pvcurve8760(mpcIndex,:));
                sorted_WTterm = WT(sort_idx)';
                sorted_Pload = Ploadterm(sort_idx);

                index = length(find(sorted_PVterm==0));
                [sorted_Pload1, sort_idx1] = sort(sorted_Pload(1:index));
                [sorted_Pload2, sort_idx2] = sort(sorted_Pload(index+1:end));
                sorted_Pload = [sorted_Pload1,sorted_Pload2];

                sorted_WTterm1=sorted_WTterm(1:index);
                sorted_WTterm2=sorted_WTterm(index+1:end);
                sorted_WTterm1 = sorted_WTterm1(sort_idx1);
                sorted_WTterm2 = sorted_WTterm2(sort_idx2);
                sorted_WTterm = [sorted_WTterm1,sorted_WTterm2];

                Pload(find(mpc0.bus(:,3)~=0),:) = mpc0.bus(find(mpc0.bus(:,3)~=0),3)/sum(mpc_model_load20.(mpcname).loadcurve8760)*(sorted_Pload);
                Pload = Pload*10^6+0/size(mpc0.bus,1);%MW
                %% baseline
                A = mpcmodelnor.A;
                T = mpcmodelnor.T;
                c = mpcmodelnor.c;
                h = mpcmodelnor.h;
                eq = mpcmodelnor.eq;
                ineq = mpcmodelnor.ineq;
                totalRela = sumRelaForMPCnormal(countyresultnormal, mpcIndex);
                [resultnor] = calLshapednormal8760(totalRela, A,T,h,c,eq,ineq,mpc0, mpcre0, mpcrelcoe0, equipment, mpc_model_load200, Pload, sorted_WTterm, sorted_PVterm, rateload, scen,powerinter(mpcIndex),firpower(mpcIndex));
                if resultnor.z == 0
                    [resultnor] = calLshapednormal365(timetotal, totalRela,mpc0, mpcre0, mpcrelcoe0, equipment, mpc_model_load200, Pload365, WT', pvcurve8760(mpcIndex,:), rateload, scen,powerinter(mpcIndex),firpower(mpcIndex));
                end
                temp_mpcnorresult = struct();
                temp_mpcnorresult.result = resultnor;
                temp_mpcnorresult.proname = mpc0.proname;
                %% case1
                A = mpcmodeldis.A;
                T = mpcmodeldis.T;
                c = mpcmodeldis.c;
                h = mpcmodeldis.h;
                eq = mpcmodeldis.eq;
                ineq = mpcmodeldis.ineq;
                totalRela = sumRelaForMPC(countyreladisasterpower, mpcIndex);
                probdis = sumprobForMPC(countyresultnormal, mpcIndex, precalc);
                [resultdis] = calLshapeddisaster8760(totalRela, A,T,h,c,eq,ineq,mpc0, mpcre0, mpcrelcoe0, equipment, mpc_model_load200, Pload, sorted_WTterm, sorted_PVterm, rateload, scen,powerinter(mpcIndex),firpower(mpcIndex));
                if resultdis.z == 0
                    [resultdis] = calLshapeddisaster365(timetotal, totalRela, probdis, mpc0, mpcre0, mpcrelcoe0, equipment, mpcdisasters0, mpc_model_load200, Pload365, WT', pvcurve8760(mpcIndex,:), rateload, scen,powerinter(mpcIndex),firpower(mpcIndex));
                end
                temp_mpcdisresult = struct();
                temp_mpcdisresult.result = resultdis;
                temp_mpcdisresult.proname = mpc0.proname;
                %% case2
                totalRela = sumRelaForMPC(countyrelamicropower, mpcIndex);
                [resultdisdistributonly] = calLshapeddisaster8760(totalRela, A,T,h,c,eq,ineq,mpc0, mpcre0, mpcrelcoe0, equipment, mpc_model_load200, Pload, sorted_WTterm, sorted_PVterm, rateload, scen,powerinter(mpcIndex),firpower(mpcIndex));
                if resultdisdistributonly.z == 0
                    [resultdisdistributonly] = calLshapeddisaster365(timetotal, totalRela, probdis ,mpc0, mpcre0, mpcrelcoe0, equipment, mpcdisasters0, mpc_model_load200, Pload365, WT', pvcurve8760(mpcIndex,:), rateload, scen,powerinter(mpcIndex),firpower(mpcIndex));
                end
                temp_mpcdisresultdistributonly = struct();
                temp_mpcdisresultdistributonly.result = resultdisdistributonly;
                temp_mpcdisresultdistributonly.proname = mpc0.proname;
                %% case3
                totalRela = sumRelaForMPC(countyrelabspower, mpcIndex);
                [resultdisBSonly] = calLshapeddisaster8760(totalRela, A,T,h,c,eq,ineq,mpc0, mpcre0, mpcrelcoe0, equipment, mpc_model_load200, Pload, sorted_WTterm, sorted_PVterm, rateload, scen,powerinter(mpcIndex),firpower(mpcIndex));
                if resultdisBSonly.z == 0
                    [resultdisBSonly] = calLshapeddisaster365(timetotal, totalRela, probdis ,mpc0, mpcre0, mpcrelcoe0, equipment, mpcdisasters0, mpc_model_load200, Pload365, WT', pvcurve8760(mpcIndex,:), rateload, scen,powerinter(mpcIndex),firpower(mpcIndex));
                end
                temp_mpcdisresultBSonly = struct();
                temp_mpcdisresultBSonly.result = resultdisBSonly;
                temp_mpcdisresultBSonly.proname = mpc0.proname;
                %% case4
                totalRela = sumRelaForMPC(countyrelarigidpower, mpcIndex);
                [resultdisrigidonly] = calLshapeddisaster8760(totalRela, A,T,h,c,eq,ineq,mpc0, mpcre0, mpcrelcoe0, equipment, mpc_model_load200, Pload, sorted_WTterm, sorted_PVterm, rateload, scen,powerinter(mpcIndex),firpower(mpcIndex));
                if resultdisrigidonly.z == 0
                    [resultdisrigidonly] = calLshapeddisaster365(timetotal, totalRela, probdis ,mpc0, mpcre0, mpcrelcoe0, equipment, mpcdisasters0, mpc_model_load200, Pload365, WT', pvcurve8760(mpcIndex,:), rateload, scen,powerinter(mpcIndex),firpower(mpcIndex));
                end
                temp_mpcdisresultrigidonly = struct();
                temp_mpcdisresultrigidonly.result = resultdisrigidonly;
                temp_mpcdisresultrigidonly.proname = mpc0.proname;

                %% dr
                %totalRela = sumRelaForMPC(countyresultdr, mpcIndex);
                %            [resultdisdronly] = calLshapeddisaster8760(totalRela, A,T,h,c,eq,ineq,mpc0, mpcre0, mpcrelcoe0, equipment, mpc_model_load200, Pload, sorted_WTterm, sorted_PVterm, rateload, scen,powerinter(mpcIndex),firpower(mpcIndex));
                %            if resultdisdronly.z == 0
                %                [resultdisdronly] = calLshapeddisaster365(timetotal, totalRela, probdis ,mpc0, mpcre0, mpcrelcoe0, equipment, mpcdisasters0, mpc_model_load200, Pload365, WT', pvcurve8760(mpcIndex,:), rateload, scen);
                %            end
                temp_mpcdisresultdronly = struct();
                %            temp_mpcdisresultdronly.result = resultdisdronly;
                %            temp_mpcdisresultdronly.proname = mpc0.proname;
                %% optimal pathway
                A = mpcmodeldis.A;
                T = mpcmodeldis.T;
                c = mpcmodeldis.c;
                h = mpcmodeldis.h;
                eq = mpcmodeldis.eq;
                ineq = mpcmodeldis.ineq;
                totalRela = sumRelaForMPC(countyrelaoptpower, mpcIndex)/125*139;
                [resultdisdr] = calLshapeddisaster8760(totalRela, A,T,h,c,eq,ineq,mpc0, mpcre0, mpcrelcoe0, equipment, mpc_model_load200, Pload, sorted_WTterm, sorted_PVterm, rateload, scen,powerinter(mpcIndex),firpower(mpcIndex));
                if resultdisdr.z == 0
                    [resultdisdr] = calLshapeddisaster365(timetotal, totalRela, probdis ,mpc0, mpcre0, mpcrelcoe0, equipment, mpcdisasters0, mpc_model_load200, Pload365, WT', pvcurve8760(mpcIndex,:), rateload, scen,powerinter(mpcIndex),firpower(mpcIndex));
                end
                temp_mpcdisresultdr = struct();
                temp_mpcdisresultdr.result = resultdisdr;
                temp_mpcdisresultdr.proname = mpc0.proname;

                mpcnorresult_temp{mpcIndex} = temp_mpcnorresult;
                mpcdisresult_temp{mpcIndex} = temp_mpcdisresult;
                mpcdisresultBSonly_temp{mpcIndex} = temp_mpcdisresultBSonly;
                mpcdisresultrigidonly_temp{mpcIndex} = temp_mpcdisresultrigidonly;
                mpcdisresultdistributonly_temp{mpcIndex} = temp_mpcdisresultdistributonly;
                mpcdisresultdronly_temp{mpcIndex} = temp_mpcdisresultdronly;
                mpcdisresultdr_temp{mpcIndex} = temp_mpcdisresultdr;
                mpcIndex
            end
        end

        for mpcIndex = 1:34
            if (mpcIndex ~= 19) && (mpcIndex ~= 11)
                mpcname = sprintf('mpc%d', mpcIndex);
                mpcnorresult.(mpcname) = mpcnorresult_temp{mpcIndex};
                mpcdisresult.(mpcname) = mpcdisresult_temp{mpcIndex};
                mpcdisresultdr.(mpcname) = mpcdisresultdr_temp{mpcIndex};
                mpcdisresultBSonly.(mpcname) = mpcdisresultBSonly_temp{mpcIndex};
                mpcdisresultrigidonly.(mpcname) = mpcdisresultrigidonly_temp{mpcIndex};
                mpcdisresultdistributonly.(mpcname) = mpcdisresultdistributonly_temp{mpcIndex};
                mpcdisresultdronly.(mpcname) = mpcdisresultdronly_temp{mpcIndex};
            end
        end
        if ppp == 1
            save('mpcnorresult126.mat', 'mpcnorresult');
            save('mpcdisresult126.mat', 'mpcdisresult');
            save('mpcdisresultdr126.mat', 'mpcdisresultdr');
            save('mpcdisresultBSonly126.mat', 'mpcdisresultBSonly');
            save('mpcdisresultrigidonly126.mat', 'mpcdisresultrigidonly');
            save('mpcdisresultdistributonly126.mat', 'mpcdisresultdistributonly');
            save('mpcdisresultdronly126.mat', 'mpcdisresultdronly');
        elseif ppp == 2
            save('mpcnorresult245.mat', 'mpcnorresult');
            save('mpcdisresult245.mat', 'mpcdisresult');
            save('mpcdisresultdr245.mat', 'mpcdisresultdr');
            save('mpcdisresultBSonly245.mat', 'mpcdisresultBSonly');
            save('mpcdisresultrigidonly245.mat', 'mpcdisresultrigidonly');
            save('mpcdisresultdistributonly245.mat', 'mpcdisresultdistributonly');
            save('mpcdisresultdronly245.mat', 'mpcdisresultdronly');
        elseif ppp == 3
            save('mpcnorresult370.mat', 'mpcnorresult');
            save('mpcdisresult370.mat', 'mpcdisresult');
            save('mpcdisresultdr370.mat', 'mpcdisresultdr');
            save('mpcdisresultBSonly370.mat', 'mpcdisresultBSonly');
            save('mpcdisresultrigidonly370.mat', 'mpcdisresultrigidonly');
            save('mpcdisresultdistributonly370.mat', 'mpcdisresultdistributonly');
            save('mpcdisresultdronly370.mat', 'mpcdisresultdronly');
        elseif ppp == 4
            save('mpcnorresult585.mat', 'mpcnorresult');
            save('mpcdisresult585.mat', 'mpcdisresult');
            save('mpcdisresultdr585.mat', 'mpcdisresultdr');
            save('mpcdisresultBSonly585.mat', 'mpcdisresultBSonly');
            save('mpcdisresultrigidonly585.mat', 'mpcdisresultrigidonly');
            save('mpcdisresultdistributonly585.mat', 'mpcdisresultdistributonly');
            save('mpcdisresultdronly585.mat', 'mpcdisresultdronly');
        end

    end
end
