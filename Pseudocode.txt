Pseudocode

BEGIN run_petronas_simulation
    CLEAR console and variables
    PRINT welcome message

    // 1. INITIAL DATA SETUP
    PRINT "Defining and Calculating Initial Data Tables"
    DEFINE inter-arrival, petrol, and refueling time data (peak and non-peak)
    CALCULATE cumulative distribution (CDF) for each data table
    DISPLAY setup tables

    // 2. USER INPUT
    PROMPT user for:
        - number of vehicles to simulate
        - random number generator choice (rand or LCG)
        - simulation mode (peak or non-peak)
    SET active inter-arrival data based on mode

    // 3. SIMULATION INITIALIZATION
    INITIALIZE simulation clock, queues, pump states, logs, and RNG seed if using LCG

    // 4. MAIN SIMULATION LOOP (EVENT-DRIVEN)
    WHILE number of vehicles departed < total vehicles
        DETERMINE next event time:
            - either next vehicle arrival
            - or earliest pump finish time (departure)

        ADVANCE simulation clock to next event time

        IF event is ARRIVAL
            INCREMENT vehicle count
            GENERATE random values for petrol type and refuel time
            SELECT petrol type and refuel time using distributions
            CALCULATE quantity and total cost
            LOG vehicle data
            HANDLE vehicle arrival (assign to pump or queue)
            IF more vehicles to generate
                GENERATE next inter-arrival time and schedule next arrival
        ELSE
            FOR each pump with vehicle finishing now
                MARK pump as free
                INCREMENT vehicles departed
                CHECK corresponding lane queue and assign next vehicle if any
    END WHILE

    // 5. FINAL RESULTS
    DISPLAY final log tables (Vehicle Summary, Arrival Info, Pump Info)
    CALCULATE and DISPLAY performance metrics

END run_petronas_simulation


Support Function

calculate_cdf(dataTable)

FOR each row in dataTable
    ADD current probability to cumulative total
    UPDATE CDF, MinRange, and MaxRange
RETURN updated dataTable


display_setup_table(dataTable, title)

PRINT title
IF table includes petrol pricing
    PRINT formatted header for petrol table
    PRINT each row with petrol type, probability, ranges, and price
ELSE
    PRINT formatted header for timing table
    PRINT each row with time, probability, and ranges


get_user_inputs()
PROMPT user for:
    - number of vehicles
    - RNG type (1 = rand, 2 = LCG)
    - simulation mode (1 = Non-peak, 2 = Peak)
RETURN user inputs


get_next_rand(rngChoice)

IF using rand() THEN return rand()
IF using LCG THEN call lcg_rand('generate')
RETURN random number


handle_arrival(vehicleID, arrivalTime, log, pumps_free_at, queue_lane1, queue_lane2)

GET refueling time from log
DETERMINE lane with shorter queue
CHECK pumps in selected lane for availability
IF pump available
    ASSIGN vehicle to pump
    SET service start and end times
    UPDATE pump availability
ELSE
    ADD vehicle to selected lane's queue
RETURN updated pump and queue states


check_queues_for_pump(pump_idx, currentTime, log, pumps_free_at, queue_lane1, queue_lane2)

IF pump belongs to Lane 1 AND Lane 1 has waiting vehicles
    ASSIGN next vehicle to pump
    UPDATE log with timings
    UPDATE pump free time
ELSE IF pump belongs to Lane 2 AND Lane 2 has waiting vehicles
    Same as above
RETURN updated pump and queue states


display_final_report_tables(log)

PRINT "Final Log Part 1: Vehicle & Cost Summary"
FOR each vehicle
    PRINT petrol type, refuel time, quantity, cost

PRINT "Final Log Part 2: Arrival & Randomness Details"
FOR each vehicle
    PRINT arrival time, inter-arrival, random numbers

PRINT "Final Log Part 3: Pumping & Timing Details"
FOR each vehicle
    PRINT lane, pump, wait time, service times, time in system



calculate_and_display_metrics(log)

CALCULATE:
    - Average wait time
    - Probability of waiting
    - Average time in system

PRINT metrics

FOR each pump
    CALCULATE average service time
    PRINT number of vehicles served


lcg_rand(action, value)

IF action == 'seed'
    STORE the seed
ELSE IF action == 'generate'
    CALCULATE next value using LCG formula:
        seed = (a * seed + c) mod m
    RETURN normalized value (seed / m)


selectFromDistribution(dataTable, randomNumber)

FOR each row in dataTable
    IF randomNumber <= MaxRange (column 5)
        RETURN corresponding value (column 1)
RETURN last value as fallback




