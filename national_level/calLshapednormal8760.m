function [result] = calLshapednormal8760(totalRela, A,T0,h0,c,eq,ineq,mpc0, mpcre0, mpcrelcoe0, equipment, mpc_model_load20, Pload, WT, PV, rateload, scen,powerinter,firpower)
period = [2025 2030 2035 2040 2045 2050];
num_stage = length(period);
wtinc = mpcrelcoe0.procmipwt;
pvinc = mpcrelcoe0.procmiprsds;
reliabilitylimit = totalRela;
reliabilitylimit(find(reliabilitylimit<=0.000001))=0;
wtinc = [1 1 1 1 1 1];

time = 24;
huilv = 7;
discountrate = 0.03;
discount = 0;
for i=1:5
    discount = discount + (1+discountrate)^(-i);
end
n_Ebranch = size(mpc0.branch,1);
maxNGcap = mpc_model_load20.loadgas;
maxCOALcap = max(mpc_model_load20.loadfire - maxNGcap,0);
maxHycap = mpc_model_load20.loadwater;
n_Ebus = size(mpc0.bus,1);


iter=0;
MpCuts=[];
z = 0;
Maxiter = 2000;
numspnum = zeros(1,Maxiter);
E = zeros(Maxiter,size(T0,2));
e = zeros(Maxiter,1);
totsp = 20;
spnum = 0;
plc = 0;
optxnor = zeros(8760/time,length(c));
sp(1:totsp) = struct('f',[],'B',[],'w',[],'xb',[],'num',[],'x',[]);
flagopt = 0;

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
Cpntnum = [BScap,NGcap,NGCCScap,COALcap,COALCCScap,Biopowercap,BiopowerCCScap,Geothermalcap,Hydropowercap,Nuclearcap,OFFWTcap,...
    reshape(ONWTcap,1,[]),reshape(UPVcap,1,[]),reshape(DPVcap,1,[]),reshape(CSPcap,1,[])];
MpConstraints=[];
for stage=1:length(period)
    year = sprintf('yr%d', period(stage));
    equipment0 = equipment.(year);
    loadequipmentdata();
    vec_ONWTdeg(stage) = ONWTdeg;
    vec_UPVdeg(stage) = UPVdeg;
    vec_DPVdeg(stage) = DPVdeg;
    vec_CSPdeg(stage) = CSPdeg;
    for qqq=1:time
        indextempload1{stage, qqq} = find(h0==rateload(stage)*(8888+4*qqq));
        indextempload4{stage, qqq} = find(h0==rateload(stage)*(8888+4*qqq)/4);
        indextemponwt{stage, qqq} = find(T0==-(1+stage)*(55555+qqq));
        indextempupv{stage, qqq} = find(T0==-(1+stage)*(66666+qqq+1));
        indextempdpv{stage, qqq} = find(T0==-(1+stage)*(66666+qqq+2));
        indextempcsp{stage, qqq} = find(T0==-(1+stage)*(66666+qqq+3));
        indextempreliability{stage, qqq} = find(h0==-rateload(stage)*168000);
    end
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
    if stage == 1
        inv(stage) = (1+discountrate)^(2025-period(stage))*huilv*1000*...
            (Nuclearcap(:,stage)*Nuclearinv + (NGcap(:,stage)-maxNGcap)*NGinv + NGCCScap(:,stage)*NGCCSinv +...
            (COALcap(:,stage)-maxCOALcap)*COALinv + COALCCScap(:,stage)*COALCCSinv + Biopowercap(:,stage)*Biopowerinv +...
            Geothermalcap(:,stage)*Geothermalinv + (Hydropowercap(:,stage)-maxHycap)*Hydropowerinv +...
            BiopowerCCScap(:,stage)*BiopowerCCSinv);
    else
        inv(stage) = (1+discountrate)^(2025-period(stage))*huilv*1000*...
            ((Nuclearcap(:,stage)-Nuclearcap(:,stage-1))*Nuclearinv + (NGcap(:,stage)-NGcap(:,stage-1))*NGinv + (NGCCScap(:,stage)-NGCCScap(:,stage-1))*NGCCSinv +...
            (COALcap(:,stage)-COALcap(:,stage-1))*COALinv + (COALCCScap(:,stage)-COALCCScap(:,stage-1))*COALCCSinv + (Biopowercap(:,stage)-Biopowercap(:,stage-1))*Biopowerinv +...
            (Geothermalcap(:,stage)-Geothermalcap(:,stage-1))*Geothermalinv + (Hydropowercap(:,stage)-Hydropowercap(:,stage-1))*Hydropowerinv +...
            (BiopowerCCScap(:,stage)-BiopowerCCScap(:,stage-1))*BiopowerCCSinv);
    end
    
    FIXOM(stage) = (1+discountrate)^(2025-period(stage))*huilv*1000*...
        (Nuclearcap(:,stage)*Nuclearfixom + NGcap(:,stage)*NGfixom + NGCCScap(:,stage)*NGCCSfixom +...
        COALcap(:,stage)*COALfixom + COALCCScap(:,stage)*COALCCSfixom + Biopowercap(:,stage)*Biopowerfixom +...
        Geothermalcap(:,stage)*Geothermalfixom + Hydropowercap(:,stage)*Hydropowerfixom +...
        BScap(:,stage) * BSfixom + BiopowerCCScap(:,stage)*BiopowerCCSfixom);
