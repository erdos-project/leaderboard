#!/bin/bash

# Assumes that $CARLA_HOME AND $PYLOT_HOME are set.
source leaderboard/scripts/utils.sh

function execute_scenario {
    while true; do
        execute_scenario_once $1 $2 $3 $4 $5 $6
        finished=`grep "score_composed" ${BASE_DIR}/logs_deadlines_town_$1_route_$2_timely_$3_edet_$4_run_$5/results.json`
        if [[ ! -z "$finished" ]] ; then
            break
        fi
        echo "Deleting incomplete experiment"
        # Deleting the incomplete logs.
        rm -r ${BASE_DIR}/logs_deadlines_town_$1_route_$2_timely_$3_edet_$4_run_$5/
    done
}

function execute_scenario_once {
    # $1 town
    # $2 route
    # $3 timely
    # $4 detector
    # $5 number of repetitions
    # $6 frame rate
    export RECORD_PATH=${BASE_DIR}/logs_deadlines_town_$1_route_$2_timely_$3_edet_$4_run_$5/
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
    echo "--deadline_enforcement=static" >> ${LEADERBOARD_ROOT}/pylot.conf
    echo "--detection_deadline=${DETECTION_DEADLINE}" >> ${LEADERBOARD_ROOT}/pylot.conf
    echo "--tracking_deadline=${TRACKING_DEADLINE}" >> ${LEADERBOARD_ROOT}/pylot.conf
    echo "--location_finder_deadline=${LOCATION_FINDER_DEADLINE}" >> ${LEADERBOARD_ROOT}/pylot.conf
    echo "--prediction_deadline=${PREDICTION_DEADLINE}" >> ${LEADERBOARD_ROOT}/pylot.conf
    echo "--planning_deadline=${PLANNING_DEADLINE}" >> ${LEADERBOARD_ROOT}/pylot.conf        
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

town=$1
route=$2
export ROUTES=${LEADERBOARD_ROOT}/data/town_${town}_route_${route}.xml
timely=$3
detector=$4
num_rep=$5
frame_rate=$6

if [ "$7" = ec2 ] ; then
    echo "Using EC2 99th percentile deadlines"
    export TRACKING_DEADLINE=15
    export LOCATION_FINDER_DEADLINE=80
    export PREDICTION_DEADLINE=25
    export PLANNING_DEADLINE=100
    if [ "$detector" -eq 1 ] ; then
        export DETECTION_DEADLINE=56
    fi
    if [ "$detector" -eq 4 ] ; then
        export DETECTION_DEADLINE=98
    fi
    if [ "$detector" -eq 7 ] ; then
        export DETECTION_DEADLINE=238
    fi
fi

if [ "$7" = dedicated ] ; then
    echo "Using deadicated 99.9th percentile deadlines"
    export TRACKING_DEADLINE=15
    export LOCATION_FINDER_DEADLINE=54
    export PREDICTION_DEADLINE=25
    export PLANNING_DEADLINE=65
    if [ "$detector" -eq 1 ] ; then
        export DETECTION_DEADLINE=60
    fi
    if [ "$detector" -eq 4 ] ; then
        export DETECTION_DEADLINE=110
    fi
    if [ "$detector" -eq 7 ] ; then
        export DETECTION_DEADLINE=274
    fi
fi
echo "[x] Running with EfficientDet D$detector with deadline ${DETECTION_DEADLINE}"

for (( rep=1; rep <= ${num_rep}; rep++ )); do
    execute_scenario $town $route $timely $detector $rep $frame_rate
done
