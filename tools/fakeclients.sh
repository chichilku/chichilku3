#!/bin/bash

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
NUM_CLIENTS="${1:-16}"
IP="${2:-localhost}"
PORT="${3:-9900}"

if [ "$1" == "--help" ] || [ "$1" == "-h" ]
then
    echo "usage: $(basename "$0") [NUM_CLIENTS=16] [IP=localhost] [PORT=9900]"
    exit 0
fi

for ((i=0;i<NUM_CLIENTS;i++))
do
    nc "$IP" "$PORT" < <(printf '%s%s' "$ID_REQUEST" "$NAME_REQUEST") &
done

read -r
pkill -f 'nc localhost 990'

