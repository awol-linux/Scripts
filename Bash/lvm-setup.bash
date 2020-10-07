#/bin/env bash

# Add a function for a yes or no prompt
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


#Assign pv
declare -a pvcandidates
while true ; do
	echo 'Please enter physcal device path or press Enter to skip'
	echo "available paritions are" 
	echo "$(lsblk -o name,type,fstype,size | awk -F'-' '/part\s{2}/ {$1="" ; print}')"
	read pvinput
	[[ -z $pvinput ]] && echo "partition $pvinput not a valid partition"i && break ||\
	[[ $(sudo fdisk -l | awk '/^\/dev/ {print $1}' | egrep  "^$pvinput"$) ]] &&\
	[[ $pvinput != "${pvcandidates[@]}" ]] &&\
		pvcandidates+=($pvinput) && \
		echo "partition $pvinput valid" && \
		echo ${pvcandidates[*]} && \
		echo "would you like to enter anther partition" && \
		read input && \
		fn input && \
		if [[ $output == false ]]; then
			break
		fi
#	else
#	fi
done
#	else
#		
#		break
#	fi
pvs
# assign volume group
echo "Enter volume group name"
read vgname
if [[ ! -z $pvinput ]] ; then
		read -r -p "Do you want to create a volume group using $pvinput" input 
		fn input
		if [[ $output == true ]]; then
			physical-volumes=$output
fi

while true; do
	echo "would you like to add another physical volume"
	fn input
	if [[ output == true ]]; then
		echo "Please enter disk names"
		read pvnames
		if [[ $(sudo pvs | grep "$pvnames" ) ]] ; then
			echo "$pvnames is valid and will be used"
		else 
			echo "Device $pvnames is not valid"
		fi
	else
		break
	fi
done
