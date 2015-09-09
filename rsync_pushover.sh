#!/usr/bin/env bash

# ----------------------------------------------------------------------------------------
# Title		: rsync_pushover.sh
# Author	: Steve Calvário
# Date		: 2015-09-09
# Version	: 1.0
# Github	: https://github.com/Calvario/rsync_pushover/
# ----------------------------------------------------------------------------------------


# ----------------------------------------------------------------------------------------
# Copyright (c) 2015 Steve Calvrio <https://github.com/Calvario/>
#
# This program is free software: you can redistribute it and/or modify it
# under the terms of the GNU General Public License as published by the
# Free Software Foundation, either version 3 of the License, or (at your
# option) any later version.  Please see LICENSE.txt at the top level of
# the source code distribution for details.

# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.

# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>
# ----------------------------------------------------------------------------------------


# ----------------------------------------------------------------------------------------
# You must edit the following variables to match with your production environment
# ----------------------------------------------------------------------------------------

rsync_src='/mysrc'
rsync_dst='account@myip:/mydest/'
rsync_exclude="/myfolder/rsync_pushover_exclude.conf"
rsync_options="-avRzh --delete --exclude-from=$rsync_exclude"

pushover_token='XXXXXXXXXXXXXXX'
pushover_user='XXXXXXXXXXXXXXXX'
pushover_title='Remote Synchronization : device'

script_log='/myfolder/rsync_pushover.log'

# ----------------------------------------------------------------------------------------


# ----------------------------------------------------------------------------------------
# !!! Do not change the lines below !!!
# ----------------------------------------------------------------------------------------


# ----------------------------------------------------------------------------------------
# Check script requirement
# ----------------------------------------------------------------------------------------

if ! type curl > /dev/null
then
	error="curl is required to use this script, please install it."
	echo $error
	
	echo "$(date '+%Y-%m-%d %H:%M:%S') - Error : $error" >> $script_log
	exit 1
elif ! type rsync > /dev/null
then
	error="rsync is required to use this script, please install it."
	echo $error
	
	echo "$(date '+%Y-%m-%d %H:%M:%S') - Error : $error" >> $script_log
	exit 1
elif ! type flock > /dev/null
then
	error="flock is required to use this script, please install it."
	echo $error
	
	echo "$(date '+%Y-%m-%d %H:%M:%S') - Error : $error" >> $script_log
	exit 1
fi

# ----------------------------------------------------------------------------------------


# ----------------------------------------------------------------------------------------
# Create lock file 
# ----------------------------------------------------------------------------------------

set -e

script_name=$(basename $0)
script_lock="/var/run/$script_name" 

exec 200>$script_lock
flock -n 200 || exit 1

script_pid=$$
echo $script_pid 1>&200

# ----------------------------------------------------------------------------------------


# ----------------------------------------------------------------------------------------
# Functions
# ----------------------------------------------------------------------------------------

func_rsync() {

	script_start=$(date '+%Y-%m-%d %H:%M:%S')
	script_start_s=$(date +%s)
	
	echo "Remote Synchronization started !"
	echo "Start at : $script_start"
	echo "PID : $4"
	echo ""
	echo "---------------------------------------------------------"
	echo ""

	rsync $1 $2 $3
	
	script_end=$(date '+%Y-%m-%d %H:%M:%S')
	script_end_s=$(date +%s)
	script_runtime_s=$(expr $script_end_s - $script_start_s)
	
	echo ""
	echo "---------------------------------------------------------"
	echo ""
	echo "Completed at : $script_end"
	echo "Runtime : $script_runtime_s seconds"
	echo "Remote Synchronization completed !"

}

func_transport_pushover() {

    curl -s -F "token=$1" \
    -F "user=$2" \
    -F "title=$3" \
    -F "message=$4" https://api.pushover.net/1/messages.json

}

# ----------------------------------------------------------------------------------------


# ----------------------------------------------------------------------------------------
# Send Pushover notification
# ----------------------------------------------------------------------------------------

pushover_message=$(func_rsync "$rsync_options" "$rsync_src" "$rsync_dst" "$script_pid")

func_transport_pushover "$pushover_token" "$pushover_user" "$pushover_title" "$pushover_message"

# ----------------------------------------------------------------------------------------
