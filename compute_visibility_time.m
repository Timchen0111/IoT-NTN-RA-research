function ue_endtime = compute_visibility_time(tle_data, UE_locations, start_time, end_time, step)
    % 輸入：
    % tle_data: 包含 TLE 兩行字串的 cell array。
    % UE_location: [緯度, 經度, 高度]（度，度，公尺）
    % start_time, end_time: 模擬時間範圍（分鐘）
    % step: 時間步長（秒）
    %
    % 輸出：
    % visibility_intervals: 一個 timetable 物件，包含可見時間區間的
    %                       開始時間 (StartTime) 和結束時間 (EndTime)
    %{
    % 將 TLE 數據寫入臨時檔案
    temp_file = 'tle_data_temp.txt';
    fileID = fopen(temp_file, 'w');
    if fileID == -1
        error('無法創建臨時 TLE 檔案。');
    end
    fprintf(fileID, '%s\n', tle_data{1});
    fprintf(fileID, '%s', tle_data{2});
    fclose(fileID);

    % 定義模擬的開始和結束時間（以目前時間為基準）
    if start_time == 0
        startTime = datetime('now') + minutes(start_time);
        endTime = datetime('now') + minutes(end_time);
    else
        startTime = datetime(start_time, 'ConvertFrom', 'posixtime'); 
        endTime = datetime(end_time, 'ConvertFrom', 'posixtime');
    end
    % 創建 satelliteScenario 物件
    sc = satelliteScenario(startTime, endTime, step);

    % 使用檔案名稱來新增衛星，這是最可靠的方法
    sat = satellite(sc, temp_file, 'Name', 'MyLEOSatellite');

    % 刪除臨時檔案
    delete(temp_file);

    % 創建地面站
    gs = groundStation(sc, UE_location(1), UE_location(2));
    % 計算可見時間區間
    ac = access(sat,gs);
    intvls = accessIntervals(ac);
    save("intvls.mat")
    ue_endtime = intvls{1,5}; 
    %}
    % 輸入：
    % - tle_data: 包含 TLE 兩行字串的 cell array
    % - UE_locations: N x 3 陣列（每列為 [lat, lon, alt]）
    % - start_time, end_time: POSIX 秒數（double）
    % - step: 時間步長（秒）
    % 輸出：
    % - ue_endtime: N x 1 datetime array，為各 UE 最後可見時間（或 NaT）

    N = size(UE_locations, 1);
    %ue_endtime = NaT(N, 1);  % 初始化為 NaT

    % === 寫入 TLE 臨時檔案 ===
    temp_file = 'tle_data_temp.txt';
    fileID = fopen(temp_file, 'w');
    if fileID == -1
        error('無法創建臨時 TLE 檔案。');
    end
    fprintf(fileID, '%s\n', tle_data{1});
    fprintf(fileID, '%s', tle_data{2});
    fclose(fileID);

    % === 定義模擬時間範圍 ===
    if start_time == 0
        startTime = datetime('now', 'TimeZone', 'Asia/Taipei')+ minutes(start_time);
        endTime =datetime('now', 'TimeZone', 'Asia/Taipei')+ minutes(end_time);
    else
        startTime = datetime(start_time, 'ConvertFrom', 'posixtime' ,'TimeZone', 'Asia/Taipei'); 
        endTime = datetime(end_time, 'ConvertFrom', 'posixtime','TimeZone', 'Asia/Taipei');
    end
    %startTime = datetime(start_time, 'ConvertFrom', 'posixtime');
    %endTime   = datetime(end_time,   'ConvertFrom', 'posixtime');
    %disp(startTime)

    % === 建立 satelliteScenario，只建一次 ===
    sc = satelliteScenario(startTime, endTime, step);
    sat = satellite(sc, temp_file, 'Name', 'MyLEOSatellite');

    % === 刪除臨時 TLE 檔案 ===
    delete(temp_file);

    % === 為每個 UE 建立 ground station 並計算 access ===
    if start_time == 0
            lat = UE_locations(1);
            lon = UE_locations(2);
            %alt = UE_locations(i,3);
    
            % 建立 ground station
            gs = groundStation(sc, lat, lon);
    
            % 建立 access 並計算 interval
            ac = access(sat, gs);
            intvls = accessIntervals(ac);
            %disp(intvls)
            % 取出 EndTime（若無則維持 NaT）
            if ~isempty(intvls)
                ue_endtime = intvls{1,5};  % EndTime
            end
    else
        ue_endtime = NaT(N, 1, 'TimeZone', 'Asia/Taipei');
        for i = 1:N
            lat = UE_locations(i,1);
            lon = UE_locations(i,2);
            %alt = UE_locations(i,3);    
            % 建立 ground station
            gs = groundStation(sc, lat, lon);    
            % 建立 access 並計算 interval
            ac = access(sat, gs);
            intvls = accessIntervals(ac);
            %disp(intvls)
            % 取出 EndTime（若無則維持 NaT）
            if ~isempty(intvls)
                ue_endtime(i) = intvls{1,5};  % EndTime
            end
            disp(i)
        end
        disp("計算完成")
    end
end
