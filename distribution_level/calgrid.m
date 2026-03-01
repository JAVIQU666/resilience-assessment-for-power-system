function [result] = calgrid(mpc0,load,pv,impact,reenergyrate,BScapmax,rigidrate,distributrate,drrate,floodindex)
time = length(load);
huilv = 7;
discountrate = 0.03;
discount = 0;
    for i=1:5
        discount = discount + (1+discountrate)^(-i);
    end
bsfixom = 48.6433;
%% flood
if floodindex > 1
    drrate = drrate*0.3;
    BScapmax = BScapmax*0.7;
    distributrate = distributrate*0.7;
end
%% bs info
PBScheff = 0.95;
PBSdiseff = 0.95;
PBSchmax = 0.2;
PBSdismax = 0.2;
SOCinitial = 0.5;
SOCmin = 0.2;
SOCmax = 0.8;
%% dr info
drupeff = 0.999;
drdowneff = 0.999;
drcost = 2.5/7; %kwh
%% distribute network
dispoint = 3; % end node

%% grid info
Branch_max = 10;
n_Ebus = size(mpc0.bus,1);
n_Ebranch = size(mpc0.branch,1);
n_Egen = size(mpc0.gen,1);
%% branch rigid
costperkm = 220/3.14/n_Ebranch; 
BRconnect = zeros(n_Ebus,n_Ebranch);
for i = 1:n_Ebranch
    BRconnect(mpc0.branch(i,1),i) = 1;
    BRconnect(mpc0.branch(i,2),i) = -1;
end
% node load
pl = ones(size(mpc0.bus,1),1)*load'/(n_Ebus);

GEconnect = zeros(n_Ebus,n_Egen);
GEconnectdis = zeros(n_Ebus,1);
for i = 1:n_Egen
    GEconnect(mpc0.gen(i,1),1)=1;
    %pl(mpc0.gen(i,1),:) = zeros(1,time);
end
GEconnectdis(dispoint) = 1;


%% define variable
Pgen = sdpvar(n_Egen,time);
Ppvdis = sdpvar(n_Ebus,time);

BScap = sdpvar(n_Egen,1);
PBSch = sdpvar(n_Egen,time);
PBSdis = sdpvar(n_Egen,time);
SOC = sdpvar(n_Egen,time);

BScapdis = sdpvar(1,1);
PBSchdis = sdpvar(1,time);
PBSdisdis = sdpvar(1,time);
SOCdis = sdpvar(1,time);

v = sdpvar(n_Ebus,time,'full');
plc = sdpvar(n_Ebus,time,'full');
qlc = sdpvar(n_Ebus,time,'full');
pij = sdpvar(n_Ebranch,time,'full');
qij = sdpvar(n_Ebranch,time,'full');

birigid = binvar(n_Ebus,1,'full');

DRup = sdpvar(n_Ebus,time);
DRdn = sdpvar(n_Ebus,time);
%% constrains
Constraints = [];
Constraints = [Constraints,0 <= Pgen <= 6];
for i = 1:n_Ebus
    Constraints = [Constraints,0 <= Ppvdis(i,:) <= distributrate*reenergyrate*pv'];
end

Constraints = [Constraints,0 <= BScap <= BScapmax];
for i=1:n_Egen
    Constraints = [Constraints,0 <= PBSch(i,:) <= PBSchmax*BScap(i)];
    Constraints = [Constraints,0 <= PBSdis(i,:) <= PBSdismax*BScap(i)];
    Constraints = [Constraints,SOCmin*BScap(i,:)<= SOC(i,:) <= SOCmax*BScap(i,:)];
end

Constraints = [Constraints,0 <= BScapdis <= distributrate*0.2];
Constraints = [Constraints,0 <= PBSchdis <= PBSchmax*BScapdis];
Constraints = [Constraints,0 <= PBSdisdis <= PBSdismax*BScapdis];
Constraints = [Constraints,SOCmin*BScapdis<= SOCdis <= SOCmax*BScapdis];

for j=1:time/24
    Constraints = [Constraints, ...
        SOC(:,(j-1)*24+2:j*24) == SOC(:,(j-1)*24+1:j*24-1) + PBScheff*PBSch(:,(j-1)*24+1:j*24-1) - PBSdis(:,(j-1)*24+1:j*24-1)/PBSdiseff, ...
        SOC(:,(j-1)*24+1) == SOCinitial*BScap, ...
        SOC(:,j*24) == SOCinitial*BScap];
    Constraints = [Constraints, ...
        SOCdis(:,(j-1)*24+2:j*24) == SOCdis(:,(j-1)*24+1:j*24-1) + PBScheff*PBSchdis(:,(j-1)*24+1:j*24-1) - PBSdisdis(:,(j-1)*24+1:j*24-1)/PBSdiseff, ...
        SOCdis(:,(j-1)*24+1) == SOCinitial*BScapdis, ...
        SOCdis(:,j*24) == SOCinitial*BScapdis];

end

Constraints = [Constraints, GEconnect*Pgen + GEconnect*(-PBSch+PBSdis) + ...
    Ppvdis + GEconnectdis*(-PBSchdis+PBSdisdis)+...
    plc - pl + DRdn - DRdn  == BRconnect*pij];
plclim = [];
for i=1:n_Ebus
    plclim = [ plclim; (1-floodindex*rigidrate*birigid(i))*pl(i,:)];
end
Constraints = [Constraints, plclim*impact - Ppvdis - ...
    GEconnectdis*PBSdisdis - GEconnect*PBSdis - DRdn <= plc <= pl];
Constraints = [Constraints, 0 <= plc <= pl];
Constraints = [Constraints, 0 <= qlc <= 0.25*pl];

Constraints = [Constraints, 0 <= DRup <= drrate*pl];
Constraints = [Constraints, 0 <= DRdn <= drrate*pl];
Constraints = [Constraints, sum(DRup,2)*drupeff ==sum(DRdn,2)/drdowneff];
for j = 1:n_Ebranch
    Constraints = [Constraints, 2*(mpc0.branch(j,3)*pij(j,:) + mpc0.branch(j,4)*qij(j,:)) == v(mpc0.branch(j,2),:) - v(mpc0.branch(j,1),:)];
end

Constraints = [Constraints, ...
    pij <= Branch_max, ...
    -pij <= Branch_max, ...
    qij <= Branch_max, ...
    -qij <= Branch_max, ...
    0.90 <= v <= 1.07, ...
    v(1,:) == 1];
%% objective CNY
rela = discount*70*1000*sum(sum(plc));
DRcost = discount*drcost*1000*sum(sum(DRup));
rigidcost =  discount*costperkm*1000*sum(birigid);
distributecostbs = discount*(bsfixom*BScapdis);
distributecostpv = discount*(50*sum(sum(Ppvdis)));
bscost = discount*bsfixom*sum(BScap);
gencost = discount*0.72*sum(sum(Pgen))*1000;
obj = rela + DRcost + rigidcost + distributecostbs + distributecostpv + bscost + gencost;
ops = sdpsettings('verbose', 0, 'solver', 'mosek');
results = optimize(Constraints, obj, ops);
result.Pgen = value(Pgen);
result.Ppvdis = value(Ppvdis);
result.BScap = value(BScap);
result.BScapdis = value(BScapdis);
result.rela = value(rela);
result.plc = value(sum(plc,1));
result.DRcost = value(DRcost);
result.rigidcost = value(rigidcost);
result.distributecostbs = value(distributecostbs);
result.distributecostpv = value(distributecostpv);
result.bscost = value(bscost);
result.gencost = value(gencost);
end