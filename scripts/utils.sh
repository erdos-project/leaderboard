# Assumes that $CARLA_HOME AND $PYLOT_HOME are set.
if [ -z "$PYLOT_HOME" ]; then
    echo "Please set \$PYLOT_HOME before sourcing this script"
    exit 1
fi

if [ -z "$CARLA_HOME" ]; then
    echo "Please set \$CARLA_HOME before running this script"
    exit 1
fi

BASE_DIR=`pwd`
export CARLA_ROOT=${CARLA_HOME}
export SCENARIO_RUNNER_ROOT=$BASE_DIR/scenario_runner/
export LEADERBOARD_ROOT=$BASE_DIR/leaderboard/
export PYTHONPATH="${CARLA_ROOT}/PythonAPI/carla/":"${SCENARIO_RUNNER_ROOT}":"${LEADERBOARD_ROOT}":${PYTHONPATH}:${PYLOT_HOME}

export SCENARIOS=${LEADERBOARD_ROOT}/data/all_towns_traffic_scenarios_public.json
export REPETITIONS=1
export DEBUG_CHALLENGE=0
export TEAM_AGENT=${PYLOT_HOME}/pylot/simulation/challenge/ERDOSAgent.py
export RESUME=1
export CHALLENGE_TRACK_CODENAME=MAP

function block_until_one_finishes {
    PROC_OWNER=`whoami`
    old_log_size="-1"
    sleep 120
    while true; do
        scenario_running=`pgrep -f -u $PROC_OWNER leaderboard_eval`
        sim_running=`pgrep -f -u $PROC_OWNER CarlaUE4`
        if [ -z "${scenario_running}" ] ; then
            echo "Scenario not running anymore..."
            break
        fi
        if [ -z "${sim_running}" ] ; then
            echo "Simulator not running anymore..."
            break
        fi
        new_log_size=$(stat -c%s "$1")
        if [ "$old_log_size" = "$new_log_size" ] ; then
           echo "The leaderboard blocked..."
           break
        fi
        old_log_size=$new_log_size
        sleep 120
    done
}


function execute_carla_and_pylot {
    # $1 frame rate
    # $2 simulator port
    # $3 traffic manager port

    PORT=2000
    if [[ ! -z "$2" ]] ; then
        PORT=$2
    fi

    TRAFFIC_MANAGER_PORT=8000
    if [[ ! -z "$3" ]] ; then
        TRAFFIC_MANAGER_PORT=$3
    fi

    echo "[x] Starting the CARLA simulator on port ${PORT}"
    SDL_VIDEODRIVER=offscreen ${CARLA_HOME}/CarlaUE4.sh -opengl -windowed -ResX=800 -ResY=600 -carla-server -benchmark -fps=20 -quality-level=Epic -world-port=$PORT &
    sleep 10

    echo "[x] Starting the leaderboard"
    python3 ${LEADERBOARD_ROOT}/leaderboard/leaderboard_evaluator.py \
            --scenarios=${SCENARIOS}  \
            --routes=${ROUTES} \
            --repetitions=${REPETITIONS} \
            --track=${CHALLENGE_TRACK_CODENAME} \
            --checkpoint=${CHECKPOINT_ENDPOINT} \
            --agent=${TEAM_AGENT} \
            --agent-config=${TEAM_CONFIG} \
            --debug=${DEBUG_CHALLENGE} \
            --record=${RECORD_PATH} \
            --resume=${RESUME} \
            --timeout=360 \
	    --frame-rate=$1 \
            --port=${PORT} \
            --trafficManagerPort=${TRAFFIC_MANAGER_PORT} &
}
