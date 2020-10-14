#/bin/env bash
# 
# enable for debugging
# set -x
#

##########################################################
#
# This code is split into four sections
# Section 1 is where I declare functions
# Section 2 is for assigning physical volumes
# Section 3 is for creating volumes groups
# Section 4 is for creating logical volumes
#
###########################################################


# Check for root privelidge

if [ "$EUID" -ne 0 ]; then
	echo "This script requires root permission in order to run."
	exit
fi


# 
# section 1
# Add functions used throught this script
#

# Add a yes or no function that loops until you answer

defyes() {
	while [ 1 == 1 ]; do
		case $input in
			[yY][eE][sS]|[yY]|"")
				return 0
				break
				;;
			[nN][oO]|[nN])
				return 1 
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
declare -a pvunassign

# Enter device path loop until done
while true; do
	echo "Please confirm the  partition table is good"
	pvs
	read input
		if defyes $input; then
			break
		else 
			read -p "would you like to add or remove a partition"$'\n' issue
			echo $issue
			while true; do
				case $issue in
					[Aa][Dd][Dd]|[Ad])
						loop=add
						break
						;;
					[Rr][Ee][Mm][Oo][Vv][Ee])
						loop=remove
						break
						;;
					*)
						read issue
						;;
				esac
			done
		fi


	if [[ $loop == add ]]; then
	
	
		#
		# section 2a 
		# List available devices
		#
	
		# Check if any physical volumes have been assigned
		
		echo -e "Please enter physical device path or press ENTER to skip \n The following partitions are available \n" 
	
		while true; do


			if [[ -n ${pvcandidates[*]} ]]; then 
		
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

			elif [[ ! $(sudo fdisk -l | awk '/^\/dev/ {print $1}' | egrep  "^$pvinput"$) ]]; then 
				echo $pvinput not a valid partion
	
			# verify partition not already entered
	
			elif [[ $(printf '%s\n' "${pvcandidates[@]}" | grep -w -P "$pvinput") ]]; then
				echo "$pvinput already enterd"
	
			# Since we validated the partition now add partition to array
	
			else	
				pvcandidates+=($pvinput) 
				echo -e "partition $pvinput valid \n ${pvcandidates[@]}"
		
			fi

			# Now add another partition

			read -p "would you like to add another partitioni (ENTER for yes)"$'\n' input
			defyes $input || break
		done

	fi
	if [[ -n ${pvcandidates[*]} ]]; then 
		pvcreate ${pvcandidates[*]}
	fi
	
	if [[ $loop == remove ]]; then		
		while [ 1 == 1 ]; do
			
			echo "which pv would you like to remove"
			
			if [[ -n ${pvunassign[*]} ]]; then
				pvs | grep -v ${pvunassign[*]}
			else
				pvs
			fi

			read pvinput

			# if blank line entered then exit loop 
			
			echo ''
			
			echo $pvinput
			
			if [[ -z $pvinput ]]; then
	       			echo "No input given not removing any new partitions" 
				break

			elif [[ "$(pvs --separator ';' | awk -F';' '$2 == "" {print $1}' | egrep -o $pvinput)" == $pvinput ]]; then
				
				echo partition $pvinput selected 
				pvunassign+=($pvinput)

			elif [[ "$(pvs --separator ';' | awk -F';' '$2 != "" {print $1}' | egrep -o $pvinput)" == $pvinput ]]; then
				
				echo "partition $pvinput $(pvs --separator ';' | grep -o $pvinput) is in volume group $(pvs --separator ';' | grep $pvinput | cut -d';' -f2)"
				read input
				defyes $input && pvunassign+=($pvinput)

			elif [[ ! $(pvs --separator ';' | egrep $pvinput) ]] && [[ $(lsblk -o path | grep $pvinput) ]]; then

				echo "partition $pvinput exists but is not a physical volume"	

			elif [[ ! $(lsblk -o path | grep $pvinput) ]]; then

				echo "partition $pvinput does not exist"

			else 
				echo "i dont know how you got here"

			fi

			echo "would you like to remove another partition"
			read input
			defyes $input || break
		done
		if [[ -n ${pvunassign[*]} ]]; then 
			pvremove ${pvunassign[*]}
		fi
	
	fi
done


#
# Section 3
#


# assign volume group
# If you added a physical volume 
# then assume you want to use it  

# If you entered a volume ask if you want to use it

# check if you made any new physical volumes

if [[ -n ${pvcandidates[*]} ]]; then 
	echo "Do you want to create the volume group using input ${pvcandidates[@]}" 
	read input
	defyes $input && physicalvolumes=("${pvcandidates[@]}") 
else
	echo "please select a volume"
	pvs
	# ask instead of do
	read pvselect

	if [[ -z $pvselect ]]; then
		echo "no physical volumes assigned would you like to try again press enter to scripts"
	
	elif [[ ! $(sudo fdisk -l | awk '/^\/dev/ {print $1}' | egrep  "^$pvselect") ]]; then
		echo "Disk not found did you enter a valid partition"


	elif [[ "$(lsblk $pvselect -o fstype | awk 'NR>1 {print}')" != LVM2_member ]]; then
		echo "$pvselect is not of type LVM2_member"


	elif [[ -n $(sudo pvdisplay $pvselect --colon | awk -F':' '{print $2}') ]]; then
		echo "$pvselect is in use by $(sudo pvdisplay $pvselect --colon | awk -F':' '{print $2}')"

	elif [[   ]]
		echo "partition $pvselect is valid"

	else 
		echo "i dont know what happened"


	fi

fi
#
#	echo $pvselect 
#
# else

# If you didnt enter any input

#else
#	echo "please enter a physical volume to use (1 at a time)"
#	read output

# Add another input loop until finished


echo '












'
while true; do
	echo "would you like to add another physical volume"
	read input
	defyes $input
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
		
		if [[ $(sudo pvs | grep "$pvnames" ) ]]; then
			echo "$pvnames is valid and will be used"

		# if device entered is not a valid pv

#		elif
			
		# Verify device not entered
#			echo " nooooooooooooooooooooooooooooooooooooooooooooooooo"
		else 
			echo "Device $pvnames is not valid"
		fi
	
	else
		break
	fi
done

#
#
#
#
#
#
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
		defyes $input && break
	fi
done

echo $vgname ${physicalvolumes[*]}



#
# Section 4
#
# 
