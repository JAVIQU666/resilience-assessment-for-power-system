function [A,T,h,c,eq,ineq] = getnorpara(mpc0, mpcre0, equipment, mpc_model_load20, Pload, WT, PV, rateload, scen, firpower)
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

BScap = sdpvar(1,num_stage);
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



PONWT = sdpvar(1,time,num_stage);
PUPV = sdpvar(1,time,num_stage);
PDPV = sdpvar(1,time,num_stage);
PCSP = sdpvar(1,time,num_stage);

PBSch = sdpvar(time,num_stage);
PBSdis = sdpvar(time,num_stage);
SOC = sdpvar(time,num_stage);

PNG = sdpvar(time,num_stage);
PNGCCS = sdpvar(time,num_stage);
PCOAL = sdpvar(time,num_stage);
PCOALCCS = sdpvar(time,num_stage);
PBiopower = sdpvar(time,num_stage);
PBiopowerCCS = sdpvar(time,num_stage);
PGeothermal = sdpvar(time,num_stage);
PHydropower = sdpvar(time,num_stage);
PNuclear = sdpvar(time,num_stage);
POFFWT = sdpvar(time,num_stage);

plc = sdpvar(1,time,num_stage,'full');
qlc = sdpvar(1,time,num_stage,'full');

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
        carlim = equipment0.carlimCN50*mpc_model_load20.ratio; %10^8t
        carcost = equipment0.carcostCN50;
    elseif scen == 3
        carlim = equipment0.carlimGM20*mpc_model_load20.ratio; %10^8t
        carcost = equipment0.carcostGM20;
    end

    %pl = rateload(stage)*2*Pload(:,1:time);
    pltemp = [];
    for qqq=1:time
        pltemp = [pltemp,rateload(stage)*(8888+4*qqq)];
    end
    pl = pltemp';

    loadequipmentdata();

    if stage == 1
        MpConstraints = [MpConstraints, 4000 <= BScap(stage) <= 30000, ...
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
        MpConstraints = [MpConstraints, BScap(stage-1) <= BScap(stage) <= 30000, ...
            NGcap(stage-1) >= NGcap(stage), ...
            NGCCScap(stage-1) <= NGCCScap(stage), ...
            COALcap(stage-1) >= COALcap(stage), ...
            COALCCScap(stage-1) <= COALCCScap(stage), ...
            3*NGCCScap(stage) <= COALCCScap(stage), ...
            0.2*firpower <= NGcap(stage), ...
            0.1*firpower <= COALcap(stage), ...
            firpower >= COALcap(stage)  + NGcap(stage) , ...
            Hydropowercap(stage-1) <= Hydropowercap(stage) <= 7*maxHycap, ...
            Biopowercap(stage-1) <= Biopowercap(stage) <= 20000, ...
            BiopowerCCScap(stage-1) <= BiopowerCCScap(stage) <= 10000, ...
            Geothermalcap(stage-1) <= Geothermalcap(stage) <= 10000, ...
            
            8000 <= Nuclearcap(stage-1) <= Nuclearcap(stage) <= 120000, ...
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

    UPVdeg=1+stage;
    DPVdeg=1+stage;
    CSPdeg=1+stage;
    ONWTdeg = 1+stage;
    for j=1:time
        Constraints = [Constraints, PONWT(:,j,stage) <= ONWTdeg*ONWTcap(:,stage)*wt(j)];
        Constraints = [Constraints, PUPV(:,j,stage) <= UPVdeg*UPVcap(:,stage)*pv1(j)];
        Constraints = [Constraints, PDPV(:,j,stage) <= DPVdeg*DPVcap(:,stage)*pv2(j)];
        Constraints = [Constraints, PCSP(:,j,stage) <= CSPdeg*CSPcap(:,stage)*pv3(j)];
    end

    Constraints = [Constraints, PNG(:,stage)-PBSch(:,stage)+PBSdis(:,stage)+PNGCCS(:,stage)+...
        PCOAL(:,stage)+PCOALCCS(:,stage)+PBiopower(:,stage)+PBiopowerCCS(:,stage)+...
        PGeothermal(:,stage)+PHydropower(:,stage)+PNuclear(:,stage)+POFFWT(:,stage) - pl + plc(:,:,stage)' + ...
        PONWT(:,:,stage)' + PUPV(:,:,stage)' + PDPV(:,:,stage)' + PCSP(:,:,stage)' == 0];

    Constraints = [Constraints, plc(:,:,stage) <= pl'];
    Constraints = [Constraints, qlc(:,:,stage) <= 0.25*pl'];


    %     Constraints = [Constraints, PBSch(:,stage) <= PBSchmax*BScap(:,stage)];
    %     Constraints = [Constraints, PBSdis(:,stage) <= PBSdismax*BScap(:,stage)];
    Constraints = [Constraints, 0 <= PBSch(:,stage) <= PBSchmax*BScap(:,stage)];
    Constraints = [Constraints, 0 <= PBSdis(:,stage) <= PBSdismax*BScap(:,stage)];
    Constraints = [Constraints, (BSdeg*SOCmin)*BScap(:,stage) <= SOC(:,stage) <= (BSdeg*SOCmax)*BScap(:,stage)];


    for j=1:time/24
        Constraints = [Constraints, SOC((j-1)*24+2:j*24,stage) == SOC((j-1)*24+1:j*24-1,stage) + PBScheff*PBSch((j-1)*24+1:j*24-1,stage) - PBSdis((j-1)*24+1:j*24-1,stage)/PBSdiseff];
        Constraints = [Constraints, SOC((j-1)*24+1,stage) == (BSdeg*SOCinitial)*BScap(:,stage)];
        Constraints = [Constraints, SOC(j*24,stage) == (BSdeg*SOCinitial)*BScap(:,stage)];
    end



    Constraints = [Constraints, PNG(:,stage) <= NGdeg*NGcap(:,stage)];
    Constraints = [Constraints, PNGCCS(:,stage) <= NGCCSdeg*NGCCScap(:,stage)];
    Constraints = [Constraints, PCOAL(:,stage) <= COALdeg*COALcap(:,stage)];
    Constraints = [Constraints, PCOALCCS(:,stage) <= COALCCSdeg*COALCCScap(:,stage)];
    Constraints = [Constraints, PBiopower(:,stage) <= Biopowerdeg*Biopowercap(:,stage)];
    Constraints = [Constraints, PBiopowerCCS(:,stage) <= BiopowerCCSdeg*BiopowerCCScap(:,stage)];
    Constraints = [Constraints, PGeothermal(:,stage) <= Geothermaldeg*Geothermalcap(:,stage)];
    Constraints = [Constraints, PHydropower(:,stage) <= Hydropowerdeg*Hydropowercap(:,stage)];
    Constraints = [Constraints, PNuclear(:,stage) <= Nucleardeg*Nuclearcap(:,stage)];
    Constraints = [Constraints, POFFWT(:,stage) <= OFFWTdeg*OFFWTcap(:,stage)];


    Constraints = [Constraints, 0 <= (-sum(sum(PBiopowerCCS(:,stage)))*0.35 + ...
        0.865*0.05*sum(sum(PCOALCCS(:,stage))) + 0.865*sum(sum(PCOAL(:,stage))) + 0.312*sum(sum(PNG(:,stage))) + ...
        0.312*0.05*sum(sum (PNGCCS(:,stage)))) <= carlim/8760*time*10^8];

    discount = 0;
    for i=1:5
        discount = discount + (1+discountrate)^(-i);
    end
    %Constraints = [Constraints, (1+discountrate)^(2025-period(stage))*discount*70*1000*8760/time*sum(sum(plc(:,:,stage))) >= rateload(stage)*168000];

    VAROM(stage) = (1+discountrate)^(2025-period(stage))*huilv*...
        (NGvarom*sum(sum(PNG(:,stage))) + NGCCSvarom*sum(sum (PNGCCS(:,stage))) + ...
        COALvarom*sum(sum(PCOAL(:,stage))) + COALCCSvarom*sum(sum(PCOALCCS(:,stage))) + Biopowervarom*sum(sum(PBiopower(:,stage))) +...
        Nuclearvarom*sum(sum(PNuclear(:,stage)))+ BiopowerCCSvarom*sum(sum(PBiopowerCCS(:,stage))));
    lcoe(stage) = (1+discountrate)^(2025-period(stage))*...
        (pvlcoe'*sum(PDPV(:,:,stage),2) + pvlcoe'*sum(PUPV(:,:,stage),2) + ...
        wtlcoe'*sum(PONWT(:,:,stage),2) + CSPlcoe*sum(sum(PCSP(:,:,stage)))+...
        ONWTlcoe*sum(POFFWT(:,stage), 1));
    rela(stage) = (1+discountrate)^(2025-period(stage))*discount*70*1000*sum(sum(plc(:,:,stage)));
    if stage == 1
        inv(stage) = (1+discountrate)^(2025-period(stage))*huilv*1000*...
            (Nuclearcap(:,stage)*Nuclearinv + NGCCScap(:,stage)*NGCCSinv +...
             COALCCScap(:,stage)*COALCCSinv + Biopowercap(:,stage)*Biopowerinv +...
            Geothermalcap(:,stage)*Geothermalinv + (Hydropowercap(:,stage)-maxHycap)*Hydropowerinv +...
            BiopowerCCScap(:,stage)*BiopowerCCSinv);
    else
        inv(stage) = (1+discountrate)^(2025-period(stage))*huilv*1000*...
            ((Nuclearcap(:,stage)-Nuclearcap(:,stage-1))*Nuclearinv + (NGCCScap(:,stage)-NGCCScap(:,stage-1))*NGCCSinv +...
            (COALCCScap(:,stage)-COALCCScap(:,stage-1))*COALCCSinv + (Biopowercap(:,stage)-Biopowercap(:,stage-1))*Biopowerinv +...
            (Geothermalcap(:,stage)-Geothermalcap(:,stage-1))*Geothermalinv + (Hydropowercap(:,stage)-Hydropowercap(:,stage-1))*Hydropowerinv +...
            (BiopowerCCScap(:,stage)-BiopowerCCScap(:,stage-1))*BiopowerCCSinv);
    end

    FIXOM(stage) = (1+discountrate)^(2025-period(stage))*huilv*1000*...
        (Nuclearcap(:,stage)*Nuclearfixom + NGcap(:,stage)*NGfixom + NGCCScap(:,stage)*NGCCSfixom +...
        COALcap(:,stage)*COALfixom + COALCCScap(:,stage)*COALCCSfixom + Biopowercap(:,stage)*Biopowerfixom +...
        Geothermalcap(:,stage)*Geothermalfixom + Hydropowercap(:,stage)*Hydropowerfixom +...
        BScap(:,stage) * BSfixom + BiopowerCCScap(:,stage)*BiopowerCCSfixom);

    carboncost(stage) = (1+discountrate)^(2025-period(stage))*...
        (-sum(sum(PBiopowerCCS(:,stage)))*0.35 + 0.865*0.05*sum(sum(PCOALCCS(:,stage))) + ...
        0.865*sum(sum(PCOAL(:,stage))) + 0.312*sum(sum(PNG(:,stage))) + 0.312*0.05*sum(sum (PNGCCS(:,stage))))* carcost;

    obj(stage) = (FIXOM(stage) + inv(stage) + rela(stage) + VAROM(stage) + lcoe(stage))/10000/10000 + carboncost(stage)/10000/10000;
end
Con = [MpConstraints, Constraints];
Objective = sum(obj);

% ops = sdpsettings('verbose', 0, 'solver', 'mosek');
% results = optimize(Con,Objective, ops);

options = sdpsettings('solver','gurobi','verbose',0);
[model,recoverymodel,diagnostic,internalmodel] = export(Constraints,Objective);

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