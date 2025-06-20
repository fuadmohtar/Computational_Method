% =========================================================================
% PETRONAS PETROL STATION SIMULATION - FINAL SCRIPT
% =========================================================================
% This self-contained script runs a complete, event-driven simulation
% of a Petronas petrol station. It handles user configuration, random
% number generation, station logic, data logging, and final reporting
% formatted to assignment specifications.
%
% To Run:
%   1. Save this entire code as a single file (e.g., "run_petronas_simulation.m").
%   2. Type 'run_petronas_simulation' in the Octave command window.
% =========================================================================

function run_petronas_simulation()
    % --- Main function to encapsulate the entire simulation ---
    clear; clc;

    fprintf("============================================================\n");
    fprintf("--- Petronas Petrol Station Simulator - Octave Version ---\n");
    fprintf("============================================================\n");

    % =====================================================================
    % 1. INITIAL DATA & TABLE SETUP
    % =====================================================================
    fprintf("\n--- Defining and Calculating Initial Data Tables ---\n");
    interArrivalData = { 1,0.25,0,0,0; 2,0.40,0,0,0; 3,0.20,0,0,0; 4,0.15,0,0,0 };
    interArrivalData_Peak = { 1,0.60,0,0,0; 2,0.30,0,0,0; 3,0.10,0,0,0 };
    petrolData = { "Primax95",0.50,0,0,0,2.05; "Primax97",0.30,0,0,0,2.80; "Dynamic Diesel",0.20,0,0,0,2.15 };
    refuelingTimeData = { 3,0.25,0,0,0; 4,0.35,0,0,0; 5,0.25,0,0,0; 6,0.15,0,0,0 };

    interArrivalData = calculate_cdf(interArrivalData);
    interArrivalData_Peak = calculate_cdf(interArrivalData_Peak);
    petrolData = calculate_cdf(petrolData);
    refuelingTimeData = calculate_cdf(refuelingTimeData);

    display_setup_table(interArrivalData, "Table 1.1: Inter-Arrival Times (Non-Peak)");
    display_setup_table(interArrivalData_Peak, "Table 1.2: Inter-Arrival Times (Peak)");
    display_setup_table(petrolData, "Table 2.1: Petrol Types");
    display_setup_table(refuelingTimeData, "Table 3.1: Refueling Times");

    % =====================================================================
    % 2. USER INPUTS
    % =====================================================================
    [numVehicles, rngChoice, modeChoice] = get_user_inputs();
    if modeChoice == 1, activeInterArrivalData = interArrivalData; else, activeInterArrivalData = interArrivalData_Peak; end

    % =====================================================================
    % 3. SIMULATION INITIALIZATION
    % =====================================================================
    fprintf("\n\n--- Initializing Simulation World ---\n");
    if rngChoice == 2, initial_seed = floor(rand() * 100000); lcg_rand('seed', initial_seed); fprintf(" -> LCG seeded with initial value: %d\n", initial_seed); end
    pumps_free_at = zeros(1, 4);
    queue_lane1 = []; queue_lane2 = [];
    log = repmat(struct('arrival_time',0,'petrol_type',"",'quantity',0,'total_cost',0,'rand_inter_arrival',0,'inter_arrival_time',0,'rand_refuel_time',0,'refuel_time',0,'lane',0,'pump',0,'wait_time',0,'service_start',0,'service_end',0,'time_in_system',0), numVehicles, 1);
    simulationClock = 0; next_arrival_time = 0;
    vehicles_generated = 0; vehicles_departed = 0;
    fprintf(" -> World initialized. Starting simulation...\n");

    % =====================================================================
    % 4. MAIN SIMULATION LOOP (EVENT-DRIVEN)
    % =====================================================================
    fprintf("\n============================================================\n--- Main Simulation Events ---\n============================================================\n");

    while vehicles_departed < numVehicles
        busy_pumps_free_times = pumps_free_at(pumps_free_at > 0);
        min_departure_time = min([busy_pumps_free_times, Inf]);

        if (next_arrival_time < min_departure_time) && (vehicles_generated < numVehicles)
            is_arrival_event = true; next_event_time = next_arrival_time;
        else
            is_arrival_event = false; next_event_time = min_departure_time;
        end

        if next_event_time == Inf, break; end
        simulationClock = next_event_time;

        if is_arrival_event
            vehicles_generated = vehicles_generated + 1; vehicleID = vehicles_generated;

            rand_petrol = get_next_rand(rngChoice);
            rand_refuel = get_next_rand(rngChoice);
            petrolType = selectFromDistribution(petrolData, rand_petrol);
            refuelingTime = selectFromDistribution(refuelingTimeData, rand_refuel);

            quantity = 5 + (refuelingTime * 8) + (rand() * 10);
            price_per_litre = petrolData{strcmp(petrolData(:,1), petrolType), 6};
            totalCost = quantity * price_per_litre;

            log(vehicleID).arrival_time = simulationClock; log(vehicleID).petrol_type = petrolType;
            log(vehicleID).refuel_time = refuelingTime; log(vehicleID).rand_refuel_time = rand_refuel;
            log(vehicleID).quantity = quantity; log(vehicleID).total_cost = totalCost;

            fprintf("EVENT (t=%.2f): Vehicle %d arrived.\n", simulationClock, vehicleID);

            [pumps_free_at, queue_lane1, queue_lane2, log] = handle_arrival(vehicleID, simulationClock, log, pumps_free_at, queue_lane1, queue_lane2);

            if vehicles_generated < numVehicles
                rand_arrival = get_next_rand(rngChoice);
                interArrivalTime = selectFromDistribution(activeInterArrivalData, rand_arrival);
                log(vehicles_generated + 1).rand_inter_arrival = rand_arrival;
                log(vehicles_generated + 1).inter_arrival_time = interArrivalTime;
                next_arrival_time = simulationClock + interArrivalTime;
            end
        else % DEPARTURE EVENT
            departing_pump_indices = find(abs(pumps_free_at - simulationClock) < 1e-9);
            for pump_idx = departing_pump_indices
                fprintf("EVENT (t=%.2f): A vehicle has departed from Pump %d.\n", simulationClock, pump_idx);
                pumps_free_at(pump_idx) = 0; vehicles_departed = vehicles_departed + 1;
                [pumps_free_at, queue_lane1, queue_lane2, log] = check_queues_for_pump(pump_idx, simulationClock, log, pumps_free_at, queue_lane1, queue_lane2);
            end
        end
    end

    % =====================================================================
    % 5. FINAL RESULTS & ANALYSIS
    % =====================================================================
    fprintf("\n============================================================\n--- Final Simulation Results ---\n============================================================\n");
    display_final_report_tables(log);
    calculate_and_display_metrics(log);
