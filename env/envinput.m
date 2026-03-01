clc; clear;
folder_path = 'G:\xunleidown\exwindmax\';  % sfcWindmax
files = dir(fullfile(folder_path, '*.nc'));
scenarios = {'ssp126', 'ssp245', 'ssp370', 'ssp585'};
all_resultswind = table();
china_lat_min = 18; china_lat_max = 54;
china_lon_min = 73; china_lon_max = 136;
for s = 1:length(scenarios)
    scenario = scenarios{s};

    filelist = {};
    for i = 1:length(files)
        fname = files(i).name;
        if contains(fname, scenario)
            filelist{end+1} = fullfile(folder_path, fname);
        end
    end
    for i = 1:length(filelist)
        filename = filelist{i};
        lat = ncread(filename, 'lat');    % [lat]
        lon = ncread(filename, 'lon');   % [lon]
        lat_idx = find(lat >= china_lat_min & lat <= china_lat_max);
        lon_idx = find(lon >= china_lon_min & lon <= china_lon_max);
        wind = double(ncread(filename, 'sfcWindmax'));  % [lat x lon x time] or [lon x lat x time]
        if size(wind,1) == length(lon) && size(wind,2) == length(lat)
            wind = permute(wind, [2 1 3]);  % [lat x lon x time]
        end
        wind_china = wind(lat_idx, lon_idx, :);  % [lat x lon x time]
        [lat_n, lon_n, time_n] = size(wind_china);
        % [grid × time]
        wind_reshape = reshape(wind_china, lat_n * lon_n, time_n);
        grid_mean = mean(wind_reshape, 2);     % [Ngrid x 1]
        china_mean = mean(grid_mean);          % scalar
        % 提取年份
        year_str = regexp(filename, '\d{4}', 'match');
        if isempty(year_str)
            warning(['un year：', filename]);
            continue;
        end
        year = str2double(year_str{1});

        row = table(string(scenario), year, china_mean, ...
            'VariableNames', {'Scenario', 'Year', 'ChinaMeanWind'});
        all_resultswind = [all_resultswind; row];
    end
end

all_resultswind = sortrows(all_resultswind, {'Scenario','Year'});
windinc = all_resultswind{:,3};
wind_sorted = zeros(size(windinc)); 
for i = 1:4 
    idx_start = (i-1)*6 + 1;
    idx_end = i*6;
    group = windinc(idx_start:idx_end);
    group_sorted = sort(group, 'ascend');
    group_norm = group_sorted / group_sorted(1);
    wind_sorted(idx_start:idx_end) = group_norm;
end
save('wind_sorted.mat', 'wind_sorted');
%% Tropical cyclone
% When determining the scenario, 
% the national disaster classification level shall be used as the standard. 
% During the resilience assessment, 
% typhoon and strong wind hazards shall be evaluated at one higher safety level.
clc
clear all
load('wind_sorted.mat');
% wind_sorted = ones(24,1);
filename = 'G:\xunleidown\windmax10.nc';  % i10fg
%filename = 'G:\xunleidown\tempmaxmin.nc';  % mx2t  mn2t

lat = ncread(filename, 'latitude');
lon = ncread(filename, 'longitude');
time = ncread(filename, 'valid_time'); 
time = 1:8760;
wind = ncread(filename, 'i10fg');  % [lon × lat × time] 或 [lat × lon × time]

wind = double(wind);

if size(wind,1) == length(lon) && size(wind,2) == length(lat)
    wind = permute(wind, [2 1 3]);  % [lat × lon × time]
end

[lat_n, lon_n, t_n] = size(wind);
tfcount_low  = zeros(6, lat_n, lon_n);  
tfcount_mid  = zeros(6, lat_n, lon_n);  
tfcount_high = zeros(6, lat_n, lon_n);  
base_scenarios = {'ssp126', 'ssp245', 'ssp370', 'ssp585'};
repeat_each = 6;
scenarios_all = repelem(base_scenarios, repeat_each);

