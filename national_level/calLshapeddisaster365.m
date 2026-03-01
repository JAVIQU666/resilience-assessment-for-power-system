function [result] = calLshapeddisaster365(time, totalRela, probdis, mpc0, mpcre0, mpcrelcoe0, equipment, mpcdisasters0, mpc_model_load20, Pload, WT, PV, rateload, scen,powerinter,firpower)
period = [2025 2030 2035 2040 2045 2050];
num_stage = length(period);
wtinc = mpcrelcoe0.procmipwt;
pvinc = mpcrelcoe0.procmiprsds;
wtinc = [1 1 1 1 1 1];
reliabilitylimit = totalRela;
reliabilitylimit(find(reliabilitylimit<=0.000001))=0;
tic

huilv = 7;
discountrate = 0.03;
if time == 24
    WTreshpe = reshape(WT,[24,365]);
    WTreshpe = mean(WTreshpe,2);
    wt = WTreshpe;

    PVreshpe = reshape(PV,[24,365]);
    PVreshpe = mean(PVreshpe,2);
    pv = PVreshpe;
else
    wt = WT';
    pv = PV';
end

numscen = 6; 

maxHycap = mpc_model_load20.loadwater;

pvlcoe = mean(mpc0.bus(find(mpc0.bus(:,3)~=0),8));
wtlcoe = mean(mpc0.bus(find(mpc0.bus(:,3)~=0),9));


PBScheff = 0.95;
PBSdiseff = 0.95;
PBSchmax = 0.2;
PBSdismax = 0.2;
SOCinitial = 0.5;
SOCmin = 0.2;
SOCmax = 0.8;

BScapcent = sdpvar(1,num_stage);

NGcap = sdpvar(1,num_stage);
NGCCScap = sdpvar(1,num_stage);
COALcap = sdpvar(1,num_stage);
COALCCScap = sdpvar(1,num_stage);
Biopowercap = sdpvar(1,num_stage);
BiopowerCCScap = sdpvar(1,num_stage);
Geothermalcap = sdpvar(1,num_stage);
Hydropowercap = sdpvar(1,num_stage);
Nuclearcap = sdpvar(1,num_stage);
OFFWTcap = sdpvar(1,num_stage);

ONWTcap = sdpvar(1,num_stage);
UPVcap = sdpvar(1,num_stage);
DPVcap = sdpvar(1,num_stage);
CSPcap = sdpvar(1,num_stage);


PONWT = sdpvar(1,time,numscen,num_stage);
PUPV = sdpvar(1,time,numscen,num_stage);
PDPV = sdpvar(1,time,numscen,num_stage);
PCSP = sdpvar(1,time,numscen,num_stage);

PBSchcent = sdpvar(time,numscen,num_stage);
PBSdiscent = sdpvar(time,numscen,num_stage);
SOCcent = sdpvar(time,numscen,num_stage);

PNG = sdpvar(time,numscen,num_stage);
PNGCCS = sdpvar(time,numscen,num_stage);
PCOAL = sdpvar(time,numscen,num_stage);
PCOALCCS = sdpvar(time,numscen,num_stage);
PBiopower = sdpvar(time,numscen,num_stage);
PBiopowerCCS = sdpvar(time,numscen,num_stage);
PGeothermal = sdpvar(time,numscen,num_stage);
PHydropower = sdpvar(time,numscen,num_stage);
PNuclear = sdpvar(time,numscen,num_stage);
POFFWT = sdpvar(time,numscen,num_stage);

plc = sdpvar(1,time,numscen,num_stage,'full');
qlc = sdpvar(1,time,numscen,num_stage,'full');