end

% +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
% SUPPORTING LOCAL FUNCTIONS
% +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

function dataTable = calculate_cdf(dataTable)
    cumulativeProb = 0;
    for i = 1:size(dataTable, 1)
        probability = dataTable{i, 2}; previousCDF = cumulativeProb;
        cumulativeProb = previousCDF + probability;
        dataTable{i, 3} = cumulativeProb; dataTable{i, 4} = previousCDF; dataTable{i, 5} = cumulativeProb;
    end
end

function display_setup_table(dataTable, titleStr)
    disp(titleStr); hasPrice = size(dataTable,2) > 5;
    if(hasPrice)
        disp(" Petrol Type    | Probability |   CDF   | Min Range | Max Range | Price/Litre (RM) ");
        for i = 1:size(dataTable, 1), fprintf(' %-14s | %11.2f | %7.2f | %9.2f | %9.2f | %16.2f \n', dataTable{i,1:6}); end
    else
        disp(" Time (min) | Probability |   CDF   | Min Range | Max Range ");
        for i = 1:size(dataTable, 1), fprintf(' %10d | %11.2f | %7.2f | %9.2f | %9.2f \n', dataTable{i,1:5}); end
    end
    fprintf("\n");
end

function [numVehicles, rngChoice, modeChoice] = get_user_inputs()
    fprintf("\n--- Simulation Configuration ---\n");
    numVehicles = input("Enter the total number of vehicles to simulate (e.g., 100): ");
    disp("Choose RNG: 1: rand(), 2: LCG"); rngChoice = input("Enter your RNG choice (1 or 2): ");
    disp("Choose Mode: 1: Non-Peak, 2: Peak"); modeChoice = input("Enter your mode choice (1 or 2): ");
    if modeChoice == 1, fprintf(" -> Simulating Non-Peak Hours.\n"); else, fprintf(" -> Simulating Peak Hours.\n"); end