for i=1:size(wind_sorted,1)
    scenario = scenarios_all{i};
    for t = 1:t_n
        frame = wind_sorted(i)*wind(:,:,t); 

        masktemp = ((frame >= 22.2) & (frame <= 32.6));
        tfcount_low(mod(i - 1, 6) + 1,:,:)  = tfcount_low(mod(i - 1, 6) + 1,:,:)  + reshape(masktemp, [1, size(masktemp,1), size(masktemp,2)]);

        masktemp = ((frame >= 32.7) & (frame <= 41.4));
        tfcount_mid(mod(i - 1, 6) + 1,:,:)  = tfcount_mid(mod(i - 1, 6) + 1,:,:)  + reshape(masktemp, [1, size(masktemp,1), size(masktemp,2)]);

        masktemp = (frame > 41.5);
        tfcount_high(mod(i - 1, 6) + 1,:,:) = tfcount_high(mod(i - 1, 6) + 1,:,:) + reshape(masktemp, [1, size(masktemp,1), size(masktemp,2)]);
    end
    extf.(scenario).low = tfcount_low;
    extf.(scenario).mid = tfcount_mid;
    extf.(scenario).high = tfcount_high;
end
save('extf.mat', 'extf');

%% exwind
clc
clear all
load('wind_sorted.mat');
% wind_sorted = ones(24,1);
filename = 'G:\xunleidown\windmax10.nc';  % i10fg
%filename = 'G:\xunleidown\tempmaxmin.nc';  % mx2t  mn2t

lat = ncread(filename, 'latitude');
lon = ncread(filename, 'longitude');
time = ncread(filename, 'valid_time');  
time = 1:8760;
wind = ncread(filename, 'i10fg');   [lon × lat × time] 或 [lat × lon × time]

wind = double(wind);
if size(wind,1) == length(lon) && size(wind,2) == length(lat)
    wind = permute(wind, [2 1 3]);  % 转为 [lat × lon × time]
end

base_scenarios = {'ssp126', 'ssp245', 'ssp370', 'ssp585'};
repeat_each = 6;
scenarios_all = repelem(base_scenarios, repeat_each);
[lat_n, lon_n, t_n] = size(wind);
ewcount_low  = zeros(6, lat_n, lon_n);  
ewcount_mid  = zeros(6, lat_n, lon_n); 
ewcount_high = zeros(6, lat_n, lon_n); 
for i = 1:size(wind_sorted, 1)
    scenario = scenarios_all{i};
    idx = mod(i - 1, 6) + 1;  

    factor = wind_sorted(i); 

    for x = 1:lat_n
        for y = 1:lon_n
            
            wind_series = squeeze(wind(x, y, :)) * factor;
            mask_low  = (wind_series >= 20)   & (wind_series <= 22.5);
            mask_mid  = (wind_series > 22.5)  & (wind_series <= 25.5);
            mask_high = (wind_series > 25.5)  & (wind_series <= 27.5);

            cc = bwlabel(mask_low);
            for r = 1:max(cc)
                len = sum(cc == r);
                if len >= 48
                    ewcount_low(idx, x, y) = ewcount_low(idx, x, y) + len;
                end
            end
            cc = bwlabel(mask_mid);
            for r = 1:max(cc)
                len = sum(cc == r);
                if len >= 36
                    ewcount_mid(idx, x, y) = ewcount_mid(idx, x, y) + len;
                end
            end
            cc = bwlabel(mask_high);
            for r = 1:max(cc)
                len = sum(cc == r);
                if len >= 24
                    ewcount_high(idx, x, y) = ewcount_high(idx, x, y) + len;
                end
            end
        end
    end

    exwind.(scenario).low  = ewcount_low;
    exwind.(scenario).mid  = ewcount_mid;
    exwind.(scenario).high = ewcount_high;
end
save('exwind.mat', 'exwind');

%%  temp
clc 
clear all
filename='G:\xunleidown\data.grib'   %grib
x=ncdataset(filename);
x.variables 
x.data('lat'); % 145 18-54 0.25
x.data('lon'); % 253 73-136 0.25
temp = double(x.data('N2_metre_temperature'));  % [lon x lat x time]
time = x.data('time');
temp_C = temp - 273.15;  
sz = size(temp_C);  % [day x lon x lat]
temp_C = squeeze(temp_C);
temp_C = temp_C(1:365*86, :, :);
p90_map = zeros(365,145, 253);
p95_map = zeros(365,145, 253);

