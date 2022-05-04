#!/bin/bash

function connect_client() {
	sleep 2
	./tools/fakeclients.sh --shutdown > /dev/null
}

connect_client &>/dev/null &

ruby lib/server/chichilku3_server.rb || exit 1

