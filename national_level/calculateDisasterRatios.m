function [ratio, Ploadcold, Ploadheat] = calculateDisasterRatios(mpcdisasters0, time_item, Pload, mpc0)

    slopecold = mpcdisasters0.regcount{strcmp(mpcdisasters0.regcount{:, 1}, 'coldwave'), 4};
    intercept_cold = mpcdisasters0.regcount{strcmp(mpcdisasters0.regcount{:, 1}, 'coldwave'), 5};
    if intercept_cold < 0
        ratiocold = 1;
    else
        ratiocold = (intercept_cold + (time_item - 2017) * slopecold) / (intercept_cold + (2020-2017) * slopecold);
    end

    slopeheat = mpcdisasters0.regcount{strcmp(mpcdisasters0.regcount{:, 1}, 'heatwave'), 4};
    intercept_heat = mpcdisasters0.regcount{strcmp(mpcdisasters0.regcount{:, 1}, 'heatwave'), 5};
    ratioheat = (intercept_heat + (time_item - 2017) * slopeheat) / intercept_heat;

    slopeflood = mpcdisasters0.regcount{strcmp(mpcdisasters0.regcount{:, 1}, 'flood'), 4};
    intercept_flood = mpcdisasters0.regcount{strcmp(mpcdisasters0.regcount{:, 1}, 'flood'), 5};
    ratioflood = (intercept_flood + (time_item - 2017) * slopeflood) / (intercept_flood + (2020-2017) * slopeflood);

    slopewind = mpcdisasters0.regcount{strcmp(mpcdisasters0.regcount{:, 1}, 'extreme wind'), 4};
    intercept_wind = mpcdisasters0.regcount{strcmp(mpcdisasters0.regcount{:, 1}, 'extreme wind'), 5};
    ratiowind = (intercept_wind + (time_item - 2017) * slopewind) / (intercept_wind + (2020-2017) * slopewind);

    slopewildfire = mpcdisasters0.regcount{strcmp(mpcdisasters0.regcount{:, 1}, 'wildfire'), 4};
    intercept_wildfire = mpcdisasters0.regcount{strcmp(mpcdisasters0.regcount{:, 1}, 'wildfire'), 5};
    ratiowildfire = (intercept_wildfire + (time_item - 2017) * slopewildfire) / (intercept_wildfire + (2020-2017) * slopewildfire);

    slopetyphone = mpcdisasters0.regcount{strcmp(mpcdisasters0.regcount{:, 1}, 'tropical cyclone'), 4};
    intercept_typhone = mpcdisasters0.regcount{strcmp(mpcdisasters0.regcount{:, 1}, 'tropical cyclone'), 5};
    ratiotyphone = (intercept_typhone + (time_item - 2017) * slopetyphone) / (intercept_typhone + (2020-2017) * slopetyphone);


    ratio = [1, 1, ratiowind, ratioflood, 1, ratiowildfire, ratiotyphone];

    [summer_hours, winter_hours] = generate_seasonal_hours();
    Ploadcold = Pload;
    Ploadheat = Pload;
    Ploadcold(:, find(winter_hours ~= 0)) = (1 + 2 * mpc0.bus(:, 10)) * ratiocold .* Ploadcold(:, find(winter_hours ~= 0));
    Ploadheat(:, find(summer_hours ~= 0)) = (1 + 2 * mpc0.bus(:, 10)) * ratioheat .* Ploadheat(:, find(summer_hours ~= 0));
end
