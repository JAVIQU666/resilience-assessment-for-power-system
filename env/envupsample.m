clc 
clear all

load('extf.mat');
load('exwind.mat');
load('extemp.mat');
load('pr_sorted.mat');
load('ID_County_CN.mat'); % county_CN
scenarios = {'ssp126', 'ssp245', 'ssp370', 'ssp585'};
highres_size = size(county_CN);     % [4800, 1950]
interp_method = 'bilinear';        

temp_vars = {
    'under_dayslow_all', 'under_daysmid_all', 'under_dayshigh_all', ...
    'exceed_dayslow_all', 'exceed_daysmid_all', 'exceed_dayshigh_all'
};
% （extf）
precip_levels = {'low', 'mid', 'high'};
% （exwind）
wind_levels = {'low', 'mid', 'high'};
% ----------------------------
for s = 1:length(scenarios)
    ssp = scenarios{s}; 

    % -------- extemp --------
    for vi = 1:length(temp_vars)
        varname = temp_vars{vi};
        data_in = extemp.(ssp).(varname);     % [6 × 145 × 253]
        data_out = zeros(6, highres_size(1), highres_size(2));

        for k = 1:6
            layer = squeeze(data_in(k, :, :));
            data_out(k, :, :) = imresize(layer, highres_size, interp_method);
        end

        extemp_upsampled.(ssp).(varname) = data_out;
    end

    % --------extf --------
    for vi = 1:length(precip_levels)
        level = precip_levels{vi};
        data_in = extf.(ssp).(level);         % [6 × 145 × 253]
        data_out = zeros(6, highres_size(1), highres_size(2));

        for k = 1:6
            layer = squeeze(data_in(k, :, :));
            data_out(k, :, :) = imresize(layer, highres_size, interp_method);
        end

        extf_upsampled.(ssp).(level) = data_out;
    end

    % -------- exwind --------
    for vi = 1:length(wind_levels)
        level = wind_levels{vi};
        data_in = exwind.(ssp).(level);       %  [6 × 145 × 253]
        data_out = zeros(6, highres_size(1), highres_size(2));

        for k = 1:6
            layer = squeeze(data_in(k, :, :));
            data_out(k, :, :) = imresize(layer, highres_size, interp_method);
        end

        exwind_upsampled.(ssp).(level) = data_out;
    end

end
save('extemp_upsampled.mat', 'extemp_upsampled', '-v7.3');
save('extf_upsampled.mat', 'extf_upsampled', '-v7.3');
save('exwind_upsampled.mat', 'exwind_upsampled', '-v7.3');