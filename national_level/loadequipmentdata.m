%%
BSlife = equipment0.BS.life;
if BSlife > (stage-1)*5
    stagetemp = (stage-1)*5;
else
    stagetemp = (stage-1)*5-BSlife;
end
BSfixom = equipment0.BS.fixom*(1+(stagetemp/BSlife).^equipment0.BS.miu);
BSdeg = (1-equipment0.BS.deg)^(stagetemp/5);
%%
NGinv = calculateDepreciationCost(equipment0.NG.inv, discountrate, equipment0.NG.life, 1);
NGlife = equipment0.COAL.life;
if NGlife > (stage-1)*5
    stagetemp = (stage-1)*5;
else
    stagetemp = (stage-1)*5-NGlife;
end
NGfixom = equipment0.NG.fixom*(1+(stagetemp/NGlife).^equipment0.NG.miu);
NGvarom = equipment0.NG.varom*(1+(stagetemp/NGlife).^equipment0.NG.miu);
NGdeg = (1-equipment0.NG.deg)^(stagetemp/5);
%%
NGCCSinv = calculateDepreciationCost(equipment0.NGCCS.inv, discountrate, equipment0.NGCCS.life, 1);
NGCCSlife = equipment0.NGCCS.life;
if NGCCSlife > (stage-1)*5
    stagetemp = (stage-1)*5;
else
    stagetemp = (stage-1)*5-NGCCSlife;
end
NGCCSfixom = equipment0.NGCCS.fixom*(1+(stagetemp/NGCCSlife).^equipment0.NGCCS.miu);
NGCCSvarom = equipment0.NGCCS.varom*(1+(stagetemp/NGCCSlife).^equipment0.NGCCS.miu);
NGCCSdeg = (1-equipment0.NGCCS.deg)^(stagetemp/5);
%%
COALinv = calculateDepreciationCost(equipment0.COAL.inv, discountrate, equipment0.COAL.life, 1);
COALlife = equipment0.COAL.life;
if COALlife > (stage-1)*5
    stagetemp = (stage-1)*5;
else
    stagetemp = (stage-1)*5-COALlife;
end
COALfixom = equipment0.COAL.fixom*(1+(stagetemp/COALlife).^equipment0.COAL.miu);
COALvarom = equipment0.COAL.varom*(1+(stagetemp/COALlife).^equipment0.COAL.miu);
COALdeg = (1-equipment0.COAL.deg)^(stagetemp/5);
%%
COALCCSinv = calculateDepreciationCost(equipment0.COALCCS.inv, discountrate, equipment0.COALCCS.life, 1);
COALCCSlife = equipment0.COALCCS.life;
if COALCCSlife > (stage-1)*5
    stagetemp = (stage-1)*5;
else
    stagetemp = (stage-1)*5-COALCCSlife;
end
COALCCSfixom = equipment0.COALCCS.fixom*(1+(stagetemp/COALCCSlife).^equipment0.COALCCS.miu);
COALCCSvarom = equipment0.COALCCS.varom*(1+(stagetemp/COALCCSlife).^equipment0.COALCCS.miu);
COALCCSdeg = (1-equipment0.COALCCS.deg)^(stagetemp/5);
%%
Biopowerinv = calculateDepreciationCost(equipment0.Biopower.inv, discountrate, equipment0.Biopower.life, 1);
Biopowerlife = equipment0.Biopower.life;
if Biopowerlife > (stage-1)*5
    stagetemp = (stage-1)*5;
else
    stagetemp = (stage-1)*5-Biopowerlife;
end
Biopowerfixom = equipment0.Biopower.fixom*(1+(stagetemp/Biopowerlife).^equipment0.Biopower.miu);
Biopowervarom = equipment0.Biopower.varom*(1+(stagetemp/Biopowerlife).^equipment0.Biopower.miu);
Biopowerlcoe = equipment0.Biopower.lcoe;
Biopowerdeg = (1-equipment0.Biopower.deg)^(stagetemp/5);
%%
BiopowerCCSinv = calculateDepreciationCost(equipment0.BiopowerCCS.inv, discountrate, equipment0.BiopowerCCS.life, 1);
BiopowerCCSlife = equipment0.BiopowerCCS.life;
if BiopowerCCSlife > (stage-1)*5
    stagetemp = (stage-1)*5;