end

function randomNumber = get_next_rand(rngChoice)
    if rngChoice == 1, randomNumber = rand(); else, randomNumber = lcg_rand('generate'); end
end

function [pumps_free_at, queue_lane1, queue_lane2, log] = handle_arrival(vehicleID, arrivalTime, log, pumps_free_at, queue_lane1, queue_lane2)
    refuelingTime = log(vehicleID).refuel_time;
    if length(queue_lane1) <= length(queue_lane2), lane = 1; pumps_to_check = [1, 2]; else, lane = 2; pumps_to_check = [3, 4]; end
    log(vehicleID).lane = lane; assigned_pump = 0;
    for p_idx = pumps_to_check
        if pumps_free_at(p_idx) <= arrivalTime, assigned_pump = p_idx; break; end
    end
    if assigned_pump > 0
        fprintf("       -> Vehicle %d goes directly to Pump %d.\n", vehicleID, assigned_pump);
        log(vehicleID).pump = assigned_pump; log(vehicleID).wait_time = 0;
        log(vehicleID).service_start = arrivalTime; log(vehicleID).service_end = arrivalTime + refuelingTime;
        pumps_free_at(assigned_pump) = log(vehicleID).service_end;
    else
        fprintf("       -> Vehicle %d enters queue for Lane %d.\n", vehicleID, lane);
        if lane == 1, queue_lane1(end+1) = vehicleID; else, queue_lane2(end+1) = vehicleID; end
    end
    log(vehicleID).time_in_system = log(vehicleID).service_end - log(vehicleID).arrival_time;
end

function [pumps_free_at, queue_lane1, queue_lane2, log] = check_queues_for_pump(freed_pump_idx, currentTime, log, pumps_free_at, queue_lane1, queue_lane2)
    vehicle_served = false;
    if ismember(freed_pump_idx, [1, 2]) && ~isempty(queue_lane1)
        vehicleID = queue_lane1(1); queue_lane1(1) = []; vehicle_served = true;
    elseif ismember(freed_pump_idx, [3, 4]) && ~isempty(queue_lane2)
        vehicleID = queue_lane2(1); queue_lane2(1) = []; vehicle_served = true;
    end
    if vehicle_served
        refuelingTime = log(vehicleID).refuel_time;
        fprintf("       -> Vehicle %d moves from queue to Pump %d.\n", vehicleID, freed_pump_idx);
        log(vehicleID).pump = freed_pump_idx; log(vehicleID).wait_time = currentTime - log(vehicleID).arrival_time;
        log(vehicleID).service_start = currentTime; log(vehicleID).service_end = currentTime + refuelingTime;
        log(vehicleID).time_in_system = log(vehicleID).service_end - log(vehicleID).arrival_time;
        pumps_free_at(freed_pump_idx) = log(vehicleID).service_end;
    end
end

