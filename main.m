%main fuction
clear all
close all
addpath 'C:\Users\88698\OneDrive\桌面\TONIClab\Simulator_new\sgp4\SGP4'; % 添加 SGP4 路徑
%Start
%UE_number = 5000;
N_sc = 48;
N_EDT = 4;
RAO = 640; %ms
BO = 1; %NBIoT BO ID 7 先停用backoff(Wu's work理論推導無backoff)
%Calculate visibility time of UE
%visibility_time = Acquire_visibility_time();
ACB = ones(1,3);
replica_num = ones(1,3);
serviceoff_time = 11000; %time unit: ms
t_req = [30000 20000 serviceoff_time];
%set1: t1=30s, t2=60s
%set2: t1=20s, t2=30s
%%%Use for simulation control
UE_num_array = 1000:1000:10000;
Parameter_setting = [1 2 3]; %1:Wu's allocation 2:equal resource 3: No grouping
all_success_rate = zeros(length(Parameter_setting),length(UE_num_array));
average_delay = zeros(length(Parameter_setting),length(UE_num_array));
record_N_sc_CE = zeros(1,length(t_req));
record_group = zeros(1,length(t_req));
record_ACB = zeros(1,length(t_req));
%%% For SGP4 
% 分配 UE 位置
UE_locations = generate_location(max(UE_num_array));
tle = {...
    '1 44714U 19074B   25216.88326253  .00000799  00000+0  72522-4 0  9990', ...
    '2 44714  53.0549  79.9036 0001271  84.0186 276.0948 15.06396482316077'};%starlink 1008
step = 1; % 1 秒
%%找出適合的模擬區間
example_UE = UE_locations(1,:);
example_UE_endt = compute_visibility_time(tle, example_UE, 0, 24*60, step);%示範UE的終止時間
disp('選定的基準時間')
disp(example_UE_endt)
start_time = posixtime(example_UE_endt)-600; %示範UE終止時間的十分鐘前
end_time = posixtime(example_UE_endt)+600; %示範UE終止時間的十分鐘後
endt = compute_visibility_time(tle, UE_locations, start_time, end_time, step);
disp('獲取終止時間')
visibility_time_all = endt-start_time;
disp('獲取可視時間集')
save('visibility_time_all.mat')
%% 

%%%
for idx = length(Parameter_setting):-1:1
    count = 0;
    if Parameter_setting(idx) == 3
        with_group = false;
    else
        with_group = true;
    end
for UE_num = UE_num_array
    count = count+1;
    disp("UE數量")
    disp(UE_num)
    %vt = rand(1,UE_num);
    %visibility_time = 246900*ones(1,UE_num).*vt; %Set 4 LEO
    %endt = compute_visibility_time(tle, UE_locations, start_time, end_time, step);
    %visibility_time = posixtime(endt)-posixtime(datetime('now'));
    visibility_time = visibility_time_all(1:UE_num);
    UE_state = zeros(1,UE_num); %0: active, 1: complete, -1: out of service time
    delay = zeros(1,UE_num);
    %Backoff = zeros(1,UE_num);
    attempt = zeros(1,UE_num);
    simulation_time = 0;
    N_sc_CE = [16 16 16];
    while sum(UE_state==0) > 0 %Simulation time
        transmissionAttemptsEachSlot = zeros(N_EDT,N_sc);
        attemptSource = zeros(N_EDT,N_sc);
        group_count = [0,0,0]; %For gold estimator
        for i = 1:UE_num
            if visibility_time(i) < serviceoff_time && UE_state(i) == 0
               UE_state(i) = -1; %Check out of visibility
            end
            if UE_state(i) == 0 %&& Backoff(i) <= 0
                %Determine the CE level
                if visibility_time(i)<t_req(2)
                    group = 3;
                elseif visibility_time(i)<t_req(1)
                    group = 2;
                else
                    group = 1;
                end
                %Acquire RACH parameter and allowable resource
                %此處我們假定gold estimator是根據前一次RAO時的分佈，因為RAparameter是藉由SIB發送給UE的，不可能立即更新。這裡的更新是為了提供gNB下次的資訊。
                group_count(group) = group_count(group)+1;
                UE_ACB = ACB(group);
                UE_rep = replica_num(group);
                %ACB test
                if rand(1) <= UE_ACB %ACB方法
                    access = 1;     
                    attempt(i) = 1;
                else
                    access = 0;
                end
                %select resource
                if N_sc_CE(group) > 0
                    if with_group == true
                        if group == 1
                            N_sc_num = [1 N_sc_CE(1)];
                        elseif group == 2
                            N_sc_num = [N_sc_CE(1)+1 N_sc_CE(2)+N_sc_CE(1)];
                        else
                            N_sc_num =  [N_sc_CE(2)+N_sc_CE(1)+1 N_sc_CE(3)+N_sc_CE(2)+N_sc_CE(1)];
                        end
                    else
                        N_sc_num = [1 N_sc];
                    end
                else
                    access = 0;
                end
                if access == 1
                    Chosen_EDT_set = randperm(N_EDT,UE_rep);
                    for replica = 1:UE_rep
                        Chosen_carrier = randi([N_sc_num(1), N_sc_num(2)]);
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
                    UE_state(CurrentUE) = 1;
                    delay(CurrentUE) = simulation_time;
                    attempt(CurrentUE) = 0;
                end
            end
        end
        %for i = 1:UE_num
            %Backoff
            %if UE_state(i) == 0 && Backoff(i) <= 0 && attempt(i) == 1
                %Backoff(i) = randi(BO);
                %attempt(i) = 0;
            %end
        %end
        %load estimation (LAYER 1)
        %gold estimator:use variable "UE_group"
        %resource allocation (LAYER 2)
        %Wu's grouping
        if Parameter_setting(idx) == 1          
            allocated_result = zeros(8,3);
            case_set = [1 1 1;1 1 2; 1 2 1;1 2 2; 2 1 1;2 1 2; 2 2 1;2 2 2];
            for acb_case = 1:length(case_set)
                remaining_resource = N_sc;
                for i = 3:-1:1
                    if case_set(acb_case,i) == 1
                        allocated_resource = RAO*group_count(i)/(t_req(i)*(1-1/group_count(i))^(group_count(i)-1));
                    else
                        allocated_resource = 1/(1-(RAO/t_req(i))^(1/(group_count(i)-1)));
                    end
                    allocated_resource = ceil(allocated_resource); 
                    if allocated_resource > remaining_resource
                        allocated_resource = remaining_resource;
                    end
                    remaining_resource = remaining_resource - allocated_resource;
                    allocated_result(acb_case,i) = allocated_resource;  
                end
                %處理剩餘的resource
                %choice 1:平分
                allocated_result(acb_case,:) = allocated_result(acb_case,:)+floor(remaining_resource/3);
                allocated_result(acb_case,3) = allocated_result(acb_case,3)+mod(remaining_resource,3);
                %choice 2:全給最高priority
                %N_sc_CE(3) = N_sc_CE(3)+remaining_resource;
            end
            %Calculate throughput
            thr = zeros(1, length(case_set));
            for acb_case = 1:length(case_set)
                Z = allocated_result(acb_case,:);      % 取出該 case 的資源配置（3×1）
                mask = Z ~= 0;                          % 避免除以0
                P_success = zeros(1,3);
                P_success(mask) = (1 - 1 ./ Z(mask)).^(group_count(mask) - 1);
                thr(acb_case) = sum(group_count .* P_success);
            end
            select_index = find(thr == max(thr), 1); %只回傳一個值
            N_sc_CE = allocated_result(select_index,:);

            %%for debug%%
            if UE_num == 5000
                 record_N_sc_CE(end+1,:) = N_sc_CE;
                 record_group(end+1,:) = group_count;
                 record_ACB(end+1,:) = ACB;
            end
        end
        %RA parameter control (LAYER 3)
        if Parameter_setting(idx) < 3
            ACB = min(1,N_sc_CE./group_count);                
        else
            ACB = min(1,N_sc/sum(group_count))*[1 1 1];
        end

        visibility_time = visibility_time-RAO;
        simulation_time = simulation_time+RAO;
        %Backoff = Backoff-RAO;
    end
    success_rate = sum(UE_state==1)/UE_num;
    all_success_rate(idx,count) = success_rate;
    average_delay(idx,count) = mean(delay(delay ~= 0));
end
end

legend_text = {'Dynamic resource allocation', 'Equal resource','No grouping'};
%legend_text = {'No BO', 'BO = 4096','BO = 16384'};
figure(1)
plot(UE_num_array,all_success_rate(1,:),'-o');
hold on;
plot(UE_num_array,all_success_rate(2,:),'-^');
hold on;
plot(UE_num_array,all_success_rate(3,:),'-*');
xlabel('Number of UE')
ylabel('Success probability')
legend(legend_text,'location','best');
figure(2)
plot(UE_num_array,average_delay(1,:)/1000,'-o');
hold on;
plot(UE_num_array,average_delay(2,:)/1000,'-^');
hold on;
plot(UE_num_array,average_delay(3,:)/1000,'-*');
xlabel('Number of UE')
ylabel('average delay (s)')
legend(legend_text,'location','best'); 
%test