for d = 1:365
    %  [86 × 145 × 253]
    temp_slice = temp_C(d:365:d+365*85, :, :);

    %  [1 × (145×253)]
    p90_flat = prctile(temp_slice, 90,1);
    p95_flat = prctile(temp_slice, 95,1);
    p99_flat = prctile(temp_slice, 99,1);

    p10_flat = prctile(temp_slice, 10,1);
    p5_flat = prctile(temp_slice, 5,1);
    p1_flat = prctile(temp_slice, 1,1);

    % reshape [145 × 253]
    p90_result(d, :, :) = p90_flat;
    p95_result(d, :, :) = p95_flat;
    p99_result(d, :, :) = p99_flat;
    p10_result(d, :, :) = p10_flat;
    p5_result(d, :, :) = p5_flat;
    p1_result(d, :, :) = p1_flat;
end
save('p90_result.mat', 'p90_result');
save('p95_result.mat', 'p95_result');
save('p99_result.mat', 'p99_result');
save('p10_result.mat', 'p10_result');
save('p5_result.mat',  'p5_result');
save('p1_result.mat',  'p1_result');
%% temp
clc 
clear all
folder_path = 'G:\xunleidown\tempday\';
files = dir(fullfile(folder_path, '*.nc'));

scenarios = {'ssp126', 'ssp245', 'ssp370', 'ssp585'};

china_lat_min = 18; china_lat_max = 54;
china_lon_min = 73; china_lon_max = 136;

load('p90_result.mat'); 
load('p95_result.mat');
load('p99_result.mat');
load('p10_result.mat');
load('p5_result.mat');
load('p1_result.mat');

for s = 1:length(scenarios)
    scenario = scenarios{s};
    files_scenario = dir(fullfile(folder_path, ['*' scenario '*.nc']));

    for i = 1:length(files_scenario)
        filename = fullfile(folder_path, files_scenario(i).name);
        disp(['  files：', filename]);

        temp_raw = double(ncread(filename, 'tasmax'));
        temp_raw = permute(temp_raw, [3, 2, 1]);
        temp_C = temp_raw - 273.15;

        lat = double(ncread(filename, 'lat'));    % [lat]
        lon = double(ncread(filename, 'lon'));   % [lon]

        lat_idx = find(lat >= china_lat_min & lat <= china_lat_max);
        lon_idx = find(lon >= china_lon_min & lon <= china_lon_max);

        lat_lr = linspace(18, 54, size(lat_idx,1));      % 与 temp_china 
        lon_lr = linspace(73, 135, size(lon_idx,1));     % 与 temp_china 

        lat_hr = linspace(18, 54, 145);     % 与 p90_result 
        lon_hr = linspace(73, 135, 253);    % 与 p90_result 

        [lon_lr_grid, lat_lr_grid] = meshgrid(lon_lr, lat_lr);
        [lon_hr_grid, lat_hr_grid] = meshgrid(lon_hr, lat_hr);

        %  p90_result → [365 × lat × lon]
        temp_china = temp_C(:, lat_idx, lon_idx);
        temp_interp = zeros(365, 145, 253);  

        for d = 1:365
            temp_day = squeeze(temp_china(d, :, :));  % [32 × 56]

            % [145 × 253]
            temp_interp(d, :, :) = interp2(lon_lr_grid, lat_lr_grid, temp_day, ...
                lon_hr_grid, lat_hr_grid, 'linear', NaN);
        end
        temp_interp = temp_interp(:, end:-1:1, :);
 
        exceed_mask = temp_interp > p90_result;
        range_mask = temp_interp >= 35 & temp_interp <= 37;
        final_mask = exceed_mask & range_mask;
        exceed_dayslow = squeeze(sum(final_mask, 1));

        exceed_mask = temp_interp > p95_result;
        range_mask = temp_interp > 37 & temp_interp <= 40;
        final_mask = exceed_mask & range_mask;
        exceed_daysmid = squeeze(sum(final_mask, 1));

        exceed_mask = temp_interp > p99_result;
        range_mask = temp_interp > 40;
        final_mask = exceed_mask & range_mask;
        exceed_dayshigh = squeeze(sum(final_mask, 1));

        exceed_mask = temp_interp > p10_result;
        range_mask = temp_interp >= -20 & temp_interp <= -15;
        final_mask = exceed_mask & range_mask;
        under_dayslow = squeeze(sum(final_mask, 1));

        exceed_mask = temp_interp > p5_result;
        range_mask = temp_interp > -25 & temp_interp <= -20;
        final_mask = exceed_mask & range_mask;
        under_daysmid = squeeze(sum(final_mask, 1));

        exceed_mask = temp_interp > p1_result;
        range_mask = temp_interp < -25;
        final_mask = exceed_mask & range_mask;
        under_dayshigh = squeeze(sum(final_mask, 1));

        extemp.(scenario).exceed_dayslow_all(i, :, :) = exceed_dayslow;
        extemp.(scenario).exceed_daysmid_all(i, :, :) = exceed_daysmid;
        extemp.(scenario).exceed_dayshigh_all(i, :, :) = exceed_dayshigh;
        extemp.(scenario).under_dayslow_all(i, :, :) = under_dayslow;
        extemp.(scenario).under_daysmid_all(i, :, :) = under_daysmid;
        extemp.(scenario).under_dayshigh_all(i, :, :) = under_dayshigh;
    end
