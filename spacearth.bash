#! /usr/bin/env bash
##
## spacearth.bash
## by lenormf
##

## Dependencies: feh wget
## Optional dependency: imagesmagick

AVAILABLE_SIZES=(144 160 200 240 256 270 288 320 400 480 512 576 640 720 800 912 1024 1152 1280 1440 1600)
## Choose from one of the sizes above
SIZE=1440

## Update every 5 minutes
UPDATE=5

## Directory in which the background will be downloaded and modified
TMP_DIR=/tmp

## The downloaded satellite view will be saved as ${FILE_PREFIX}${TIMESTAMP}.jpg
FILE_PREFIX=earth_

## The pid of a running instance of this script will be stored in that file, in TMP_DIR
PID_FILE=spacearth.pid

function fatal {
	echo "$@" >&2 && exit 1
}

function usage {
	echo "Usage: $0" \
		"[-w <image width>] (default: $SIZE)" \
		"[-u <update rate (seconds)> (default: $UPDATE)]" \
		"[-d <temporary directory> (default: $TMP_DIR)]" \
		"[-p <file prefix> (default: $FILE_PREFIX)]" \
		"[-f <pid filename> (default: $PID_FILE)]"
	exit 0
}

function main {
	while true; do
		test -d "$TMP_DIR" || fatal "No such directory: $TMP_DIR"

		local D=$(date '+%s')
		local DST="${TMP_DIR}/${FILE_PREFIX}${D}.jpg"
		local U="http://static.die.net/earth/mercator-cloudless/${SIZE}.jpg"

		## The site filters user agents, and only lets "real browsers" download the pictures
		wget -o /tmp/log --user-agent='Mozilla/5.0 (X11; Linux x86_64; rv:18.0) Gecko/20100101 Firefox/18.0' -O "$DST" "$U"

		## Sharpen the image a bit, if possible
		test ! -z "$(which convert)" \
			&& convert "$DST" -sharpen 0x1.0 "${DST}.out" \
			&& mv "${DST}.out" "$DST"
		feh --bg-scale "$DST"

		rm -f "$DST"

		sleep $((UPDATE * 60))
	done
}

function kill_old {
	local PIDF="${TMP_DIR}/${PID_FILE}"

	test -f "${PIDF}" && kill -9 "$(cat ${PIDF} )" 2>/dev/null
	echo $$ > "$PIDF"
}

function set_options {
	while getopts ':hw:u:d:p:f:' opt; do
		case "$opt" in
			h)
				usage
				;;
			w)
				echo "$OPTARG" | egrep -qo '^[0-9]+$' || fatal "Provided argument $OPTARG is not an number"

				local sz=''
				for i in "${AVAILABLE_SIZES[@]}"; do
					test $i -eq "$OPTARG" && sz=$i && break
				done
				test -z "$sz" && fatal "Unavailable width $OPTARG (choose from the following values: ${AVAILABLE_SIZES[@]})"
				SIZE="$sz"
				;;
			u)
				echo "$OPTARG" | egrep -qo '^[0-9]+$' || fatal "Provided argument $OPTARG is not an number"
				UPDATE="$OPTARG"
				;;
			d)
				test -d "$OPTARG" || mkdir -p "$OPTARG" 2>/dev/null
				TMP_DIR="$OPTARG"
				;;
			p)
				FILE_PREFIX="$OPTARG"
				;;
			f)
				PID_FILE="$OPTARG"
				;;
			*)
				fatal "Invalid option $opt"
				;;
		esac
	done
}

set_options "$@"
kill_old
main

rm -f "${TMP_DIR}/${PID_FILE}"
