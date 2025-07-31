function visibility_time = compute_visibility_time(tle, UE_location, start_time, end_time, step)
    % 輸入：
    % tle: TLE 數據（結構或字符串數組）
    % UE_location: [緯度, 經度, 高度]（度，度，公尺）
    % start_time, end_time: 模擬時間範圍（分鐘）
    % step: 時間步長（秒）
    % 輸出：
    % visibility_time: 衛星對 UE 的可視時間（毫秒）
    satdata = parse_tle(tle); % 解析 TLE

    visibility_time = 0;
    for t = start_time*60:step:end_time*60 % 時間轉為秒
        [pos, ~] = sgp4(t/60, satdata); % 調用 SGP4，時間為分鐘
        sat_pos = pos; % 提取 ECI 位置 (km)
        % 將 ECI 轉為 ECEF（考慮地球自轉）
        sat_pos_ecef = eci2ecef(sat_pos, t);
        elevation = compute_elevation(UE_location, sat_pos_ecef);
        if elevation > 0 % 衛星在地平線以上
            visibility_time = visibility_time + step * 1000; % 累加可視時間（毫秒）
        end
    end
end
