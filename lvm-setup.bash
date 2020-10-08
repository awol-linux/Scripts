#/bin/env bash
# 
# enable for debugging
# set -x
#

##########################################################
#
# This code is split into four sections
# Section 1 is where i declare functions
# Section 2 is for assigning physical volumes
# Section 3 is for creating volumes groups
# Section 4 is for creating logical volumes
#
###########################################################


# Check for root privelidge

if [ "$EUID" -ne 0 ]
  then echo "This script requires root permission in order to run."
  exit
fi


# 
# section 1
#

# Add functions used throught this script
# 

# Add a yes or no function

fn() {
	while true; do
		case $input in
			[yY][eE][sS]|[yY])
				output=true
				break
				;;
			[nN][oO]|[nN])
				output=false
				break
		       		;;
			*)
				echo "Invalid input..."
				unset input
				read input
				;;
		esac
	done
}

#
# Section 2 for Assigning Physical Volumes
#

# Asign physical volumes 
# you can skip this if 
# you have done this already

# Create array for physical volumes yet to be assigned

declare -a pvcandidates

# Enter device path loop until done

while true ; do
	echo "Please enter physical device path or press ENTER to skip"
	echo "The following partitions are available" 
	echo " "

	#
	# section 2a 
	# List available devices
	#
	
	# Check if any physical volumes have been assigned
	
	if [[ -n ${pvcandidates[*]} ]];then 
		
		# If there are candidates echo available partitions and remove any candidates.

		echo "$(lsblk -o name,type,fstype,size \
			| awk -F'-' '/part\s{2}/ {$1="" ;printf "/dev/"; print $2}')" \
			| grep -vI $(printf '%s\n' "${pvcandidates[@]}")
	
	else
	
		# If there aren-t candidates echo available partitions disks.
	
		echo "$(lsblk -o name,type,fstype,size \
			| awk -F'-' '/part\s{2}/ {$1="";printf "/dev/"; print $2}')"
	fi
	
	#
	# section 2b
	# handle physical volume input
	#
	
	read pvinput
	
	# if blank line entered then exit loop 

	if [[ -z $pvinput ]]; then
	       	echo "No input given not assigning any new partitions" 
		break
	
	# verify disk is valid if there is input

# disabled for debugging

#	elif [[ ! $(sudo fdisk -l | awk '/^\/dev/ {print $1}' | egrep  "^$pvinput"$) ]]; then 
#		echo $pvinput not a valid partion
	
	# verify partition not already entered
	
	elif [[ $(printf '%s\n' "${pvcandidates[@]}" | grep -w -P "$pvinput") ]]; then
		echo "$pvinput already enterd"
	
	# Since we validated the partition now add partition to array
	
	else	
		pvcandidates+=($pvinput) 
		echo -e "partition $pvinput valid \n ${pvcandidates[@]} \n would you like to enter anther partition"
		read input
		fn input 
		if [[ $output == false ]]; then
			break
		fi
	fi
done


# Show Physical Volume To confirm action was done

echo "pelase verify that the following partition table is accurate"
pvs


#
# Section 3
#


# assign volume group
# If you added a physical volume 
# then assume you want to use it  



# check if somthing was entered
#if [[ -z $vgname ]]; then
while true; do
	
	# Ask for volume group name
	
	echo "Enter volume group name or press enter to pick a existing volume group"
	read vgname
	
	# check if input is blank
	
	if [[ -z $vgname ]]; then
		echo -e "No input found not creating a new volume group \n which volume group do you want to use \n$(vgs | awk 'NR>1 {print}')"
						
	# If there is input and it does exist
			
	elif [[ $(vgs | awk 'NR>1 { print $1 }') = $vgname ]]; then
		echo $vgname\ selected
		break
	
	# If there is input and it doesnt exists
	
	else
		echo "$vgname does not exist would you like to make it?"
		read input
		fn input
		if [[ $output == true ]] ;then
			break
		fi
	fi
done

echo $vgname

# If you entered a volume ask if you want to use it
#
#
# This doesnt work
#
#
#
#

if [[ -n ${pvcandidates[1]} ]];then 
	echo "Do you want to create $vgname using input ${pvcandidates[@]}"
	fn input
	if [[ $output == true ]]; then
		physicalvolumes=("${pvcandidates[@]}")
		echo "${physicalvolumes[@]}"
	fi

# If you didnt enter a input

else
	echo "please enter a physical volume to use (1 at a time)"
	read output
fi

# Add another input loop until finished
while true; do
	echo "would you like to add another physical volume"
	read input
	fn $input
	if [[ $output == true ]]; then
		echo -e "Please enter disk names \n `pvs`"
		read pvnames
		
		# if device entered is a valid physical volume
		#
		#
		# add a step to a verify input not enterd twice
		# the same as earler
		#
		#
		
		if [[ $(sudo pvs | grep "$pvnames" ) ]] ; then
			echo "$pvnames is valid and will be used"

		# if device entered is not a valid pv

		elif
			
		# Verify device not entered

		else 
			echo "Device $pvnames is not valid"
		fi
	
	else
		break
	fi
done

#
# Section 4
#

# 
