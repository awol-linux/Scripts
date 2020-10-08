#/bin/env bash
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

# Enter device path loop untill done

while true ; do
	echo 'Please enter physcal device path or press Enter to skip'
	echo "available paritions are" 

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
	
	# add partition to array
	
	else	
		pvcandidates+=($pvinput) 
		echo "partition $pvinput valid"
		echo ${pvcandidates[@]}
		echo "would you like to enter anther partition"
		read input
		fn input 
		if [[ $output == false ]]; then
			break
		fi
	fi
done


# Show Physical Volume To confirm action was done

pvs


#
# Section 2
#


# assign volume group
# If you added a physical volume 
# then assume you want to use it  


# Ask for volume group name

echo "Enter volume group name"
read vgname

# If you entered a volume ask if you want to use it

if [[ -n $pvinput ]] ; then
	read -r -p "Do you want to create a volume group using $pvinput" input 
	fn input
	if [[ $output == true ]]; then
		physical-volumes=$output
	fi

# If you didnt enter a input

else
	echo "please enter a physical volume to use (1 at a time)"
	read output
fi

# Add another input loop untill finished
while true; do
	echo "would you like to add another physical volume"
	fn input
	if [[ output == true ]]; then
		echo "Please enter disk names"
		read pvnames
		
		# Verify physical volume exists
		
		if [[ $(sudo pvs | grep "$pvnames" ) ]] ; then
			echo "$pvnames is valid and will be used"
		else 
			echo "Device $pvnames is not valid"
		fi
	else
		break
	fi
done
