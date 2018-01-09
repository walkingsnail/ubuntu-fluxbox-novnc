#!/bin/bash

[[ $EUID -ne 0 ]] && echo "Error: This script must be run as root!" && exit 1

########## START OF CONFIG ##########

# Directory to store backups
LOCALDIR="/vnpy/backups/"

# Temporary directory used during backup creation
TEMPDIR="/root/backups/temp/"

# File to log the outcome of backups
LOGFILE="/root/backups/backup.log"

# Below is a list of files and directories that will be backed up in the tar backup
# For example:
# File: /data/www/default/test.tgz
# Directory: /data/www/default/test
BACKUP[0]="/data/db/"

# Number of days to store daily local backups (default 7 days)
LOCALAGEDAILIES="21"

########## END OF CONFIG ##########


# Date & Time
DAY=$(date +%d)
MONTH=$(date +%m)
YEAR=$(date +%C%y)
BACKUPDATE=$(date +%Y%m%d%H%M%S)
# Backup file name
TARFILE="${LOCALDIR}""$(hostname)"_"${BACKUPDATE}".tgz

log() {
    echo -e "$(date "+%Y-%m-%d %H:%M:%S")" "$1" >> ${LOGFILE}
}

# Check for list of mandatory binaries
check_commands() {
    # This section checks for all of the binaries used in the backup
    BINARIES=( cat cd du date dirname echo pwd rm tar )
    
    # Iterate over the list of binaries, and if one isn't found, abort
    for BINARY in "${BINARIES[@]}"; do
        if [ ! "$(command -v "$BINARY")" ]; then
            log "$BINARY is not installed. Install it and try again"
            exit 1
        fi
    done
}

calculate_size() {
    local file_name=$1
    local file_size=$(du -h $file_name 2>/dev/null | awk '{print $1}')
    if [ "x${file_size}" = "x" ]; then
        echo "unknown"
    else
        echo "${file_size}"
    fi
}

start_backup() {
    [ "${BACKUP[*]}" == "" ] && echo "Error: You must to modify the [$(basename $0)] config before run it!" && exit 1

    log "Tar backup file start"
    tar -zcPf ${TARFILE} ${BACKUP[*]}
    if [ $? -gt 1 ]; then
        log "Tar backup file failed"
        exit 1
    fi
    log "Tar backup file completed"
    log "File name: ${OUT_FILE}, File size: `calculate_size ${OUT_FILE}`"
}

# Get file date
get_file_date() {
    #Approximate a 30-day month and 365-day year
    DAYS=$(( $((10#${YEAR}*365)) + $((10#${MONTH}*30)) + $((10#${DAY})) ))

    unset FILEYEAR FILEMONTH FILEDAY FILEDAYS FILEAGE
    FILEYEAR=$(echo "$1" | cut -d_ -f2 | cut -c 1-4)
    FILEMONTH=$(echo "$1" | cut -d_ -f2 | cut -c 5-6)
    FILEDAY=$(echo "$1" | cut -d_ -f2 | cut -c 7-8)

    if [[ "${FILEYEAR}" && "${FILEMONTH}" && "${FILEDAY}" ]]; then
        #Approximate a 30-day month and 365-day year
        FILEDAYS=$(( $((10#${FILEYEAR}*365)) + $((10#${FILEMONTH}*30)) + $((10#${FILEDAY})) ))
        FILEAGE=$(( 10#${DAYS} - 10#${FILEDAYS} ))
        return 0
    fi

    return 1
}

# Clean up old file
clean_up_files() {
    cd ${LOCALDIR} || exit

    for f in ${LS[@]}
    do
        get_file_date ${f}
        if [ $? == 0 ]; then
            if [[ ${FILEAGE} -gt ${LOCALAGEDAILIES} ]]; then
                rm -f ${f}
                log "Old backup file name: ${f} has been deleted"
                delete_gdrive_file ${f}
                delete_ftp_file ${f}
            fi
        fi
    done
}

# Main progress
STARTTIME=$(date +%s)

# Check if the backup folders exist and are writeable
if [ ! -d "${LOCALDIR}" ]; then
    mkdir -p ${LOCALDIR}
fi
if [ ! -d "${TEMPDIR}" ]; then
    mkdir -p ${TEMPDIR}
fi

log "Backup progress start"
check_commands
start_backup
log "Backup progress complete"
clean_up_files

ENDTIME=$(date +%s)
DURATION=$((ENDTIME - STARTTIME))
log "All done"
log "Backup and transfer completed in ${DURATION} seconds"