function display_final_report_tables(log)
    % Displays final tables in a clear, multi-part format to avoid cramping.

    % --- TABLE 1: Vehicle & Cost Summary ---
    fprintf('\n--- Final Log Part 1: Vehicle & Cost Summary ---\n');
    disp(repmat('-', 1, 75));
    fprintf('%-5s | %-14s | %-15s | %-15s | %-14s\n', 'Veh#', 'Petrol Type', 'Refuel Time(min)', 'Quantity (L)', 'Total Cost (RM)');
    disp(repmat('-', 1, 75));
    for i = 1:length(log)
        fprintf('%-5d | %-14s | %-15d | %-15.2f | %-14.2f\n', ...
            i, log(i).petrol_type, log(i).refuel_time, log(i).quantity, log(i).total_cost);
    end
    disp(repmat('-', 1, 75));

    % --- TABLE 2: Arrival & Randomness Details ---
    fprintf('\n\n--- Final Log Part 2: Arrival & Randomness Details ---\n');
    disp(repmat('-', 1, 85));
    fprintf('%-5s | %-12s | %-11s | %-12s | %-11s \n', 'Veh#', 'Arrival Time', 'Inter-Arr', 'RN Inter-Arr', 'RN Refuel');
    disp(repmat('-', 1, 85));
    for i = 1:length(log)
        fprintf('%-5d | %-12.2f | %-11d | %-12.4f | %-11.4f \n', ...
            i, log(i).arrival_time, log(i).inter_arrival_time, log(i).rand_inter_arrival, log(i).rand_refuel_time);
    end
    disp(repmat('-', 1, 85));

    % --- TABLE 3: Pumping & Timing Details ---
    fprintf('\n\n--- Final Log Part 3: Pumping & Timing Details ---\n');
    disp(repmat('-', 1, 90));
    fprintf('%-5s | %-6s | %-6s | %-10s | %-11s | %-9s | %-14s \n', 'Veh#', 'Lane#', 'Pump#', 'Wait Time', 'Svc Start', 'Svc End', 'Time in System');
    disp(repmat('-', 1, 90));
    for i = 1:length(log)
        fprintf('%-5d | %-6d | %-6d | %-10.2f | %-11.2f | %-9.2f | %-14.2f \n', ...
            i, log(i).lane, log(i).pump, log(i).wait_time, log(i).service_start, log(i).service_end, log(i).time_in_system);
    end
    disp(repmat('-', 1, 90));
end

function calculate_and_display_metrics(log)
    % Calculates and displays all final performance metrics as required
    wait_times = [log.wait_time];
    time_in_system = [log.time_in_system];

    avgWaitTime = mean(wait_times);
    probWaiting = mean(wait_times > 0.001) * 100;
    avgTimeInSystem = mean(time_in_system);

    fprintf('\n--- Performance Metrics ---\n');
    fprintf('Average waiting time for a vehicle: %.2f minutes\n', avgWaitTime);
    fprintf('Probability that a vehicle has to wait: %.2f%%\n', probWaiting);
    fprintf('Average time a vehicle spends in the system: %.2f minutes\n', avgTimeInSystem);

    fprintf('\n--- Pump Specific Metrics ---\n');
    for p = 1:4
        pump_services = [log([log.pump] == p).refuel_time];
        if ~isempty(pump_services)
            avg_svc_time = mean(pump_services);
            fprintf('Average service time at Pump %d: %.2f minutes (%d vehicles served)\n', p, avg_svc_time, length(pump_services));
        else
            fprintf('Pump %d did not serve any vehicles.\n', p);
        end
    end
end

function randomNumber = lcg_rand(action, value)
    % A complete Linear Congruential Generator
    persistent seed;
    persistent a c m;

    if isempty(a) % Initialize parameters only once
        m = 2^31;       % Modulus
        a = 1103515245; % Multiplier
        c = 12345;      % Increment
    end

    if nargin == 2 && strcmp(action, 'seed')
        seed = value; % Set the seed from user input
        randomNumber = -1; % Special value to indicate seeding
        return;
    end

    % Generate next number in sequence
    seed = mod(a * seed + c, m);
    randomNumber = seed / m; % Normalize to [0,1)
end

function selectedValue = selectFromDistribution(dataTable, randomNumber)
    % Selects an item from a table based on its CDF
    selectedValue = nan; numRows = size(dataTable, 1);
    if numRows == 0, warning('Input dataTable is empty.'); return; end
    valueColumnIndex = 1; cdfColumnIndex = 5; % Value is in col 1, CDF/MaxRange is in col 5
    for i = 1:numRows
        if randomNumber <= dataTable{i, cdfColumnIndex}
            selectedValue = dataTable{i, valueColumnIndex};
            return;
        end
    end
    if isnan(selectedValue), selectedValue = dataTable{numRows, valueColumnIndex}; end % Fallback for rand() being exactly 1
end
