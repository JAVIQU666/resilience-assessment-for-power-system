clc
clear all
warning off

%% 加载数据
load('mpc_model_load20.mat');
load('mpc.mat');
load('loadcurve20to50.mat');
load('equipment.mat');
load('mpcre.mat');
load('mpcdisasters.mat');
load('WT33_lv8760.mat');
load('pvcurve8760.mat');
time = [2025 2030 2035 2040 2045 2050];
firpower = 10*[5561	1136	3478	2308	9582	2344	3560	546	5391	7068	0	2423	3316	2269	1852	2455	10079	3643	0	9374	3326	393	1596	4993	11135	2450	6878	1668	0	6337	43	1517	6358	1545];

for scen = 2:2
    if scen == 1
        for item =1:length(loadcurve20to50.NDC)-1
   
            year = sprintf('yr%d', time(item));
            rateload(item) = loadcurve20to50.NDC(item+1)/loadcurve20to50.NDC(1); 
            rateload = round(rateload, 2);
        end
    elseif scen == 2
        for item =1:length(loadcurve20to50.CN50)-1
       
            year = sprintf('yr%d', time(item));
            rateload(item) = loadcurve20to50.CN50(item+1)/loadcurve20to50.CN50(1); 
            rateload = round(rateload, 2);
        end
    elseif scen == 3
        for item =1:length(loadcurve20to50.GM20)-1
        
            year = sprintf('yr%d', time(item));
            rateload(item) = loadcurve20to50.GM20(item+1)/loadcurve20to50.GM20(1); 
            rateload = round(rateload, 2);
        end
    end
    for mpcIndex=1:34
        if (mpcIndex ~= 19) && (mpcIndex ~= 11) && (mpcIndex ~= 29)%澳门 香港除外
            mpcname = sprintf('mpc%d', mpcIndex);
            mpc0 = mpc.(mpcname);
            mpcre0 = mpcre.(mpcname);
            mpc_model_load200 = mpc_model_load20.(mpcname);
            mpcdisasters0 = mpcdisasters;
            
  
            n_Ebus = size(mpc0.bus,1);
            n_Ebranch = size(mpc0.branch,1);
            n_Egen = size(mpc0.gen,1);
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
            Pload = Pload*10^6;%MW
            
            %% baseline
            [A,T,h,c,eq,ineq] = getnorpara(mpc0, mpcre0, equipment, mpc_model_load200, Pload, WT(:,1)', pvcurve8760(mpcIndex,:), rateload, scen, firpower(mpcIndex));
            temp_mpcnorresult = struct();
            temp_mpcnorresult.A = A;
            temp_mpcnorresult.T = T;
            temp_mpcnorresult.h = h;
            temp_mpcnorresult.c = c;
            temp_mpcnorresult.eq = eq;
            temp_mpcnorresult.ineq = ineq;

            mpcnormodel_temp{mpcIndex} = temp_mpcnorresult;
            
            %% case1 to optimal pathway
            [A,T,h,c,eq,ineq] = getdispara(mpc0, mpcre0, equipment, mpcdisasters0, mpc_model_load200, Pload, sorted_WTterm, sorted_PVterm, rateload, scen, firpower(mpcIndex));
            temp_mpcdisresult = struct();
            temp_mpcdisresult.A = A;
            temp_mpcdisresult.T = T;
            temp_mpcdisresult.h = h;
            temp_mpcdisresult.c = c;
            temp_mpcdisresult.eq = eq;
            temp_mpcdisresult.ineq = ineq;

            mpcdismodel_temp{mpcIndex} = temp_mpcdisresult;

            mpcIndex
        end
    end

    for mpcIndex = 1:34
        if (mpcIndex ~= 19) && (mpcIndex ~= 11) && (mpcIndex ~= 29)
            mpcname = sprintf('mpc%d', mpcIndex);
            mpcnormodel.(mpcname) = mpcnormodel_temp{mpcIndex};
            mpcdismodel.(mpcname) = mpcdismodel_temp{mpcIndex};     
        end
    end
    if scen == 1
        save('NDCmpcmodelnor.mat', 'mpcnormodel');
        save('NDCmpcmodeldis.mat', 'mpcdismodel');  
    elseif scen == 2
        save('CN50mpcmodelnor.mat', 'mpcnormodel');
        save('CN50mpcmodeldis.mat', 'mpcdismodel');  
    elseif scen == 3
        save('GM20mpcmodelnor.mat', 'mpcnormodel');
        save('GM20mpcmodeldis.mat', 'mpcdismodel');
    end
end
