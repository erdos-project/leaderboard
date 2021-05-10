#!/bin/bash

# Assumes that $CARLA_HOME AND $PYLOT_HOME are set.
source leaderboard/scripts/utils.sh

function execute_scenario {
    while true; do
        execute_scenario_once $1 $2 $3 $4
        finished=`grep "score_composed" ${BASE_DIR}/logs_town_$1_route_$2_detection_deadline_$3_run_$4/results.json`
        if [[ ! -z "$finished" ]] ; then
            break
        fi
        echo "Deleting incomplete experiment"
        # Deleting the incomplete logs.
        rm -r ${BASE_DIR}/logs_town_$1_route_$2_detection_deadline_$3_run_$4/
    done
}

function execute_scenario_once {
    # $1 town
    # $2 route
    # $3 deadline
    # $4 number of repetitions
    export RECORD_PATH=${BASE_DIR}/logs_town_$1_route_$2_detection_deadline_$3_run_$4/
    if [ -d "${RECORD_PATH}" ]; then
        echo "Experiment already executed"
        return
    fi
    mkdir ${RECORD_PATH}
    export CHECKPOINT_ENDPOINT=${RECORD_PATH}/results.json
    export TEAM_CONFIG=${LEADERBOARD_ROOT}/pylot.conf
    cp ${LEADERBOARD_ROOT}/pylot_base.conf ${LEADERBOARD_ROOT}/pylot.conf
    echo "--path_coco_labels=${PYLOT_HOME}/dependencies/models/coco.names" >> ${LEADERBOARD_ROOT}/pylot.conf
    echo "--traffic_light_det_model_path=${PYLOT_HOME}/dependencies/models/traffic_light_detection/faster-rcnn/frozen_inference_graph.pb" >> ${LEADERBOARD_ROOT}/pylot.conf
    echo "--obstacle_detection_model_paths=${PYLOT_HOME}/dependencies/models/obstacle_detection/efficientdet/efficientdet-d1/efficientdet-d1_frozen.pb,${PYLOT_HOME}/dependencies/models/obstacle_detection/efficientdet/efficientdet-d2/efficientdet-d2_frozen.pb,${PYLOT_HOME}/dependencies/models/obstacle_detection/efficientdet/efficientdet-d3/efficientdet-d3_frozen.pb,${PYLOT_HOME}/dependencies/models/obstacle_detection/efficientdet/efficientdet-d4/efficientdet-d4_frozen.pb,${PYLOT_HOME}/dependencies/models/obstacle_detection/efficientdet/efficientdet-d5/efficientdet-d5_frozen.pb,${PYLOT_HOME}/dependencies/models/obstacle_detection/efficientdet/efficientdet-d6/efficientdet-d6_frozen.pb,${PYLOT_HOME}/dependencies/models/obstacle_detection/efficientdet/efficientdet-d7/efficientdet-d7_frozen.pb" >> ${LEADERBOARD_ROOT}/pylot.conf
    echo "--obstacle_detection_model_names=efficientdet-d1,efficientdet-d2,efficientdet-d3,efficientdet-d4,efficientdet-d5,efficientdet-d6,efficientdet-d7" >> ${LEADERBOARD_ROOT}/pylot.conf
    echo "--log_file_name=${RECORD_PATH}/challenge.log" >> ${LEADERBOARD_ROOT}/pylot.conf
    echo "--csv_log_file_name=${RECORD_PATH}/challenge.csv" >> ${LEADERBOARD_ROOT}/pylot.conf
    echo "--profile_file_name=${RECORD_PATH}/challenge.json" >> ${LEADERBOARD_ROOT}/pylot.conf
    echo "--deadline_enforcement=static" >> ${LEADERBOARD_ROOT}/pylot.conf
    echo "--detection_deadline=$3" >> ${LEADERBOARD_ROOT}/pylot.conf

    execute_carla_and_pylot 20

    export LOG_FILE=${RECORD_PATH}/challenge.log
    block_until_one_finishes $LOG_FILE

    PROC_OWNER=`whoami`
    pkill -9 -f -u $PROC_OWNER leaderboard_eval
    # Kill the simulator.
    pkill -9 -f -u $PROC_OWNER CarlaUE4
}


towns=(1)
routes=(2)
timely_setup=(False)
deadlines=(55 60 80 110 160 200 280 240 130 100 90 70)
num_rep=3

for town in ${towns[@]}; do
    for route in ${routes[@]}; do
        export ROUTES=${LEADERBOARD_ROOT}/data/town_${town}_route_${route}.xml
        for deadline in ${deadlines[@]}; do
            echo "[x] Running with deadline $deadline"
            for (( rep=1; rep <= ${num_rep}; rep++ )); do
                execute_scenario $town $route $deadline $rep
            done
        done
    done
done
