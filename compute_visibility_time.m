function visibility_time = compute_visibility_time(tle_data, UE_locations, start_time, end_time, step)
    % 輸入：
    % - tle_data: 包含 TLE 兩行字串的 cell array
    % - UE_locations: N x 3 陣列（每列為 [lat, lon, alt]）
    % - start_time, end_time: POSIX 秒數（double），若 start_time == 0 表示從現在開始
    % - step: 時間步長（秒）
    %
    % 輸出：
    % - ue_endtime: N x 1 datetime array，為各 UE 最後可見時間（或 NaT）

    N = size(UE_locations, 1); % UE 數量

    % === 1. 將 TLE 寫入臨時檔案（satelliteScenario 需要檔案形式） ===
    temp_file = 'tle_data_temp.txt';
    fileID = fopen(temp_file, 'w');
    if fileID == -1
        error('無法創建臨時 TLE 檔案。');
    end
    fprintf(fileID, '%s\n', tle_data{1});
    fprintf(fileID, '%s', tle_data{2});
    fclose(fileID);

    % === 2. 定義模擬時間範圍 ===
    if start_time == 0
        % 從現在時間開始（加上分鐘偏移）
        startTime = datetime('now', 'TimeZone', 'Asia/Taipei') + minutes(start_time);
        endTime   = datetime('now', 'TimeZone', 'Asia/Taipei') + minutes(end_time);
    else
        % 從 POSIX 秒數轉 datetime
        startTime = datetime(start_time, 'ConvertFrom', 'posixtime', 'TimeZone', 'Asia/Taipei');
        endTime   = datetime(end_time,   'ConvertFrom', 'posixtime', 'TimeZone', 'Asia/Taipei');
    end

    % === 3. 建立 satelliteScenario（一次建立，不重複） ===
    sc = satelliteScenario(startTime, endTime, step);

    % 加入衛星
    sat = satellite(sc, temp_file, 'Name', 'MyLEOSatellite');

    % 刪除臨時檔案（節省空間）
    delete(temp_file);
    disp("開始建立地面站")
    % === 4. 一次性建立所有 ground station（避免迴圈中重複建立） ===
    % 注意：altitude 目前沒用到，如果有需要可以傳進去
    lat = UE_locations(:,1);
    lon = UE_locations(:,2);
    gs_array = groundStation(sc, lat, lon);
    % === 5. 一次性建立所有 access（避免多次呼叫 satelliteScenario 計算） ===
    ac_array = access(sat, gs_array); 
    % === 6. 初始化輸出變數 ===
    ue_starttime = nan(N, 1); 
    ue_endtime = nan(N, 1);  % POSIX time 初始化為 NaN
    disp("建置地面站完成")
    % === 7. 批量取得每個 UE 的最後可見時間 ===
    if start_time == 0
        ue_starttime = NaT(N, 1, 'TimeZone', 'Asia/Taipei');
        ue_endtime = NaT(N, 1, 'TimeZone', 'Asia/Taipei');
        intvls = accessIntervals(ac_array(1)); % 取得該 UE 與衛星的所有可見時間區間
        disp(intvls)
        ue_endtime(1) = intvls{1,5};
        ue_starttime(1) = intvls{1,4}; 
    else
        % === 7. 批量取得每個 UE 的最後可見時間（修正後） ===
    % 使用 parfor 迴圈來平行處理每個 UE 的 accessIntervals 呼叫
        parfor i = 1:N
            % 取得該 UE 與衛星的所有可見時間區間
            % intvls 會是一個 timetable 物件
            intvls = accessIntervals(ac_array(i));
            
            if ~isempty(intvls)
                % 如果有可見時間，取出最後一次的 EndTime
                % 正確的索引方式是 intvls.EndTime(end)
                ue_endtime(i) = posixtime(intvls.EndTime(end));
                ue_starttime(i) = posixtime(intvls.StartTime(end));
            end
        end
    end
    disp("可視時間計算完成");
    visibility_time = [ue_starttime, ue_endtime];
    clear sc sat gs_array ac_array
end