MpConstraints =[];
Constraints = [];
for stage=1:length(period)
    year = sprintf('yr%d', period(stage));
    equipment0 = equipment.(year);

    wt = wt*wtinc(stage);
    pv = pv*pvinc(stage)*1.4;

    if scen == 1
        carlim = equipment0.carlimCN50*mpc_model_load20.ratio; % 10^8t
        carcost = equipment0.carcostCN50;
    elseif scen == 2
        carlim = equipment0.carlimCN50*mpc_model_load20.ratio; % 10^8t
        carcost = equipment0.carcostCN50;
    elseif scen == 3
        carlim = equipment0.carlimGM20*mpc_model_load20.ratio; % 10^8t
        carcost = equipment0.carcostGM20;
    end

    if time == 24
        Ploadreshpe = reshape(Pload,[size(Pload,1),24,365]);
        Ploadreshpe = mean(Ploadreshpe,3);
        Ploadreshpe = squeeze(Ploadreshpe);
        pl = rateload(stage)*Ploadreshpe;
    else
        pl = Pload;
    end
    pl = sum(pl,1)*(1+powerinter);

    loadequipmentdata();

    gdp = mpc0.bus(:,16); 
    load = mpc0.bus(:,3); %TWH
    plcost = gdp./load;
    plcost = plcost/10; 
    plcost(isnan(plcost))=70;
    plcost = plcost*1.05^(period(stage)-2020);
    plcost = mean(plcost);
    %%
    CtgProb = probdis(:,stage);
    CtgProb = CtgProb/sum(CtgProb);
    % [ratio, Ploadcold, Ploadheat] = calculateDisasterRatios(mpcdisasters0, period(stage), Pload, mpc0);

    if stage == 1
        MpConstraints = [MpConstraints, 4000 <= BScapcent(stage) <= 30000, ...
            0 <= NGcap(stage), ...
            0 <= NGCCScap(stage), ...
            0 <= COALcap(stage), ...
            0 <= COALCCScap(stage), ...
            NGCCScap(stage) <= COALCCScap(stage), ...
            firpower == COALcap(stage) + NGcap(stage), ...
            maxHycap <= Hydropowercap(stage) <= 7*maxHycap, ...
            0 <= Biopowercap(stage) <= 20000, ...
            0 <= BiopowerCCScap(stage) <= 30000, ...
            0 <= Geothermalcap(stage) <= 10000, ...
            0 <= Nuclearcap(stage) <= 120000, ...
            0 <= OFFWTcap(stage) <= mpcre0.OFFWTarea*3, ...
            0 <= sum(ONWTcap(:,stage)) <= mpcre0.ONWTarea*3, ...
            0 <= sum(UPVcap(:,stage))/3 + sum(CSPcap(:,stage))*2 <= mpcre0.UPVarea, ...
            0 <= sum(DPVcap(:,stage)) <= mpcre0.DPVarea*70, ...
            0 <= CSPcap(:,stage) <= sum(mpc0.bus(1:length(find(mpc0.bus(:,3)~=0)),5)/2), ...
            0 <= UPVcap(:,stage) <= sum(mpc0.bus(1:length(find(mpc0.bus(:,3)~=0)),5)*3), ...
            0 <= DPVcap(:,stage) <= sum(mpc0.bus(1:length(find(mpc0.bus(:,3)~=0)),6)*70), ...
            0 <= ONWTcap(:,stage) <= sum(mpc0.bus(1:length(find(mpc0.bus(:,3)~=0)),7)*3)];
        
    else
        MpConstraints = [MpConstraints, BScapcent(stage-1) <= BScapcent(stage) <= 30000, ...
            NGcap(stage-1) >= NGcap(stage), ...
            NGCCScap(stage-1) <= NGCCScap(stage), ...
            COALcap(stage-1) >= COALcap(stage), ...
            5000 <= COALCCScap(stage-1) <= COALCCScap(stage), ...
            3*NGCCScap(stage) <= COALCCScap(stage), ...
            0.2*firpower <= NGcap(stage), ...
            0.1*firpower <= COALcap(stage), ...
            firpower >= COALcap(stage) + NGcap(stage), ...
            Hydropowercap(stage-1) <= Hydropowercap(stage) <= 7*maxHycap, ...
            Biopowercap(stage-1) <= Biopowercap(stage) <= 30000, ...
            2000 <= BiopowerCCScap(stage-1) <= BiopowerCCScap(stage) <= 40000, ...
            Geothermalcap(stage-1) <= Geothermalcap(stage) <= 10000, ...
            
            5000 <= Nuclearcap(stage-1) <= Nuclearcap(stage) <= 120000, ...
            OFFWTcap(stage-1) <= OFFWTcap(stage) <= mpcre0.OFFWTarea*3, ...

            0 <= sum(ONWTcap(:,stage)) <= mpcre0.ONWTarea*3, ...
            ONWTcap(:,stage-1) <= ONWTcap(:,stage), ...
            0 <= sum(UPVcap(stage))/3 + sum(CSPcap(:,stage))*2 <= mpcre0.UPVarea, ...
            UPVcap(:,stage-1) <= UPVcap(:,stage), ...
            CSPcap(:,stage-1) <= CSPcap(:,stage), ...
            0 <= sum(DPVcap(:,stage)) <= mpcre0.DPVarea*70, ...
            DPVcap(:,stage-1) <= DPVcap(:,stage), ...
            CSPcap(:,stage-1) <= CSPcap(:,stage) <= sum(mpc0.bus(1:length(find(mpc0.bus(:,3)~=0)),5)/2), ...
            UPVcap(:,stage-1) <= UPVcap(:,stage) <= sum(mpc0.bus(1:length(find(mpc0.bus(:,3)~=0)),5)*3), ...
            DPVcap(:,stage-1) <= DPVcap(:,stage) <= sum(mpc0.bus(1:length(find(mpc0.bus(:,3)~=0)),6)*70), ...
            ONWTcap(:,stage-1) <= ONWTcap(:,stage) <= sum(mpc0.bus(1:length(find(mpc0.bus(:,3)~=0)),7)*3)];
    end

   
    for i=1:numscen

        Constraints = [Constraints, (-PBSchcent(:,i,stage)+PBSdiscent(:,i,stage)+PNG(:,i,stage)+PNGCCS(:,i,stage)+...
            PCOAL(:,i,stage)+PCOALCCS(:,i,stage)+PBiopower(:,i,stage)+PBiopowerCCS(:,i,stage)+...
            PGeothermal(:,i,stage)+PHydropower(:,i,stage)+PNuclear(:,i,stage)+POFFWT(:,i,stage))' - pl + plc(:,:,i,stage) + ...
            PONWT(:,:,i,stage) + PUPV(:,:,i,stage) + PDPV(:,:,i,stage) + PCSP(:,:,i,stage) == 0];

        Constraints = [Constraints, 0 <= plc(:,:,i,stage) <= pl];
        Constraints = [Constraints, 0 <= qlc(:,:,i,stage) <= 0.25*pl];
