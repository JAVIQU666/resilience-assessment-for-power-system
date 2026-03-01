clc
clear all
warning off
load('scenariosnormal.mat');
load('scenariosheat.mat');
load('scenarioscold.mat');
load('scenariostyphoon.mat');
load('scenariosexwind.mat');
load('scenariosflood.mat');
load('scenarioscoldnetwork.mat');
normal = scenariosnormal;
heat = scenariosheat;
cold = scenarioscold;
typhoon = scenariostyphoon;
wind = scenariosexwind;
flood = scenariosflood;
coldnetwork = scenarioscoldnetwork;
load('topology.mat');
mpcrtopology = topology;

reenergyrate = 0.3;
scenario = [normal,heat,cold,typhoon,wind,flood,coldnetwork];

scenariosra2 = [scenario;cell(5,size(scenario,2))];
scenariodra2 = [scenario;cell(5,size(scenario,2))];
scenariosrat2 = [scenario;cell(5,size(scenario,2))];
scenariodrat2 = [scenario;cell(5,size(scenario,2))];
scenariosri2 = [scenario;cell(5,size(scenario,2))];
scenariodri2 = [scenario;cell(5,size(scenario,2))];

numnormal = size(normal,2);
numheat = size(heat,2);
numcold = size(cold,2);
numtyphoon = size(typhoon,2);
numwind = size(wind,2);
numflood = size(flood,2);
numcoldnetwrok = size(coldnetwork,2);
for numtop = 1:size(mpcrtopology,1)
    
    mpc = mpcrtopology{numtop};
    
    tempresult = cell(1, size(scenario, 2));
    tempresultbs = cell(1, size(scenario, 2));
    tempresultrigid = cell(1, size(scenario, 2));
    tempresultmicro = cell(1, size(scenario, 2));
    tempresultdr = cell(1, size(scenario, 2));
    tempresultopt = cell(1, size(scenario, 2));

    for scen = 1:size(scenario, 2)
        
        para = scenario{8,scen};

        
        local_tempresult = cell(1, size(para.load, 2));
        local_tempresultbs = cell(1, size(para.load, 2));
        local_tempresultrigid = cell(1, size(para.load, 2));
        local_tempresultmicro = cell(1, size(para.load, 2));
        local_tempresultdr = cell(1, size(para.load, 2));
        local_tempresultopt = cell(1, size(para.load, 2));
        if (numnormal + numheat + numcold + numtyphoon + numwind < scen) && (scen <= numnormal + numheat + numcold + numtyphoon + numwind + numflood)
            floodindex = 1.2;
        else
            floodindex = 0.9;
        end
        for month = 1:size(para.load, 2)
            load = para.load(:,month);
            pv = para.pv(:,month);
            impact = para.impact;

            %% normal
            BScapmax = 0;
            rigidrate = 0;
            distributrate = 0;
            drrate = 0;
            local_tempresult{month} = calgrid(mpc, load, pv, impact, reenergyrate, BScapmax, rigidrate, distributrate, drrate,floodindex);
            %local_tempresult{month} = [];
            %% microgrid
            BScapmax = 0;
            rigidrate = 0;
            distributrate = 1;
            drrate = 0;
            local_tempresultmicro{month} = calgrid(mpc, load, pv, impact, reenergyrate, BScapmax, rigidrate, distributrate, drrate,floodindex);
            %local_tempresultmicro{month} = [];
            %% BS
            BScapmax = 1.5;
            rigidrate = 0;
            distributrate = 1;
            drrate = 0;
            local_tempresultbs{month} = calgrid(mpc, load, pv, impact, reenergyrate, BScapmax, rigidrate, distributrate, drrate,floodindex);
            %local_tempresultbs{month} = [];
            %% RIGID
            BScapmax = 1.5;
            rigidrate = 0.5;
            distributrate = 1;
            drrate = 0;
            local_tempresultrigid{month} = calgrid(mpc, load, pv, impact, reenergyrate, BScapmax, rigidrate, distributrate, drrate,floodindex);
            %local_tempresultrigid{month} = [];
            
            %% dr
            BScapmax = 0;
            rigidrate = 0;
            distributrate = 0;
            drrate = 0.4;
            %local_tempresultdr{month} = calgrid(mpc, load, pv, impact, reenergyrate, BScapmax, rigidrate, distributrate, drrate,floodindex);
            local_tempresultdr{month} = [];
            %% optimal
            BScapmax = 1.5;
            rigidrate = 0.5;
            distributrate = 1;
            drrate = 0.3;
            local_tempresultopt{month} = calgrid(mpc, load, pv, impact, reenergyrate, BScapmax, rigidrate, distributrate, drrate,floodindex);
            %local_tempresultopt{month} = [];
        end
        scen
        
        tempresult{scen} = local_tempresult;
        tempresultbs{scen} = local_tempresultbs;
        tempresultrigid{scen} = local_tempresultrigid;
        tempresultmicro{scen} = local_tempresultmicro;
        tempresultdr{scen} = local_tempresultdr;
        tempresultopt{scen} = local_tempresultopt;
    end

    
    if numtop == 1
        scenariosra2(3+6,:) = tempresult;
        scenariosra2(4+6,:) = tempresultbs;
        scenariosra2(5+6,:) = tempresultmicro;
        scenariosra2(6+6,:) = tempresultrigid;
        scenariosra2(7+6,:) = tempresultdr;
        scenariosra2(8+6,:) = tempresultopt;
        save('Scenariosra2.mat','scenariosra2');
    elseif numtop == 2
        scenariodra2(3+6,:) = tempresult;
        scenariodra2(4+6,:) = tempresultbs;
        scenariodra2(5+6,:) = tempresultmicro;
        scenariodra2(6+6,:) = tempresultrigid;
        scenariodra2(7+6,:) = tempresultdr;
        scenariodra2(8+6,:) = tempresultopt;
        save('Scenariodra2.mat','scenariodra2');
    elseif numtop == 3
        scenariosrat2(3+6,:) = tempresult;
        scenariosrat2(4+6,:) = tempresultbs;
        scenariosrat2(5+6,:) = tempresultmicro;
        scenariosrat2(6+6,:) = tempresultrigid;
        scenariosrat2(7+6,:) = tempresultdr;
        scenariosrat2(8+6,:) = tempresultopt;
        save('Scenariosrat2.mat','scenariosrat2');
    elseif numtop == 4
        scenariodrat2(3+6,:) = tempresult;
        scenariodrat2(4+6,:) = tempresultbs;
        scenariodrat2(5+6,:) = tempresultmicro;
        scenariodrat2(6+6,:) = tempresultrigid;
        scenariodrat2(7+6,:) = tempresultdr;
        scenariodrat2(8+6,:) = tempresultopt;
        save('Scenariodrat2.mat','scenariodrat2');
    elseif numtop == 5
        scenariosri2(3+6,:) = tempresult;
        scenariosri2(4+6,:) = tempresultbs;
        scenariosri2(5+6,:) = tempresultmicro;
        scenariosri2(6+6,:) = tempresultrigid;
        scenariosri2(7+6,:) = tempresultdr;
        scenariosri2(8+6,:) = tempresultopt;
        save('Scenariosri2.mat','scenariosri2');
    elseif numtop == 6
        scenariodri2(3+6,:) = tempresult;
        scenariodri2(4+6,:) = tempresultbs;
        scenariodri2(5+6,:) = tempresultmicro;
        scenariodri2(6+6,:) = tempresultrigid;
        scenariodri2(7+6,:) = tempresultdr;
        scenariodri2(8+6,:) = tempresultopt;
        save('Scenariodri2.mat','scenariodri2');
%     elseif numtop == 7
%         scenariodp(3+6,:) = tempresult;
%         scenariodp(4+6,:) = tempresultbs;
%         scenariodp(5+6,:) = tempresultmicro;
%         scenariodp(6+6,:) = tempresultrigid;
%         scenariodp(7+6,:) = tempresultdr;
%         scenariodp(8+6,:) = tempresultopt;
%         save('Scenariodp.mat','scenariodp');
    end


end
