#!/bin/bash

# Assign rules change here to change the rules
declare -A rules
rules=([3]=Fizz [5]=Buzz)

# Run this 100 times
for i in {1..100}
do
	unset output
	for key in ${!rules[@]}
	do
	
		if ! ((i % $key))
		then
    			output="${rules[$key]}$output"
		fi
	done
	if [ -z $output ]
	then
		output=$i
	fi
	echo $output
done
