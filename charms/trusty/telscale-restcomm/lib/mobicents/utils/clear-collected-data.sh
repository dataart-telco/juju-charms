#!/bin/sh
#
# Description: Clears data, logs and traces collected by collect-data service.
# Author: Henrique Rosa

# VARIABLES
SAVE_DIR=$TELSCALE_ANALYTICS/log/system
FILE_LIMIT=3

## Description: Counts the number of files in a directory
## Parameters : 
##				1.The directory to inspect
countFiles() {
	find $1 -maxdepth 1 -mindepth 1 -type f | wc -l
}

## Description: Finds the N oldest files in a directory
## Parameters : 1. The directory to inspect
##				2. The number of files to be retrieved
findOldest() {
        find $1 -maxdepth 1 -mindepth 1 -type f -printf '%T+ %p\n' 2>/dev/null | sort -k 1nr | head -n $2 | awk '{print $2}'
}

# MAIN
FILE_COUNT=`countFiles $SAVE_DIR`
THRESHOLD=$((FILE_COUNT-FILE_LIMIT))

if [ $THRESHOLD > 0 ]; then
	echo 'Started cleaning collected data'
	echo "File Count: $FILE_COUNT"
	echo "File Limit: $FILE_LIMIT"
	echo "Deleting $THRESHOLD files..."
    findOldest $SAVE_DIR $THRESHOLD | while read file; do
		rm -f $file
		echo "Erased $file"
	done
	echo 'Finished erasing collected data'
fi