end
save('extemp.mat', 'extemp');
%% flood
clc; clear;
folder_path = 'G:\xunleidown\prday\';  % sfcWindmax
files = dir(fullfile(folder_path, '*.nc'));

scenarios = {'ssp126', 'ssp245', 'ssp370', 'ssp585'};

all_resultswind = table();

china_lat_min = 18; china_lat_max = 54;
china_lon_min = 73; china_lon_max = 136;

for s = 1:length(scenarios)
    scenario = scenarios{s};

    filelist = {};
    for i = 1:length(files)
        fname = files(i).name;
        if contains(fname, scenario)
            filelist{end+1} = fullfile(folder_path, fname);
        end
    end
    for i = 1:length(filelist)
        filename = filelist{i};
        disp(['  文件：', filename]);
        lat = ncread(filename, 'lat');    % [lat]
        lon = ncread(filename, 'lon');   % [lon]

        lat_idx = find(lat >= china_lat_min & lat <= china_lat_max);
        lon_idx = find(lon >= china_lon_min & lon <= china_lon_max);
        wind = double(ncread(filename, 'pr'));  % [lat x lon x time] or [lon x lat x time]
        if size(wind,1) == length(lon) && size(wind,2) == length(lat)
            wind = permute(wind, [2 1 3]);  %  [lat x lon x time]
        end
        wind_china = wind(lat_idx, lon_idx, :);  % [lat x lon x time]
        [lat_n, lon_n, time_n] = size(wind_china);
        wind_reshape = reshape(wind_china, lat_n * lon_n, time_n);
        grid_mean = mean(wind_reshape, 2);     % [Ngrid x 1]
        china_mean = mean(grid_mean);          % scalar
        year_str = regexp(filename, '\d{4}', 'match');
        if isempty(year_str)
            warning(['no year：', filename]);
            continue;
        end
        year = str2double(year_str{1});
        row = table(string(scenario), year, china_mean, ...
            'VariableNames', {'Scenario', 'Year', 'ChinaMeanWind'});
        all_resultswind = [all_resultswind; row];
    end
end
all_resultswind = sortrows(all_resultswind, {'Scenario','Year'});
windinc = all_resultswind{:,3};
pr_sorted = zeros(size(windinc)); 
for i = 1:4 
    idx_start = (i-1)*6 + 1;
    idx_end = i*6;

    group = windinc(idx_start:idx_end);
    group_sorted = sort(group, 'ascend');

    group_norm = group_sorted / group_sorted(1);

    pr_sorted(idx_start:idx_end) = group_norm;
end
save('pr_sorted.mat', 'pr_sorted');



























