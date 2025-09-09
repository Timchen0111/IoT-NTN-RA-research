%Generate visibility time
clear all
close all
addpath 'C:\Users\88698\OneDrive\桌面\TONIClab\Simulator_new\sgp4\SGP4'; % 添加 SGP4 路徑
%Start
%%% For SGP4 
% 分配 UE 位置
num = 1000;
UE_locations = generate_location(1);
tle = {...
    '1 44714U 19074B   25216.88326253  .00000799  00000+0  72522-4 0  9990', ...
    '2 44714  53.0549  79.9036 0001271  84.0186 276.0948 15.06396482316077'};%starlink 1008
step = 1; % 1 秒
%%找出適合的模擬區間
example_UE = UE_locations(1,:);
example_UE_t = compute_visibility_time(tle, example_UE, 0, 24*60, step);%示範UE的終止時間
example_UE_startt = example_UE_t(1);
example_UE_endt = example_UE_t(2);
disp('選定的基準時間')
disp(example_UE_endt)
start_time = posixtime(example_UE_startt)-60*60; %示範UE終止時間的五分鐘前
end_time = posixtime(example_UE_endt)+60*60; %示範UE終止時間的五分鐘後
uet_all = [];
for i = 1:60
    UE_locations = generate_location(num);
    uet = compute_visibility_time(tle, UE_locations, start_time, end_time, step);
    has_nan = any(isnan(uet), 'all');
    if has_nan
         uet = uet(~any(isnan(uet), 2), :);
    end
    uet_all = [uet_all; uet];
end
save("50km.mat")