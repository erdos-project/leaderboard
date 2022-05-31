#!/bin/bash

export SIMULATOR_PORT=$1
export TRAFFIC_MANAGER_PORT=$2
export TOWN=$3
export MIN_ROUTE=$4
export MAX_ROUTE=$5

timely_setup=(False)
num_rep=7
frame_rate=40

# Assumes that $CARLA_HOME AND $PYLOT_HOME are set.
source leaderboard/scripts/utils.sh

function execute_scenario {
    while true; do
        execute_scenario_once $1 $2 $3 $4 $5
        finished=`grep "score_composed" ${BASE_DIR}/logs_town_$1_route_$2_timely_$3_perfect_perception_run_$4/results.json`
        if [[ ! -z "$finished" ]] ; then
            break
        fi
        echo "Deleting incomplete experiment"
        # Deleting the incomplete logs.
        rm -r ${BASE_DIR}/logs_town_$1_route_$2_timely_$3_perfect_perception_run_$4/
    done
}

function execute_scenario_once {
    # $1 town
    # $2 route
    # $3 timely
    # $4 number of repetitions
    # $5 frame rate
    export RECORD_PATH=${BASE_DIR}/logs_town_$1_route_$2_timely_$3_perfect_perception_run_$4/
    if [ -d "${RECORD_PATH}" ]; then
        echo "Experiment already executed"
        return
    fi
    mkdir ${RECORD_PATH}
    export CHECKPOINT_ENDPOINT=${RECORD_PATH}/results.json
    export TEAM_CONFIG=${LEADERBOARD_ROOT}/pylot_${SIMULATOR_PORT}.conf
    cp ${LEADERBOARD_ROOT}/pylot_perfect_perception.conf ${LEADERBOARD_ROOT}/pylot_${SIMULATOR_PORT}.conf
    echo "--log_file_name=${RECORD_PATH}/challenge.log" >> ${LEADERBOARD_ROOT}/pylot_${SIMULATOR_PORT}.conf
    echo "--csv_log_file_name=${RECORD_PATH}/challenge.csv" >> ${LEADERBOARD_ROOT}/pylot_${SIMULATOR_PORT}.conf
    echo "--profile_file_name=${RECORD_PATH}/challenge.json" >> ${LEADERBOARD_ROOT}/pylot_${SIMULATOR_PORT}.conf
    echo "--simulator_port=${SIMULATOR_PORT}" >> ${LEADERBOARD_ROOT}/pylot_${SIMULATOR_PORT}.conf

    execute_carla_and_pylot $5 ${SIMULATOR_PORT} ${TRAFFIC_MANAGER_PORT}

    export LOG_FILE=${RECORD_PATH}/challenge.log
    block_until_one_finishes $LOG_FILE

    PROC_OWNER=`whoami`
    pkill -9 -f -u $PROC_OWNER "\-\-port=${SIMULATOR_PORT}"
    # Kill the simulator.
    pkill -9 -f -u $PROC_OWNER world-port=${SIMULATOR_PORT}
}

for (( rep=1; rep <= ${num_rep}; rep++ )); do
    for (( route=${MIN_ROUTE}; route <= ${MAX_ROUTE}; route++ )); do
        export ROUTES=${LEADERBOARD_ROOT}/data/town_${TOWN}_route_${route}.xml
        for timely in ${timely_setup[@]}; do
            echo "[x] Running in $route of $TOWN"
            execute_scenario $TOWN $route $timely $rep $frame_rate
        done
    done
done