end
tic
while true
    iter=iter+1;

    if iter>1
        z = sdpvar(1,1);
        for j=1:iter-1
            MpCuts = [MpCuts; E(j,:)* Cpntnum' + z >= e(j)];
        end
    end
    obj = sum(inv + FIXOM)/10000/10000 + z; 
    MpConstraints = [MpConstraints; MpCuts];
    
    ops = sdpsettings('verbose', 0, 'solver', 'mosek');
    solution = optimize(MpConstraints,obj, ops);
    
    MPBScap = value(BScap);
    MPNGcap = value(NGcap);
    MPNGCCScap = value(NGCCScap);
    MPCOALcap = value(COALcap);
    MPCOALCCScap = value(COALCCScap);
    MPBiopowercap = value(Biopowercap);
    MPBiopowerCCScap = value(BiopowerCCScap);
    MPGeothermalcap = value(Geothermalcap);
    MPHydropowercap = value(Hydropowercap);
    MPNuclearcap = value(Nuclearcap);
    MPOFFWTcap = value(OFFWTcap);
    MPONWTcap = value(ONWTcap);
    MPUPVcap = value(UPVcap);
    MPDPVcap = value(DPVcap);
    MPCSPcap = value(CSPcap);
    Mpz(iter)=value(z);
    
    MPCpntnum = [MPBScap,MPNGcap,MPNGCCScap,MPCOALcap,MPCOALCCScap,MPBiopowercap,MPBiopowerCCScap,MPGeothermalcap,MPHydropowercap,MPNuclearcap,MPOFFWTcap,...
        reshape(MPONWTcap,1,[]),reshape(MPUPVcap,1,[]),reshape(MPDPVcap,1,[]),reshape(MPCSPcap,1,[])];

    spnum = 0;
    for i = 1 : 365
        pl = sum(Pload(:,(i-1)*24+1:i*24));
        wt = WT((i-1)*24+1:i*24);
        pv = PV((i-1)*24+1:i*24);
        if iter == 1
            T = T0;
            h = h0;
            for stage=1:num_stage
                % LOAD
                for qqq = 1:time
                for qqqq=1:size(indextempload1{stage, qqq},1)
                    h(indextempload1{stage, qqq}(qqqq)) = rateload(stage)*pl(qqq)*(1+powerinter);
                end
                
                for qqqq=1:size(indextempload4{stage, qqq},1)
                    h(indextempload4{stage, qqq}(qqqq)) = 0.25*rateload(stage)*pl(qqq)*(1+powerinter);
                end
                % ONWT
                for qqqq=1:size(indextemponwt{stage, qqq},1)
                    T(indextemponwt{stage, qqq}(qqqq)) = -vec_ONWTdeg(stage)*wtinc(stage)*wt(qqq);
                end
                % UPV
                for qqqq=1:size(indextempupv{stage, qqq},1)
                    T(indextempupv{stage, qqq}(qqqq)) = -vec_UPVdeg(stage)*pvinc(stage)*pv(qqq);
                end
                % DPV
                for qqqq=1:size(indextempdpv{stage, qqq},1)
                    T(indextempdpv{stage, qqq}(qqqq)) = -vec_DPVdeg(stage)*pvinc(stage)*pv(qqq);
                end
                % CSP
                for qqqq=1:size(indextempcsp{stage, qqq},1)
                    T(indextempcsp{stage, qqq}(qqqq)) = -vec_CSPdeg(stage)*pvinc(stage)*pv(qqq);
                end
                % reliability
                for qqqq=1:size(indextempreliability{stage, qqq},1)
                    h(indextempreliability{stage, qqq}(qqqq)) = -reliabilitylimit(stage)*10000000;
                end
                end
            end
            Ttotal{i} = T;
            htotal{i} = h;
        end
        
        %% SS
        flag = 0;
        b = htotal{i} - Ttotal{i}*MPCpntnum';
        for kk=spnum:-1:max(spnum-5,1)
            ii = mod(kk-1,totsp)+1;
            if (sp(ii).B\b >= -1e-8)
                sp(ii).num = sp(ii).num + 1;
                e(iter,1) = e(iter) + sp(ii).w*htotal{i};
                E(iter,:) = E(iter,:) + sp(ii).w*Ttotal{i};
                plc(i,1) =  sp(ii).w*b;

                if flagopt == 1
                    xx = zeros(1,length(c));
                    xb = sp(ii).B\b;
                    xx(sp(ii).xb) = xb;
                    optxnor(i,:) = xx;
                end
                flag = 1;
                break;
            end
        end
        if flag == 0
            spnum = spnum + 1;
            [sp(mod(spnum-1,totsp)+1)] = sp_mosekcal(A,b,c,n_Ebranch,time,num_stage,eq,ineq);
            e(iter,1) = e(iter) + sp(mod(spnum-1,totsp)+1).w*htotal{i};
            E(iter,:) = E(iter,:) + sp(mod(spnum-1,totsp)+1).w*Ttotal{i};
            plc(i,1) =  sp(mod(spnum-1,totsp)+1).f;
            optxnor(i,:) = sp.x;
        else
            if kk~=spnum
                tmp = sp(mod(kk-1,totsp)+1);
                sp(mod(kk-1,totsp)+1) = sp(mod(spnum-1,totsp)+1);
                sp(mod(spnum-1,totsp)+1) = tmp;
            end
        end
        i
    end
    numspnum(iter) = spnum;

    w(iter) = e(iter) - E(iter,:)* MPCpntnum';
    %display([' w: ',num2str(w(iter)), ' z: ',num2str(Mpz(iter)),]);
    if w(iter) - Mpz(iter) < 0.01
        break
    else
        flagopt = 1;
    end
end
result.BScap = value(BScap);
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
result.inv = value(inv)/10000/10000;
result.FIXOM = value(FIXOM)/10000/10000;
result.x = sum(optxnor,1);
result.z = w(iter);
result.numspnum = numspnum;
result.time = toc;
end