else
    stagetemp = (stage-1)*5-BiopowerCCSlife;
end
BiopowerCCSfixom = equipment0.BiopowerCCS.fixom*(1+(stagetemp/BiopowerCCSlife).^equipment0.BiopowerCCS.miu);
BiopowerCCSvarom = equipment0.BiopowerCCS.varom*(1+(stagetemp/BiopowerCCSlife).^equipment0.BiopowerCCS.miu);
BiopowerCCSdeg = (1-equipment0.BiopowerCCS.deg)^(stagetemp/5);
%%
Geothermalinv = calculateDepreciationCost(equipment0.Geothermal.inv, discountrate, equipment0.Geothermal.life, 1);
Geothermallife = equipment0.Geothermal.life;
if Geothermallife > (stage-1)*5
    stagetemp = (stage-1)*5;
else
    stagetemp = (stage-1)*5-Geothermallife;
end
Geothermalfixom = equipment0.Geothermal.fixom*(1+(stagetemp/Geothermallife).^equipment0.Geothermal.miu);
Geothermallcoe = equipment0.Geothermal.lcoe;
Geothermaldeg = (1-equipment0.Geothermal.deg)^(stagetemp/5);
%%
Hydropowerinv = calculateDepreciationCost(equipment0.Hydropower.inv, discountrate, equipment0.Hydropower.life, 1);
Hydropowerlife = equipment0.Hydropower.life;
if Hydropowerlife > (stage-1)*5
    stagetemp = (stage-1)*5;
else
    stagetemp = (stage-1)*5-Hydropowerlife;
end
Hydropowerfixom = equipment0.Hydropower.fixom*(1+(stagetemp/Hydropowerlife).^equipment0.Hydropower.miu);
Hydropowerlcoe = equipment0.Hydropower.lcoe;
Hydropowerdeg = (1-equipment0.Hydropower.deg)^(stagetemp/5);
%%
Nuclearinv = calculateDepreciationCost(equipment0.Nuclear.inv, discountrate, equipment0.Nuclear.life, 1);
Nuclearlife = equipment0.Nuclear.life;
if Nuclearlife > (stage-1)*5
    stagetemp = (stage-1)*5;
else
    stagetemp = (stage-1)*5-Nuclearlife;
end
Nuclearfixom = equipment0.Nuclear.fixom*(1+(stagetemp/Nuclearlife).^equipment0.Nuclear.miu);
Nuclearvarom = equipment0.Nuclear.varom*(1+(stagetemp/Nuclearlife).^equipment0.Nuclear.miu);
Nuclearlcoe = equipment0.Nuclear.lcoe;
Nucleardeg = (1-equipment0.Nuclear.deg)^(stagetemp/5);
%%
OFFWTinv = calculateDepreciationCost(equipment0.OFFWT.inv, discountrate, equipment0.OFFWT.life, 1);
OFFWTlife = equipment0.OFFWT.life;
if OFFWTlife > (stage-1)*5
    stagetemp = (stage-1)*5;
else
    stagetemp = (stage-1)*5-OFFWTlife;
end
OFFWTfixom = equipment0.OFFWT.fixom*(1+(stagetemp/OFFWTlife).^equipment0.OFFWT.miu);
OFFWTlcoe = equipment0.OFFWT.lcoe;
OFFWTdeg = (1-equipment0.OFFWT.deg)^(stagetemp/5);
%%
CSPlcoe= equipment0.CSP.lcoe;
CSPlife = equipment0.CSP.life;
CSPdeg = (1-equipment0.CSP.deg)^(stagetemp/5);
%%
ONWTlcoe = equipment0.ONWT.lcoe;
ONWTlife = equipment0.ONWT.life;
ONWTdeg = (1-equipment0.ONWT.deg)^(stagetemp/5);
%%
UPVlife = equipment0.UPV.life;
UPVdeg = (1-equipment0.UPV.deg)^(stagetemp/5);
%%
DPVlife = equipment0.DPV.life;
DPVdeg = (1-equipment0.DPV.deg)^(stagetemp/5);