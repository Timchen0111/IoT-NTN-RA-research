function UE_locations = generate_location(num_UE)
% 台北市中心位置 (近似)
center_lat = 25;     % 緯度
center_lon = 121.5;    % 經度
radius_km = 50;           % 半徑 500 公里
earth_radius = 6371;      % 地球半徑 (km)

% 隨機產生角度與距離 (均勻分布在圓內)
theta = 2 * pi * rand(num_UE, 1);                        % 隨機角度 [0, 2π]
r = radius_km * sqrt(rand(num_UE, 1));                   % 均勻圓內距離

% 將 km 轉換為球面角度
delta_lat = (r ./ earth_radius) .* cos(theta);           % 緯度方向距離
delta_lon = (r ./ earth_radius) .* sin(theta) ./ cosd(center_lat);  % 經度方向距離（考慮緯度修正）

% 計算每個 UE 的實際位置
UE_locations = zeros(num_UE, 3);
UE_locations(:,1) = center_lat + rad2deg(delta_lat);
UE_locations(:,2) = center_lon + rad2deg(delta_lon);
UE_locations(:,3) = 0;  % 假設都在地表
