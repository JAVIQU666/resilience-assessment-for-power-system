function [summer_hours, winter_hours] = generate_seasonal_hours()

    num_hours = 8760;


    summer_hours = zeros(1, num_hours);
    winter_hours = zeros(1, num_hours);


    hours_in_month = [31 28 31 30 31 30 31 31 30 31 30 31] * 24;


    month_start_idx = [1, cumsum(hours_in_month(1:end-1)) + 1];
    month_end_idx = cumsum(hours_in_month);


    summer_months = [6, 7, 8];
    summer_days = [];
    for i = 1:length(summer_months)
        month = summer_months(i);
        days_in_month = hours_in_month(month) / 24;
        summer_days = [summer_days, month_start_idx(month):24:month_end_idx(month)];
    end


    winter_months = [12, 1, 2];
    winter_days = [];
    for i = 1:length(winter_months)
        month = winter_months(i);
        days_in_month = hours_in_month(month) / 24;
        winter_days = [winter_days, month_start_idx(month):24:month_end_idx(month)];
    end


    random_summer_days = randsample(summer_days, 3);
    for i = 1:length(random_summer_days)
        summer_hours(random_summer_days(i):random_summer_days(i)+23) = 1;
    end


    random_winter_days = randsample(winter_days, 3);
    for i = 1:length(random_winter_days)
        winter_hours(random_winter_days(i):random_winter_days(i)+23) = 1;
    end
end
