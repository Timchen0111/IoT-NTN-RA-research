function satdata = parse_tle(tle_input)
    % 輸入：
    % tle_input: 數組格式（[Line 1], [Line 2]）、單行 TLE 字符串或雙行 TLE 字符串數組
    % 輸出：
    % satdata: 包含 xno, eo, xincl, omegao, xmo, xnodeo, bstar 的結構

    satdata = struct();
    
    if iscell(tle_input) && length(tle_input) == 2 && iscell(tle_input{1})
        % 數組格式
        line1 = tle_input{1};
        line2 = tle_input{2};
        
        % 解析 Line 2
        satdata.xno = line2{8} * (2 * pi) / (24 * 60); % 平均運動 (rad/min)
        satdata.eo = str2double(['0.', char(line2{5})]); % 偏心率
        satdata.xincl = deg2rad(line2{3}); % 軌道傾角 (rad)
        satdata.omegao = deg2rad(line2{4}); % 近地點角距 (rad)
        satdata.xmo = deg2rad(line2{7}); % 平近點角 (rad)
        satdata.xnodeo = deg2rad(line2{6}); % 升交點赤經 (rad)
        
        % 解析 Line 1
        bstar_str = char(line1{7}); % B* 係數 (例如 '20716-3')
        bstar_mantissa = str2double(['0.', bstar_str(1:5)]);
        bstar_exponent = str2double(bstar_str(6:end));
        satdata.bstar = bstar_mantissa * 10^bstar_exponent;
        
    elseif ischar(tle_input) || isstring(tle_input)
        % 單行 TLE
        tle_str = char(tle_input);
        name_end = strfind(tle_str, '1 ')-1;
        if isempty(name_end)
            error('無效的單行 TLE 格式：無法找到 Line 1');
        end
        line1_start = name_end + 1;
        line1_end = line1_start + 68;
        line2_start = line1_end + 1;
        line1 = tle_str(line1_start:line1_end);
        line2 = tle_str(line2_start:end);
        
        % 解析 Line 2
        xno_str = strtrim(line2(53:end));
        satdata.xno = str2double(xno_str) * (2 * pi) / (24 * 60);
        satdata.eo = str2double(['0.', line2(27:33)]);
        satdata.xincl = deg2rad(str2double(line2(9:16)));
        satdata.omegao = deg2rad(str2double(line2(18:25)));
        satdata.xmo = deg2rad(str2double(line2(44:51)));
        satdata.xnodeo = deg2rad(str2double(line2(35:42)));
        
        % 解析 Line 1
        bstar_mantissa = str2double(['0.', line1(54:59)]);
        bstar_exponent = str2double(line1(60:61));
        satdata.bstar = bstar_mantissa * 10^bstar_exponent;
        
    elseif iscell(tle_input) && length(tle_input) == 2 && ischar(tle_input{1})
        % 雙行 TLE 字符串
        line1 = tle_input{1};
        line2 = tle_input{2};
        
        % 解析 Line 2
        xno_str = strtrim(line2(53:end));
        satdata.xno = str2double(xno_str) * (2 * pi) / (24 * 60);
        satdata.eo = str2double(['0.', line2(27:33)]);
        satdata.xincl = deg2rad(str2double(line2(9:16)));
        satdata.omegao = deg2rad(str2double(line2(18:25)));
        satdata.xmo = deg2rad(str2double(line2(44:51)));
        satdata.xnodeo = deg2rad(str2double(line2(35:42)));
        
        % 解析 Line 1
        bstar_mantissa = str2double(['0.', line1(54:59)]);
        bstar_exponent = str2double(line1(60:61));
        satdata.bstar = bstar_mantissa * 10^bstar_exponent;
    else
        error('無效的 TLE 輸入格式');
    end

    % 驗證數據
    if any(isnan([satdata.xno, satdata.eo, satdata.xincl, satdata.omegao, satdata.xmo, satdata.xnodeo, satdata.bstar]))
        error('TLE 解析失敗：無效字段');
    end
end