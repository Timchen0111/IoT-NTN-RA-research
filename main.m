%main fuction
clear all
close all

%Start
N_sc = 48;
N_EDT = 4;
RAO = 640; %ms
BO = 1; %NBIoT BO ID 7 先停用backoff(Wu's work理論推導無backoff)

%Calculate visibility time of UE
replica_num = 1;
serviceoff_time = 11000; %time unit: ms
t_req = [50000 serviceoff_time];

%Use for simulation control
UE_num_array = 40000:5000:60000;
Parameter_setting = [1 2 3]; %1:No priority  2: Priority on queue 3: Priority on queue and visibility time

% 不同的queue threshold用於parameter 2和3
queue_thr_array = [5 10];
queue_thr_default = 10; % parameter 1使用的固定值

% 結果儲存陣列
all_success_rate_param1 = zeros(1, length(UE_num_array));
average_delay_param1 = zeros(1, length(UE_num_array));
all_success_rate_param2 = zeros(length(queue_thr_array), length(UE_num_array));
average_delay_param2 = zeros(length(queue_thr_array), length(UE_num_array));
all_success_rate_param3 = zeros(length(queue_thr_array), length(UE_num_array));
average_delay_param3 = zeros(length(queue_thr_array), length(UE_num_array));

record_N_sc_CE = zeros(1,length(t_req));
record_group = zeros(1,length(t_req));
record_ACB = zeros(1,length(t_req));

%%% For visibility time
load('500km.mat');%5.4772 41.09
uet = uet_all;
endt = uet(:,2);
startt = uet(:,1);
t_simulation_start = min(startt); 
visibility_time_all = endt-t_simulation_start;
start_time_all = startt-t_simulation_start;

%% For Possion arrival generation
lambda = 0.01; %Calculate average number of packets
pr = 1-exp(-lambda);  
arrival_type = "beta";
%% For Beta arrival generation
alpha = 3;
beta = 4;
activation = 60000; %1 minute (Le, 2024)
UE_arrival_time = activation*betarnd(3,4,[20,max(UE_num_array)]); %產生每個UE的activation time

%% 初始化ACB變數
ACB = [1, 1];

%% 主要模擬迴圈
for idx = 1:length(Parameter_setting)
    current_param = Parameter_setting(idx);
    if current_param == 1
        % Parameter 1: No priority - 使用固定的queue threshold
        fprintf("執行 Parameter 1 (No priority) - 固定 Queue Threshold = %d\n", queue_thr_default);
        queue_thr = queue_thr_default;
        count = 0;
        
        for UE_num = UE_num_array
            count = count + 1;
            fprintf("Parameter 1, UE數量: %d\n", UE_num);
            
            [success_rate, avg_delay] = simulate_scenario(UE_num, queue_thr, current_param, ...
                visibility_time_all, start_time_all, pr,arrival_type, ACB, N_sc, N_EDT, RAO, ...
                serviceoff_time, replica_num,UE_arrival_time);
            
            all_success_rate_param1(count) = success_rate;
            average_delay_param1(count) = avg_delay;
        end
        
    elseif current_param == 2
        % Parameter 2: Priority on queue - 比較不同的queue thresholds
        fprintf("執行 Parameter 2 (Priority on queue) - 比較不同 Queue Thresholds\n");
        
        for queue_idx = 1:length(queue_thr_array)
            queue_thr = queue_thr_array(queue_idx);
            count = 0;
            
            for UE_num = UE_num_array
                count = count + 1;
                fprintf("Parameter 2, Queue Threshold: %d, UE數量: %d\n", queue_thr, UE_num);
                
                [success_rate, avg_delay] = simulate_scenario(UE_num, queue_thr, current_param, ...
                    visibility_time_all, start_time_all, pr,arrival_type, ACB, N_sc, N_EDT, RAO, ...
                    serviceoff_time, replica_num,UE_arrival_time);
                
                all_success_rate_param2(queue_idx, count) = success_rate;
                average_delay_param2(queue_idx, count) = avg_delay;
            end
        end
    else % current_param == 3
        % Parameter 3: Priority on queue and visibility time - 比較不同的queue thresholds
        fprintf("執行 Parameter 3 (Priority on queue and visibility time) - 比較不同 Queue Thresholds\n");
        
        for queue_idx = 1:length(queue_thr_array)
            queue_thr = queue_thr_array(queue_idx);
            count = 0;
            
            for UE_num = UE_num_array
                count = count + 1;
                fprintf("Parameter 3, Queue Threshold: %d, UE數量: %d\n", queue_thr, UE_num);
                
                [success_rate, avg_delay] = simulate_scenario(UE_num, queue_thr, current_param, ...
                    visibility_time_all, start_time_all, pr,arrival_type, ACB, N_sc, N_EDT, RAO, ...
                    serviceoff_time, replica_num,UE_arrival_time);
                
                all_success_rate_param3(queue_idx, count) = success_rate;
                average_delay_param3(queue_idx, count) = avg_delay;
            end
        end
    end
end

%% 繪圖部分
colors = ['k', 'b', 'g'];
line_styles = {'-o', '-^', '-s'};

% 成功率比較圖
figure(1);
clf;

% Parameter 2 的結果 (不同queue thresholds)
for queue_idx = 1:length(queue_thr_array)
    plot(UE_num_array, all_success_rate_param2(queue_idx, :), ...
         line_styles{queue_idx}, 'Color', colors(1), 'LineWidth', 1.5);
    hold on;
end
% Parameter 1 的結果 (黑色粗線)
plot(UE_num_array, all_success_rate_param1, '-', 'Color', 'r', 'LineWidth', 1.5);
hold on;

% Parameter 3 的結果 (不同queue thresholds)
for queue_idx = 1:length(queue_thr_array)
    plot(UE_num_array, all_success_rate_param3(queue_idx, :), ...
         line_styles{queue_idx}, 'Color', colors(2), 'LineWidth', 1.5);
    hold on;
end

xlabel('Number of UE');
ylabel('Success Probability');
title('Success Rate Comparison');

% 建立圖例
legend_text = cell(1, 1 + 2*length(queue_thr_array));
legend_text{4} = sprintf('No priority', queue_thr_default);
for i = 1:length(queue_thr_array)
    legend_text{i} = sprintf('Priority on queue (Queue Thr = %d)', queue_thr_array(i));
end
for i = 1:length(queue_thr_array)
    legend_text{i+1+length(queue_thr_array)} = sprintf('Priority on queue & visibility (Queue Thr = %d)', queue_thr_array(i));
end
legend(legend_text, 'Location', 'southwest');
grid on;

% 延遲比較圖
figure(2);
clf;

% Parameter 1 的結果
plot(UE_num_array, average_delay_param1/1000, '-o', 'Color', 'k', 'LineWidth', 1);
hold on;

% Parameter 2 的結果 (不同queue thresholds)
for queue_idx = 1:length(queue_thr_array)
    plot(UE_num_array, average_delay_param2(queue_idx, :)/1000, ...
         line_styles{queue_idx}, 'Color', colors(1), 'LineWidth', 1);
    hold on;
end

% Parameter 3 的結果 (不同queue thresholds)
for queue_idx = 1:length(queue_thr_array)
    plot(UE_num_array, average_delay_param3(queue_idx, :)/1000, ...
         line_styles{queue_idx}, 'Color', colors(2), 'LineWidth', 1.5);
    hold on;
end

xlabel('Number of UE');
ylabel('Average Delay (s)');
title('Average Delay Comparison');
legend(legend_text, 'Location', 'northwest');
grid on;

% Parameter 2 和 3 的詳細比較圖
figure(3);

% Parameter 2
subplot(2,2,1);
for queue_idx = 1:length(queue_thr_array)
    plot(UE_num_array, all_success_rate_param2(queue_idx, :), ...
         line_styles{queue_idx}, 'Color', colors(queue_idx), 'LineWidth', 1.5);
    hold on;
end
xlabel('Number of UE');
ylabel('Success Probability');
title('Parameter 2: Priority on Queue');
legend_text_detail = {};
for i = 1:length(queue_thr_array)
    legend_text_detail{i} = sprintf('Queue Threshold = %d', queue_thr_array(i));
end
legend(legend_text_detail, 'Location', 'southwest');
grid on;

subplot(2,2,2);
for queue_idx = 1:length(queue_thr_array)
    plot(UE_num_array, average_delay_param2(queue_idx, :)/1000, ...
         line_styles{queue_idx}, 'Color', colors(queue_idx), 'LineWidth', 1.5);
    hold on;
end
xlabel('Number of UE');
ylabel('Average Delay (s)');
title('Parameter 2: Priority on Queue');
legend(legend_text_detail, 'Location', 'northwest');
grid on;

% Parameter 3
subplot(2,2,3);
for queue_idx = 1:length(queue_thr_array)
    plot(UE_num_array, all_success_rate_param3(queue_idx, :), ...
         line_styles{queue_idx}, 'Color', colors(queue_idx), 'LineWidth', 1.5);
    hold on;
end
xlabel('Number of UE');
ylabel('Success Probability');
title('Parameter 3: Priority on Queue & Visibility');
legend(legend_text_detail, 'Location', 'southwest');
grid on;

subplot(2,2,4);
for queue_idx = 1:length(queue_thr_array)
    plot(UE_num_array, average_delay_param3(queue_idx, :)/1000, ...
         line_styles{queue_idx}, 'Color', colors(queue_idx), 'LineWidth', 1.5);
    hold on;
end
xlabel('Number of UE');
ylabel('Average Delay (s)');
title('Parameter 3: Priority on Queue & Visibility');
legend(legend_text_detail, 'Location', 'northwest');
grid on;

fprintf('模擬完成！\n');

%% 模擬函數
function [success_rate, avg_delay] = simulate_scenario(UE_num, queue_thr, parameter, ...
    visibility_time_all, start_time_all, pr, arrival_type , ACB, N_sc, N_EDT, RAO, ...
    serviceoff_time, replica_num,UE_arrival_time)
    
    % 檢查陣列長度
    if UE_num > length(visibility_time_all)
        error('UE_num (%d) 超過可用數據長度 (%d)', UE_num, length(visibility_time_all));
    end
    
    visibility_time = visibility_time_all(1:UE_num)*1000;
    start_time = start_time_all(1:UE_num)*1000;
    UE_state = ones(1,UE_num); %0: ACTIVE, 1: IDLE, -1: out of service time
    delay = [];
    number_of_packet = zeros(1,UE_num);
    attempt = zeros(1,UE_num);
    simulation_time = 0;
    N_sc_CE = 48;
    queue = zeros(1,UE_num);
    successful_packet = 0;
    all_packet = 0;
    all_start = cell(1, UE_num);
    for i = 1:UE_num
        all_start{i}.data = {}; 
        all_start{i}.front_idx = 1;
    end
    UE_now_arrival = UE_arrival_time(1,:);
    record_packet_num = ones(1,UE_num);
    while simulation_time < max(visibility_time_all)*1000 %Simulation time
        transmissionAttemptsEachSlot = zeros(N_EDT,N_sc);
        attemptSource = zeros(N_EDT,N_sc);
        %Poisson arrival
        %Generate Poisson arrival
        uerand = rand(1,UE_num);
        UEcount = 0;
        
        for i = 1:UE_num
            if visibility_time(i) < serviceoff_time
               UE_state(i) = -1; %Check out of visibility
            end
            if start_time(i) > simulation_time
                continue %visibility period尚未開始
            end
            if arrival_type == "Poisson"
                if uerand(i) < pr
                    all_packet = all_packet+1;
                    queue(i) = queue(i)+1;
                    UE_state(i) = 0;
                    all_start{i}.data{end+1} = simulation_time;
                end
            else
                if simulation_time < UE_now_arrival(i) && UE_now_arrival(i) < simulation_time+RAO %Activation in this RAO
                    all_packet = all_packet+1;
                    queue(i) = queue(i)+1;
                    UE_state(i) = 0;
                    all_start{i}.data{end+1} = simulation_time;
                    record_packet_num(i) = record_packet_num(i)+1;
                    UE_now_arrival(i) = 60000*(record_packet_num(i)-1)+UE_arrival_time(record_packet_num(i),i); %下一次的activation time
                end
            end
            if UE_state(i) == 0
                UEcount = UEcount + 1;
                
                % 初始化ACB值
                if parameter == 1
                    % Parameter 1: No priority - 所有UE使用相同ACB
                    UE_ACB = ACB(1);
                elseif parameter == 2
                    % Parameter 2: Priority on queue only
                    if queue(i) > queue_thr
                        UE_ACB = ACB(2);  % 高優先級（較高的ACB值）
                    else
                        UE_ACB = ACB(1);  % 低優先級
                    end
                else % parameter == 3
                    % Parameter 3: Priority on queue and visibility time
                    if queue(i) > queue_thr
                        UE_ACB = ACB(2);  % 高優先級（較高的ACB值）
                    else
                        UE_ACB = ACB(1);  % 低優先級
                    end
                    
                    % 額外的visibility time priority
                    if visibility_time(i) < 10000  % 30秒
                        UE_ACB = ACB(2);  % 接近離開可視範圍的UE獲得高優先級
                    end
                end
                
                UE_rep = replica_num;
                %ACB test
                if rand(1) <= UE_ACB %ACB方法
                    access = 1;     
                    attempt(i) = 1;
                else
                    access = 0;
                end
                if access == 1
                    Chosen_EDT_set = randperm(N_EDT,UE_rep);
                    for replica = 1:UE_rep
                        Chosen_carrier = randi(N_sc_CE);
                        Chosen_EDT = Chosen_EDT_set(replica);
                        transmissionAttemptsEachSlot(Chosen_EDT,Chosen_carrier) = transmissionAttemptsEachSlot(Chosen_EDT,Chosen_carrier)+1;
                        attemptSource(Chosen_EDT,Chosen_carrier) = i; %Record the UE transmitting packet                      
                    end
                end
            end
        end
       
        for i = 1:N_EDT
            for j = 1:N_sc
                %Check collision
                %Report success UE
                if transmissionAttemptsEachSlot(i,j) == 1 %No collision, not has been decoded
                    CurrentUE = attemptSource(i,j);
                    queue(CurrentUE) = queue(CurrentUE)-1;
                    successful_packet = successful_packet+1;
                    start = all_start{CurrentUE}.data{all_start{CurrentUE}.front_idx};
                    all_start{CurrentUE}.front_idx = all_start{CurrentUE}.front_idx + 1;
                    delay(end+1) = simulation_time - start;
                    if queue(CurrentUE) == 0
                        UE_state(CurrentUE) = 1;
                    end
                    attempt(CurrentUE) = 0;
                end
            end
        end
        
        %resource allocation and RA parameter control
        if parameter == 1             
            ACB = min(1,N_sc/UEcount)*[1 1];  % No priority: 兩個ACB值相同
        else
            ACB = [min(1,N_sc/UEcount), 1];   % With priority: ACB(1) < ACB(2)
        end

        visibility_time = visibility_time-RAO;
        simulation_time = simulation_time+RAO;
    end
    
    % 避免除零錯誤
    if all_packet > 0
        success_rate = successful_packet/all_packet;
    else
        success_rate = 0;
    end
    
    if ~isempty(delay)
        avg_delay = mean(delay);
    else
        avg_delay = 0;
    end
end