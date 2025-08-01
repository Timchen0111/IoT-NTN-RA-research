function visibility_time = compute_visibility_time(tle, UE_location, start_time, end_time, step)
    % 輸入：
    % tle: TLE 數據（結構、單行字符串、雙行字符串數組或數組格式）
    % UE_location: [緯度, 經度, 高度]（度，度，公尺）
    % start_time, end_time: 模擬時間範圍（分鐘）
    % step: 時間步長（秒）
    % 輸出：
    % visibility_time: 衛星對 UE 的可視時間（毫秒）

    if isstruct(tle)
        satdata = tle;
    else
        satdata = parse_tle(tle); % 解析 TLE
    end

    % TLE 曆元：2025 年第 211.90723748 天
    epoch_year = 2025;
    epoch_day = 211.90723748;
    % 將曆元轉為 UTC 時間
    epoch_datetime = datetime(epoch_year, 1, 1) + days(epoch_day - 1);
    epoch_utc = [year(epoch_datetime), month(epoch_datetime), day(epoch_datetime), ...
                 hour(epoch_datetime), minute(epoch_datetime), second(epoch_datetime)];

    visibility_time = 0;
    for t = start_time*60:step:end_time*60
        [pos, vel] = sgp4(t/60, satdata);
        sat_pos = pos;
        sat_vel = vel;
        % 將 t（秒）轉為 UTC 時間
        utc_time = epoch_utc;
        utc_time(6) = utc_time(6) + t; % 更新秒數
        utc_time = fix_utc(utc_time); % 修正時間進位
        sat_pos_ecef = eci2ecef(utc_time,sat_pos,sat_vel);
        elevation = compute_elevation(UE_location, sat_pos_ecef);
        if elevation > 0
            visibility_time = visibility_time + step * 1000;
        end
    end
end



