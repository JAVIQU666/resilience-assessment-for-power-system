function totalRela = sumRelaForMPC(countyresultnormal, mpcIndex)

    totalRela = zeros(1,6);
    

    for i = 1:size(countyresultnormal, 1)
 
        if countyresultnormal{i, 2} == mpcIndex
            
            structData = countyresultnormal{i, 3};
            
           
            totalRela = totalRela + sum(structData.temprela,2)';
        end
    end
end
