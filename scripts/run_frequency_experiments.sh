#!/bin/bash

# Assumes that $CARLA_HOME AND $PYLOT_HOME are set.
source leaderboard/scripts/utils.sh

function execute_scenario {
    while true; do
        execute_scenario_once $1 $2 $3 $4 $5 $6
        finished=`grep "score_composed" ${BASE_DIR}/logs_frequency_town_$1_route_$2_timely_$3_edet_$4_run_$5/results.json`
        if [[ ! -z "$finished" ]] ; then
            break
        fi
        echo "Deleting incomplete experiment"
        # Deleting the incomplete logs.
        rm -r ${BASE_DIR}/logs_frequency_town_$1_route_$2_timely_$3_edet_$4_run_$5/
    done
}

function execute_scenario_once {
    # $1 town
    # $2 route
    # $3 timely
    # $4 detector
    # $5 number of repetitions
    # $6 frame rate
    export RECORD_PATH=${BASE_DIR}/logs_frequency_town_$1_route_$2_timely_$3_edet_$4_run_$5/
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
    echo "--obstacle_detection_model_paths=${PYLOT_HOME}/dependencies/models/obstacle_detection/efficientdet/efficientdet-d$4/efficientdet-d$4_frozen.pb" >> ${LEADERBOARD_ROOT}/pylot.conf
    echo "--obstacle_detection_model_names=efficientdet-d$4" >> ${LEADERBOARD_ROOT}/pylot.conf
    echo "--log_file_name=${RECORD_PATH}/challenge.log" >> ${LEADERBOARD_ROOT}/pylot.conf
    echo "--csv_log_file_name=${RECORD_PATH}/challenge.csv" >> ${LEADERBOARD_ROOT}/pylot.conf
    echo "--profile_file_name=${RECORD_PATH}/challenge.json" >> ${LEADERBOARD_ROOT}/pylot.conf

    execute_carla_and_pylot $6

    export LOG_FILE=${RECORD_PATH}/challenge.log
    block_until_one_finishes $LOG_FILE

    PROC_OWNER=`whoami`
    pkill -9 -f -u $PROC_OWNER leaderboard_eval
    # Kill the simulator.
    pkill -9 -f -u $PROC_OWNER CarlaUE4
}

towns=(1)
routes=(1 2 3 4 5 6 7 8 9)
timely_setup=(True)
detectors=(4)
num_rep=7
frame_rate=40

for town in ${towns[@]}; do
    for (( rep=1; rep <= ${num_rep}; rep++ )); do
	for route in ${routes[@]}; do
            export ROUTES=${LEADERBOARD_ROOT}/data/town_${town}_route_${route}.xml
            for timely in ${timely_setup[@]}; do
		for detector in ${detectors[@]}; do
                    echo "[x] Running with EfficientDet D$detector"
                    execute_scenario $town $route $timely $detector $rep $frame_rate
                done
            done
        done
    done
done
