function [A,T,h,c,eq,ineq] = getdispara(mpc0, mpcre0, equipment, mpcdisasters0, mpc_model_load20, Pload, WT, PV, rateload, scen, firpower)
period = [2025 2030 2035 2040 2045 2050];
num_stage = length(period);

time = 24;
huilv = 7;
discountrate = 0.03;

wttemp=[];
pvtemp=[];
for qqq=1:time
    wttemp = [wttemp,55555+qqq];
    pvtemp = [pvtemp,66666+qqq];
end
wt = wttemp;
pv1 = pvtemp+1;
pv2 = pvtemp+2;
pv3 = pvtemp+3;

numscen = height(mpcdisasters0.regcount)+1;
maxNGcap = mpc_model_load20.loadgas;
maxCOALcap = max(mpc_model_load20.loadfire - maxNGcap,0);
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

numequipment = 11*1*num_stage + 1*num_stage*4;

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

plc = sdpvar(time,numscen,num_stage,'full');
qlc = sdpvar(1,time,numscen,num_stage,'full');

MpConstraints =[];
Constraints = [];
for stage=1:length(period)
    year = sprintf('yr%d', period(stage));
    equipment0 = equipment.(year);
    %%
    if scen == 1
        carlim = equipment0.carlimNDC*mpc_model_load20.ratio; %10^8t
        carcost = equipment0.carcostNDC;
    elseif scen == 2
        carlim = equipment0.carlimCN50*mpc_model_load20.ratio; % 10^8t
        carcost = equipment0.carcostCN50;
    elseif scen == 3
        carlim = equipment0.carlimGM20*mpc_model_load20.ratio; %10^8t
        carcost = equipment0.carcostGM20;
    end

    pltemp = [];
    for qqq=1:time
        pltemp = [pltemp,rateload(stage)*(8888+4*qqq)];
    end
    pl = pltemp;


    gdp = mpc0.bus(:,16);
    load = mpc0.bus(:,3); %TWH
    plcost = gdp./load;
    plcost = plcost/10; %
    plcost(isnan(plcost))=70;
    plcost = plcost*1.05^(period(stage)-2020);
    plcost = mean(plcost);

    CtgProb = zeros(numscen,1);
    duration = mpcdisasters0.regcount.AverageDuration;

    for i = 2:numscen
        slope = mpcdisasters0.regcount.CountSlope(i-1);
        count = mpcdisasters0.regcount.Count2017(i-1);
        ratioyear = 1 + slope*(period(stage)-2017);
        if ratioyear<0
            ratioyear = 0;
        end
        CtgProb(i) = ratioyear*duration(i-1)/8760;
    end
    CtgProb(1) = 1 - sum(CtgProb(2:end));
    [ratio, Ploadcold, Ploadheat] = calculateDisasterRatios(mpcdisasters0, period(stage), Pload, mpc0);
    if time == 24
        Ploadreshpe = reshape(Ploadheat,[size(Pload,1),24,365]);
        Ploadreshpe = mean(Ploadreshpe,3);
        Ploadreshpe = squeeze(Ploadreshpe);
        plheat = rateload(stage)*Ploadreshpe;

        Ploadreshpe = reshape(Ploadcold,[size(Pload,1),24,365]);
        Ploadreshpe = mean(Ploadreshpe,3);
        Ploadreshpe = squeeze(Ploadreshpe);
        plcold = rateload(stage)*Ploadreshpe;
    end
    CtgProb = CtgProb.*(ratio');


    loadequipmentdata();

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

    Constraints = [Constraints, 0 <= (-sum(sum(PBiopowerCCS(:,:,stage), 1)'.* CtgProb)*0.35 + 0.865*0.05*sum(sum(PCOALCCS(:,:,stage), 1)' .* CtgProb) + ...
        0.865*sum(sum(PCOAL(:,:,stage), 1)' .* CtgProb) + 0.312*sum(sum(PNG(:,:,stage), 1)' .* CtgProb) + 0.312*0.05*sum(sum(PNGCCS(:,:,stage), 1)' .* CtgProb))*8760/time <= carlim*10^8];

    %Constraints = [Constraints, 0.2*rateload(stage)*168000 <= 1000*8760/time*sum(plcost*sum(plc(:,:,stage),2)'* CtgProb) <= rateload(stage)*168000];

    for i=1:numscen

        Constraints = [Constraints, (-PBSchcent(:,i,stage)+PBSdiscent(:,i,stage)+PNG(:,i,stage)+PNGCCS(:,i,stage)+...
            PCOAL(:,i,stage)+PCOALCCS(:,i,stage)+PBiopower(:,i,stage)+PBiopowerCCS(:,i,stage)+...
            PGeothermal(:,i,stage)+PHydropower(:,i,stage)+PNuclear(:,i,stage)+POFFWT(:,i,stage))' - pl + plc(:,i,stage)' + ...
            PONWT(:,:,i,stage) + PUPV(:,:,i,stage) + PDPV(:,:,i,stage) + PCSP(:,:,i,stage) == 0];

        Constraints = [Constraints, plc(:,i,stage)' <= pl];
        Constraints = [Constraints, qlc(:,:,i,stage) <= 0.25*pl];
        UPVdeg=1+stage;
        DPVdeg=1+stage;
        CSPdeg=1+stage;
        ONWTdeg = 1+stage;

        for j=1:time
            Constraints = [Constraints, PONWT(:,j,i,stage) <= ONWTdeg*ONWTcap(:,stage) .* wt];
        end
        Constraints = [Constraints, ...
            PUPV(:,:,i,stage) <= UPVdeg*UPVcap(:,stage) * pv1, ...
            PDPV(:,:,i,stage) <= DPVdeg*DPVcap(:,stage) * pv2, ...
            PCSP(:,:,i,stage) <= CSPdeg*CSPcap(:,stage) * pv3];

        %         for j=1:time
        %             Constraints = [Constraints, ...
        %                 PBSchcent(j,i,stage) <= PBSchmax*BScapcent(:,stage), ...
        %                 PBSdiscent(j,i,stage) <= PBSdismax*BScapcent(:,stage)];
        %         end

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
        PNG(:,:,stage) <= NGdeg*NGcap(:,stage), ...
        PNGCCS(:,:,stage) <= NGCCSdeg*NGCCScap(:,stage), ...
        PCOAL(:,:,stage) <= COALdeg*COALcap(:,stage), ...
        PCOALCCS(:,:,stage) <= COALCCSdeg*COALCCScap(:,stage), ...
        PBiopower(:,:,stage) <= Biopowerdeg*Biopowercap(:,stage), ...
        PBiopowerCCS(:,:,stage) <= BiopowerCCSdeg*BiopowerCCScap(:,stage), ...
        PGeothermal(:,:,stage) <= Geothermaldeg*Geothermalcap(:,stage), ...
        PHydropower(:,:,stage) <= Hydropowerdeg*Hydropowercap(:,stage), ...
        PNuclear(:,:,stage) <= Nucleardeg*Nuclearcap(:,stage),...
        POFFWT(:,:,stage) <= OFFWTdeg*OFFWTcap(:,stage)];


    discount = 0;
    for i=1:5
        discount = discount + (1+discountrate)^(-i);
    end

    VAROM(stage) = (1+discountrate)^(2025-period(stage))*huilv*(NGvarom*sum(sum(PNG(:,:,stage), 1)'.* CtgProb) + NGCCSvarom*sum(sum(PNGCCS(:,:,stage), 1)'.* CtgProb) + ...
        COALvarom*sum(sum(PCOAL(:,:,stage), 1)'.* CtgProb) + COALCCSvarom*sum(sum(PCOALCCS(:,:,stage), 1)'.* CtgProb) + ...
        Biopowervarom*sum(sum(PBiopower(:,:,stage), 1)'.* CtgProb) + Nuclearvarom*sum(sum(PNuclear(:,:,stage), 1)'.* CtgProb)+ BiopowerCCSvarom*sum(sum(PBiopowerCCS(:,:,stage), 1)'.* CtgProb));
    %BSvarom*squeeze(sum(sum((PBSch + PBSdis), 1)))'* CtgProb

    lcoe(stage) = (1+discountrate)^(2025-period(stage))*...
        (sum((pvlcoe'*squeeze(sum(PDPV(:,:,:,stage),2)))'* CtgProb) + ...
        sum((pvlcoe'*squeeze(sum(PUPV(:,:,:,stage),2)))'* CtgProb)+...
        sum((wtlcoe'*squeeze(sum(PONWT(:,:,:,stage),2)))'* CtgProb)+...
        CSPlcoe*sum(sum(sum(PCSP(:,:,:,stage),1),2)'.* CtgProb)+...
        OFFWTlcoe*sum(sum(POFFWT(:,:,stage), 1)'.* CtgProb));

    rela(stage) = (1+discountrate)^(2025-period(stage))*discount*1000*sum(sum(plcost*sum(plc(:,:,stage),2)')* CtgProb);

    if stage == 1
        inv(stage) = (1+discountrate)^(2025-period(stage))*huilv*1000*...
            (Nuclearcap(:,stage)*Nuclearinv + NGCCScap(:,stage)*NGCCSinv +...
            COALCCScap(:,stage)*COALCCSinv + Biopowercap(:,stage)*Biopowerinv + ...
            BiopowerCCScap(:,stage)*BiopowerCCSinv +...
            Geothermalcap(:,stage)*Geothermalinv + (Hydropowercap(:,stage)-maxHycap)*Hydropowerinv);
    else
        inv(stage) = (1+discountrate)^(2025-period(stage))*huilv*1000*...
            ((Nuclearcap(:,stage)-Nuclearcap(:,stage-1))*Nuclearinv + (NGCCScap(:,stage)-NGCCScap(:,stage-1))*NGCCSinv +...
            (COALCCScap(:,stage)-COALCCScap(:,stage-1))*COALCCSinv + (Biopowercap(:,stage)-Biopowercap(:,stage-1))*Biopowerinv + ...
            (BiopowerCCScap(:,stage)-BiopowerCCScap(:,stage-1))*BiopowerCCSinv +...
            (Geothermalcap(:,stage)-Geothermalcap(:,stage-1))*Geothermalinv + (Hydropowercap(:,stage)-Hydropowercap(:,stage-1))*Hydropowerinv);
    end
    %(COALcap(:,stage)-COALcap(:,stage-1))*COALinv + (NGcap(:,stage)-NGcap(:,stage-1))*NGinv + 
    FIXOM(stage) = (1+discountrate)^(2025-period(stage))*huilv*1000*(Nuclearcap(:,stage)*Nuclearfixom + NGcap(:,stage)*NGfixom + NGCCScap(:,stage)*NGCCSfixom +...
        COALcap(:,stage)*COALfixom + COALCCScap(:,stage)*COALCCSfixom + Biopowercap(:,stage)*Biopowerfixom + BiopowerCCScap(:,stage)*BiopowerCCSfixom + ...
        Geothermalcap(:,stage)*Geothermalfixom + Hydropowercap(:,stage)*Hydropowerfixom +...
        BScapcent(:,stage) * BSfixom);

    carboncost(stage) = (1+discountrate)^(2025-period(stage))*(-sum(sum(PBiopowerCCS(:,:,stage), 1)'.* CtgProb)*0.35 + 0.865*0.05*sum(sum(PCOALCCS(:,:,stage), 1)' .* CtgProb) + ...
        0.865*sum(sum(PCOAL(:,:,stage), 1)' .* CtgProb) + 0.312*sum(sum(PNG(:,:,stage), 1)' .* CtgProb) + 0.312*0.05*sum(sum(PNGCCS(:,:,stage), 1)' .* CtgProb))* carcost;

    %Constraints = [Constraints, rela(stage)/10000/10000>=rateload(stage)*111000];
    obj(stage) = (FIXOM(stage) + inv(stage) + rela(stage) + VAROM(stage) + lcoe(stage))/10000/10000; %+ carboncost(stage)/10000/10000;
end
Con = [MpConstraints, Constraints];
Objective = sum(obj);

options = sdpsettings('solver','gurobi','verbose',0);
[model,recoverymodel,diagnostic,internalmodel] = export(Con,Objective);

eq = size(find(model.sense=='='),1);
ineq = size(find(model.sense=='<'),1);
% A = model.A(:,numequipment+1:end);
% T = model.A(:,1:numequipment);
% h = model.rhs;
% c = model.obj(numequipment+1:end);
A1 = [full(model.A),[zeros(eq,ineq);eye(ineq)]];
A = A1(:,numequipment+1:end);
T = A1(:,1:numequipment);
h = model.rhs;% h+Tx
c = [model.obj(numequipment+1:end);zeros(ineq,1)];
A = sparse(A);
T = sparse(T);
h = sparse(h);
c = sparse(c);
end