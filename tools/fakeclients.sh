#!/bin/bash

is_flood=0
is_shutdown=0

if [ "$1" == "--help" ] || [ "$1" == "-h" ]
then
	echo "usage: $(basename "$0") [OPTIONS] [NUM_CLIENTS=16] [IP=localhost] [PORT=9900]"
	echo "options:"
	echo "  --flood     reconnect 1 client constantly"
	echo "  --shutdown  connect 1 client to server and run 'exit' command"
	exit 0
elif [ "$1" == "--shutdown" ]
then
	is_shutdown=1
	shift
elif [ "$1" == "--flood" ]
then
	is_flood=1
	shift
fi

root=chichilku3
function check_root() {
	if [ -f "$root/lib/share/network.rb" ]
	then
		return 1
	fi
	if [ "${#root}" -gt "128" ]
	then
		echo "[-] Error: lib/share/network.rb not found"
		echo "[-] script has to be run from inside the repo"
		exit 1
	fi
	root="../$root"
	return 0
}

while check_root; do test; done

GAME_VERSION="$(grep 'GAME_VERSION = ' "$root/lib/share/network.rb" | cut -d"'" -f2)"
ID_REQUEST="1l${GAME_VERSION}XXXXX"
NAME_REQUEST='3lfoobar '
EXIT_CMD='4l1exit    '
NUM_CLIENTS="${1:-16}"
IP="${2:-localhost}"
PORT="${3:-9900}"

if [ "$is_flood" == "1" ]
then
	while true
	do
		nc "$IP" "$PORT" -q 1 < <(printf '%s%s' "$ID_REQUEST" "$NAME_REQUEST") || exit
	done
elif [ "$is_shutdown" == "1" ]
then
	nc "$IP" "$PORT" < <(printf '%s%s' "$ID_REQUEST" "$EXIT_CMD") &
else
	for ((i=0;i<NUM_CLIENTS;i++))
	do
		nc "$IP" "$PORT" < <(printf '%s%s' "$ID_REQUEST" "$NAME_REQUEST") &
	done

	read -r
	pkill -f 'nc localhost 990'
fi

