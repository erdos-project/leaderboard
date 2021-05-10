#!/bin/bash

# $1 town
# $2 port
# $3 traffic manager port

export CARLA_ROOT=${CARLA_HOME}
export SCENARIO_RUNNER_ROOT=/home/ionel/code/challenge/scenario_runner/
export LEADERBOARD_ROOT=/home/ionel/code/challenge/leaderboard/
export PYTHONPATH="${CARLA_ROOT}/PythonAPI/carla/":"${SCENARIO_RUNNER_ROOT}":"${LEADERBOARD_ROOT}":${PYTHONPATH}:${PYLOT_HOME}

export SCENARIOS=${LEADERBOARD_ROOT}/data/all_towns_traffic_scenarios_public.json
export ROUTES=${LEADERBOARD_ROOT}/data/routes_town$1.xml
export REPETITIONS=1
export DEBUG_CHALLENGE=0
export TEAM_AGENT=${PYLOT_HOME}/pylot/simulation/challenge/ERDOSAgent.py
export TEAM_CONFIG=${PYLOT_HOME}/pylot/simulation/challenge/challenge_town$1.conf
#export TEAM_AGENT=${LEADERBOARD_ROOT}/leaderboard/autoagents/human_agent.py
export CHECKPOINT_ENDPOINT=${LEADERBOARD_ROOT}/results_town$1.json
export RECORD_PATH=/home/ionel/code/challenge/logs/
export RESUME=1
export CHALLENGE_TRACK_CODENAME=MAP
export PORT=$2
export TRAFFIC_MANAGER_PORT=$3

python ${LEADERBOARD_ROOT}/leaderboard/leaderboard_evaluator.py \
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
--timeout=120 \
--port=${PORT} \
--trafficManagerPort=${TRAFFIC_MANAGER_PORT}
