function elevation = compute_elevation(UE_location, sat_pos)
    r_UE = lla2ecef(UE_location); % UE 位置轉 ECEF
    d = sat_pos - r_UE; % 衛星相對位置向量
    [d_E, d_N, d_U] = ecef2enu(d(1), d(2), d(3), UE_location(1), UE_location(2), UE_location(3));
    elevation = atan2(d_U, sqrt(d_E^2 + d_N^2)) * 180/pi; % 仰角（度）
end