for j=1:time
        Constraints = [Constraints, ...
            0 <= PUPV(:,j,i,stage) <= UPVdeg*UPVcap(:,stage) * pv(j), ...
            0 <= PDPV(:,j,i,stage) <= DPVdeg*DPVcap(:,stage) * pv(j), ...
            0 <= PCSP(:,j,i,stage) <= CSPdeg*CSPcap(:,stage) * pv(j),...
            0 <= PONWT(:,j,i,stage) <= ONWTdeg*ONWTcap(:,stage) * wt(j)];
end
        Constraints = [Constraints, 0 <= POFFWT(:,i,stage) <= OFFWTdeg*OFFWTcap(:,stage)* wt];

    
        Constraints = [Constraints, ...
                0 <= PBSchcent(:,i,stage) <= PBSchmax*BScapcent(:,stage), ...
                0 <= PBSdiscent(:,i,stage) <= PBSdismax*BScapcent(:,stage), ...
                (BSdeg*SOCmin)*BScapcent(:,stage) <= SOCcent(:,i,stage) <= (BSdeg*SOCmax)*BScapcent(:,stage)];


        for j=1:time/24
            Constraints = [Constraints, ...
                SOCcent((j-1)*24+2:j*24,i,stage) == SOCcent((j-1)*24+1:j*24-1,i,stage) + PBScheff*PBSchcent((j-1)*24+1:j*24-1,i,stage) - PBSdiscent((j-1)*24+1:j*24-1,i,stage)/PBSdiseff, ...
                SOCcent((j-1)*24+1,i,stage) == (BSdeg*SOCinitial)*BScapcent(:,stage), ...
                SOCcent(j*24,i,stage) == (BSdeg*SOCinitial)*BScapcent(:,stage)];
        end
    end


    Constraints = [Constraints, ...
        0 <= PNG(:,:,stage) <= NGdeg*NGcap(:,stage), ...
        0 <= PNGCCS(:,:,stage) <= NGCCSdeg*NGCCScap(:,stage), ...
        0 <= PCOAL(:,:,stage) <= COALdeg*COALcap(:,stage), ...
        0 <= PCOALCCS(:,:,stage) <= COALCCSdeg*COALCCScap(:,stage), ...
        0 <= PBiopower(:,:,stage) <= Biopowerdeg*Biopowercap(:,stage), ...
        0 <= PBiopowerCCS(:,:,stage) <= BiopowerCCSdeg*BiopowerCCScap(:,stage), ...
        0 <= PGeothermal(:,:,stage) <= Geothermaldeg*Geothermalcap(:,stage), ...
        0 <= PHydropower(:,:,stage) <= Hydropowerdeg*Hydropowercap(:,stage), ...
        0 <= PNuclear(:,:,stage) <= Nucleardeg*Nuclearcap(:,stage)];

    Constraints = [Constraints, 0 <= (-sum(sum(PBiopowerCCS(:,:,stage), 1)'.* CtgProb)*0.35 + 0.865*0.05*sum(sum(PCOALCCS(:,:,stage), 1)' .* CtgProb) + ...
        0.865*sum(sum(PCOAL(:,:,stage), 1)' .* CtgProb) + 0.312*sum(sum(PNG(:,:,stage), 1)' .* CtgProb) + 0.312*0.05*sum(sum(PNGCCS(:,:,stage), 1)' .* CtgProb))*8760/time <= carlim*10^8];


    discount = 0;
    for i=1:5
        discount = discount + (1+discountrate)^(-i);
    end

   Constraints = [Constraints, (sum((squeeze(sum(plc(:,:,:,stage),2)))'* CtgProb)) >= reliabilitylimit(stage)*100000000/(5*1000*8760/time)];

    VAROM(stage) = (1+discountrate)^(2025-period(stage))*huilv*8760/time*discount*...
        (NGvarom*sum(sum(PNG(:,:,stage), 1)'.* CtgProb) + NGCCSvarom*sum(sum(PNGCCS(:,:,stage), 1)'.* CtgProb) + ...
        COALvarom*sum(sum(PCOAL(:,:,stage), 1)'.* CtgProb) + COALCCSvarom*sum(sum(PCOALCCS(:,:,stage), 1)'.* CtgProb) + ...
        Biopowervarom*sum(sum(PBiopower(:,:,stage), 1)'.* CtgProb) + Nuclearvarom*sum(sum(PNuclear(:,:,stage), 1)'.* CtgProb)+ BiopowerCCSvarom*sum(sum(PBiopowerCCS(:,:,stage), 1)'.* CtgProb));%+...
        %2.7*210*sum(sum(PNGCCS(:,:,stage), 1)'.* CtgProb) + 2.7*210*sum(sum(PNG(:,:,stage), 1)'.* CtgProb) + 1000*0.3*sum(sum(PCOAL(:,:,stage), 1)'.* CtgProb) + 1000*0.3*sum(sum(PCOALCCS(:,:,stage), 1)'.* CtgProb));
    %BSvarom*squeeze(sum(sum((PBSch + PBSdis), 1)))'* CtgProb

    lcoe(stage) = (1+discountrate)^(2025-period(stage))*8760/time*...
        (sum((pvlcoe'*squeeze(sum(PDPV(:,:,:,stage),2)))'* CtgProb) + ...
        sum((pvlcoe'*squeeze(sum(PUPV(:,:,:,stage),2)))'* CtgProb)+...
        sum((wtlcoe'*squeeze(sum(PONWT(:,:,:,stage),2)))'* CtgProb)+...
        CSPlcoe*sum(sum(sum(PCSP(:,:,:,stage),1),2)'.* CtgProb)+...
        OFFWTlcoe*sum(sum(POFFWT(:,:,stage), 1)'.* CtgProb));

    rela(stage) = (1+discountrate)^(2025-period(stage))*discount*1000*8760/time*(sum((plcost'*squeeze(sum(plc(:,:,:,stage),2)))'* CtgProb));

    if stage == 1
        inv(stage) = (1+discountrate)^(2025-period(stage))*huilv*1000*...
            (Nuclearcap(:,stage)*Nuclearinv + NGCCScap(:,stage)*NGCCSinv +...
            COALCCScap(:,stage)*COALCCSinv + Biopowercap(:,stage)*Biopowerinv + ...
            BiopowerCCScap(:,stage)*BiopowerCCSinv +...
            Geothermalcap(:,stage)*Geothermalinv + (Hydropowercap(:,stage)-maxHycap)*Hydropowerinv);
    else
        inv(stage) = (1+discountrate)^(2025-period(stage))*huilv*1000*...
            ((Nuclearcap(:,stage)-Nuclearcap(:,stage-1))*Nuclearinv +  (NGCCScap(:,stage)-NGCCScap(:,stage-1))*NGCCSinv +...
            (COALCCScap(:,stage)-COALCCScap(:,stage-1))*COALCCSinv + (Biopowercap(:,stage)-Biopowercap(:,stage-1))*Biopowerinv + ...
            (BiopowerCCScap(:,stage)-BiopowerCCScap(:,stage-1))*BiopowerCCSinv +...
            (Geothermalcap(:,stage)-Geothermalcap(:,stage-1))*Geothermalinv + (Hydropowercap(:,stage)-Hydropowercap(:,stage-1))*Hydropowerinv);
%(COALcap(:,stage)-COALcap(:,stage-1))*COALinv + (NGcap(:,stage)-NGcap(:,stage-1))*NGinv +
    end
    FIXOM(stage) = (1+discountrate)^(2025-period(stage))*huilv*1000*discount*(Nuclearcap(:,stage)*Nuclearfixom + NGcap(:,stage)*NGfixom + NGCCScap(:,stage)*NGCCSfixom +...
        COALcap(:,stage)*COALfixom + COALCCScap(:,stage)*COALCCSfixom + Biopowercap(:,stage)*Biopowerfixom + BiopowerCCScap(:,stage)*BiopowerCCSfixom + ...
        Geothermalcap(:,stage)*Geothermalfixom + Hydropowercap(:,stage)*Hydropowerfixom +...
        BScapcent(:,stage) * BSfixom);

    carboncost(stage) = (1+discountrate)^(2025-period(stage))*8760/time*(-sum(sum(PBiopowerCCS(:,:,stage), 1)'.* CtgProb)*0.35 + 0.865*0.05*sum(sum(PCOALCCS(:,:,stage), 1)' .* CtgProb) + ...
        0.865*sum(sum(PCOAL(:,:,stage), 1)' .* CtgProb) + 0.312*sum(sum(PNG(:,:,stage), 1)' .* CtgProb) + 0.312*0.05*sum(sum(PNGCCS(:,:,stage), 1)' .* CtgProb))* carcost;

    obj(stage) = (FIXOM(stage) + inv(stage)+ rela(stage)  + VAROM(stage) + lcoe(stage))/10000/10000;% + carboncost(stage)/10000/10000; 
end
Con = [MpConstraints, Constraints];
Objective = sum(obj);

ops = sdpsettings('verbose', 0, 'solver', 'mosek');
results = optimize(Con, Objective, ops);

if results.problem == 0
    result.BScapcent = value(BScapcent);
    result.NGcap = value(NGcap);
    result.NGCCScap = value(NGCCScap);
    result.COALcap = value(COALcap);
    result.COALCCScap = value(COALCCScap);
    result.Biopowercap = value(Biopowercap);
    result.BiopowerCCScap = value(BiopowerCCScap);
    result.CSPcap = value(CSPcap);
    result.Geothermalcap = value(Geothermalcap);
    result.Hydropowercap = value(Hydropowercap);
    result.Nuclearcap = value(Nuclearcap);
    result.OFFWTcap = value(OFFWTcap);
    result.ONWTcap = value(ONWTcap);
    result.UPVcap = value(UPVcap);
    result.DPVcap = value(DPVcap);

    result.PBSchcent = value(PBSchcent);
    result.PBSdiscent = value(PBSdiscent);
    result.SOCcent = value(SOCcent);

    result.PNG = value(PNG);
    result.PNGCCS = value(PNGCCS);
    result.PCOAL = value(PCOAL);
    result.PCOALCCS = value(PCOALCCS);
    result.PBiopower = value(PBiopower);
    result.PBiopowerCCS = value(PBiopowerCCS);
    result.PCSP = value(PCSP);
    result.PGeothermal = value(PGeothermal);
    result.PHydropower = value(PHydropower);
    result.PNuclear = value(PNuclear);
    result.POFFWT = value(POFFWT);
    result.PONWT = value(PONWT);
    result.PUPV = value(PUPV);
    result.PDPV = value(PDPV);
    result.plc = value(plc);
    result.qlc = value(qlc);

    result.varom = value(VAROM)/10000/10000;
    result.lcoe = value(lcoe)/10000/10000;
    result.rela = value(rela)/10000/10000;
    result.inv = value(inv)/10000/10000;
    result.FIXOM = value(FIXOM)/10000/10000;
    result.carboncost = value(carboncost)/10000/10000;
    result.obj = value(obj);
    result.time = toc;
else
    fprintf('%s %d\n', mpc0.proname, year);
end
end