#!/bin/bash

#######################################
# Base script for a progress bar
# Globals:
#   None
# Arguments:
#   None
# Outputs:
#   A live progress bar while iterating over **/*cache files/folders
#######################################

progress-bar()
{
	local current=$1
	local len=$2

	local bar_char='x'
	local empty_char=' '
	local length=50
	local perc_done=$((current * 100 / len))
	local num_bars=$((perc_done * length / 100))

	local i
	local s='['
	for ((i = 0; i < num_bars; i++)); do
		s+=$bar_char
	done
	for ((i = num_bars; i < length; i++)); do
		s+=$empty_char
	done
	s+=']'

	echo -ne "$s $current/$len ($perc_done%)\r"
}

process-files()
{
	local file=$1
	sleep .01
}

shopt -s globstar nullglob

echo "Finding files"
files=(./**/*cache)
len=${#files[@]}
echo "Found $len files"

i=0
for file in "${files[@]}"; do
	progress-bar "$((i+1))" "$len"
	process-files "$file"

	((i++))
done

echo
