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
        load('ProvDisasterStageLevel_126.mat')
    elseif ppp == 2
        load('countyresultnormal.mat');
        load('countyreladisasterpower245.mat');
        load('countyrelabspower245.mat');
        load('countyrelarigidpower245.mat');
        load('countyrelamicropower245.mat');
        load('countyrelaoptpower245.mat');
        load('county_disaster_precalc245.mat');
        load('ProvDisasterStageLevel_245.mat')
    elseif ppp == 3
        load('countyresultnormal.mat');
        load('countyreladisasterpower370.mat');
        load('countyrelabspower370.mat');
        load('countyrelarigidpower370.mat');
        load('countyrelamicropower370.mat');
        load('countyrelaoptpower370.mat');
        load('county_disaster_precalc370.mat');
        load('ProvDisasterStageLevel_370.mat')
    elseif ppp == 4
        load('countyresultnormal.mat');
        load('countyreladisasterpower585.mat');
        load('countyrelabspower585.mat');
        load('countyrelarigidpower585.mat');
        load('countyrelamicropower585.mat');
        load('countyrelaoptpower585.mat');
        load('county_disaster_precalc585.mat');
        load('ProvDisasterStageLevel_585.mat')
    end
    time = [2025 2030 2035 2040 2045 2050];
    timetotal = 8760;
    %timetotal = 24;
    %% cost
    pdc = [166.813042	128.1966289	196.6759024	38.33816561	490.1155182	85.26086886	66.10649876	18.68898049	153.5702265	211.9938369	0	43.22429421	194.2512653	172.4320694	41.61427874	111.8001716	488.5558108	101.41199	0	87.6057043	17.8496309	12.64810843	210.2498065	116.8907941	343.4112896	149.7026849	84.70735697	56.28595486	0	64.44490862	8.440175967	94.78997465	300.2823314	101.0885387];
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
                ProvDisasterheat = squeeze(ProvDisasterStageLevel(mpcIndex,1,:,:));
                ProvDisastercold = squeeze(ProvDisasterStageLevel(mpcIndex,2,:,:));
                ProvDisastertyphone = squeeze(ProvDisasterStageLevel(mpcIndex,3,:,:));
                ProvDisasterexwind = squeeze(ProvDisasterStageLevel(mpcIndex,4,:,:));

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
                Pload = Pload*10^6+0/size(mpc0.bus,1);
                %% baseline
                totalRela = sumRelaForMPCnormal(countyresultnormal, mpcIndex);
                [resultnor] = calLshapednormal365(timetotal, totalRela,mpc0, mpcre0, mpcrelcoe0, equipment, mpc_model_load200, Pload365, WT', pvcurve8760(mpcIndex,:), rateload, scen,powerinter(mpcIndex),firpower(mpcIndex));
                [resultnorheat] = calLshapednormal365withmaingridheat(resultnor,timetotal, totalRela,mpc0, mpcre0, mpcrelcoe0, equipment, mpc_model_load200, Pload365, WT', pvcurve8760(mpcIndex,:), rateload, scen,ProvDisasterheat,pdc(mpcIndex),powerinter(mpcIndex),firpower(mpcIndex));
                [resultnorcold] = calLshapednormal365withmaingridcold(resultnor,timetotal, totalRela,mpc0, mpcre0, mpcrelcoe0, equipment, mpc_model_load200, Pload365, WT', pvcurve8760(mpcIndex,:), rateload, scen,ProvDisastercold,pdc(mpcIndex),powerinter(mpcIndex),firpower(mpcIndex));
                [resultnortyphone] = calLshapednormal365withmaingridtyphone(resultnor,timetotal, totalRela,mpc0, mpcre0, mpcrelcoe0, equipment, mpc_model_load200, Pload365, WT', pvcurve8760(mpcIndex,:), rateload, scen,ProvDisastertyphone,pdc(mpcIndex),powerinter(mpcIndex),firpower(mpcIndex));
                [resultnorexwind] = calLshapednormal365withmaingridexwind(resultnor,timetotal, totalRela,mpc0, mpcre0, mpcrelcoe0, equipment, mpc_model_load200, Pload365, WT', pvcurve8760(mpcIndex,:), rateload, scen,ProvDisasterexwind,pdc(mpcIndex),powerinter(mpcIndex),firpower(mpcIndex));

                temp_mpcnorresult = struct();
                resultnor.relaheat = sum(ProvDisasterheat).*resultnorheat.rela;
                resultnor.relacold = sum(ProvDisastercold).*resultnorcold.rela;
                resultnor.relatyphone = sum(ProvDisastertyphone).*resultnortyphone.rela;
                resultnor.relaexwind = sum(ProvDisasterexwind).*resultnorexwind.rela;
                temp_mpcnorresult.proname = mpc0.proname;
                %% case 1
                A = mpcmodeldis.A;
                T = mpcmodeldis.T;
                c = mpcmodeldis.c;
                h = mpcmodeldis.h;
                eq = mpcmodeldis.eq;
                ineq = mpcmodeldis.ineq;
                totalRela = sumRelaForMPC(countyreladisasterpower, mpcIndex);
                probdis = sumprobForMPC(countyresultnormal, mpcIndex, precalc);
                temp_mpcdisresult = struct();
                %% case2
                totalRela = sumRelaForMPC(countyrelamicropower, mpcIndex);
                temp_mpcdisresultdistributonly = struct();
                %% case3
                totalRela = sumRelaForMPC(countyrelabspower, mpcIndex);
                temp_mpcdisresultBSonly = struct();
                %% case4
                totalRela = sumRelaForMPC(countyrelarigidpower, mpcIndex);
                temp_mpcdisresultrigidonly = struct();
                %% optimal pathway
                temp_mpcdisresultdronly = struct();
                %% 最优路径
                A = mpcmodeldis.A;
                T = mpcmodeldis.T;
                c = mpcmodeldis.c;
                h = mpcmodeldis.h;
                eq = mpcmodeldis.eq;
                ineq = mpcmodeldis.ineq;
                totalRela = sumRelaForMPC(countyrelaoptpower, mpcIndex);
                temp_mpcdisresultdr = struct();

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
            save('mpcnorresult126withmaingrid.mat', 'mpcnorresult');
        elseif ppp == 2
            save('mpcnorresult245withmaingrid.mat', 'mpcnorresult');
        elseif ppp == 3
            save('mpcnorresult370withmaingrid.mat', 'mpcnorresult');
        elseif ppp == 4
            save('mpcnorresult585withmaingrid.mat', 'mpcnorresult');
        end

    end
end