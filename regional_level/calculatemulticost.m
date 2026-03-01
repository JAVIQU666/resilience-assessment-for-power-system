function [result] = calculatemulticost(scenario, leng, weightsload, days_in_month)

    resultgencost = zeros(1, leng);
    resultrela = zeros(1, leng);
    resultDRcost = zeros(1, leng);
    resultrigidcost = zeros(1, leng);
    resultdistributecostbs = zeros(1, leng);
    resultdistributecostpv = zeros(1, leng);
    resultbscost = zeros(1, leng);

        for m = 1:size(scenario, 2)
            monthtemp = 12/size(scenario, 2);
            currentStructs = scenario{m};
            tempresultgencost = 0;
            tempresultrela = 0;
            tempresultDRcost = 0;
            tempresultrigidcost = 0;
            tempresultdistributecostbs = 0;
            tempresultdistributecostpv = 0;
            tempresultbscost = 0;
            for k = 1:length(currentStructs)
                tempresult = currentStructs{k};
                tempresultgencost = tempresultgencost + monthtemp*days_in_month(k) * tempresult.gencost;
                tempresultrela = tempresultrela + monthtemp*days_in_month(k) * tempresult.rela;
                tempresultDRcost = tempresultDRcost + monthtemp*days_in_month(k) * tempresult.DRcost;
                tempresultrigidcost = tempresultrigidcost + monthtemp*days_in_month(k) * tempresult.rigidcost;
                tempresultdistributecostbs = tempresultdistributecostbs + monthtemp*days_in_month(k) * tempresult.distributecostbs;
                tempresultdistributecostpv = tempresultdistributecostpv + monthtemp*days_in_month(k) * tempresult.distributecostpv;
                tempresultbscost = tempresultbscost + monthtemp*days_in_month(k) * tempresult.bscost;
            end
            resultgencost(1, m) = tempresultgencost;
            resultrela(1, m) = tempresultrela;
            resultDRcost(1, m) = tempresultDRcost;
            resultrigidcost(1, m) = tempresultrigidcost;
            resultdistributecostbs(1, m) = tempresultdistributecostbs;
            resultdistributecostpv(1, m) = tempresultdistributecostpv;
            resultbscost(1, m) = tempresultbscost;
        end
   
    gencost = resultgencost * weightsload' / 100000000;
    rela = resultrela * weightsload'  / 100000000;
    DRcost = resultDRcost * weightsload' / 100000000;
    rigidcost = resultrigidcost * weightsload'  / 100000000;
    distributecostpv = resultdistributecostpv * weightsload'/ 100000000;
    distributecostbs = resultdistributecostbs * weightsload'/ 100000000;
    bscost = resultbscost * weightsload'/ 100000000;

    result = [gencost,rela,DRcost,rigidcost,distributecostbs,distributecostpv,bscost];
end
