#/bin/env bash
#set -x

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
while true ; do
	echo 'Please enter physcal device path or press Enter to skip'
	read pvinput
	if [[ ! -z $pvinput ]] ; then
		echo $pvinput
		if [[ $(sudo fdisk -l | awk '/^\/dev/ {print $1}' | grep "$pvinput") ]] ; then
			echo "partition $pvinput valid"
			echo "would you like to enter anther partition"
			read input
			fn input
			if [output == false]; then
				break
			fi
		else
			echo "partition $pvinput not a valid partition"
		fi
	else
		echo "OK no assigning any physical volumes"
		break
	fi
	pvs
done

# assign volume group
echo "Enter volume group name"
read vgname
if [[ ! -z $pvinput ]] ; then
		read -r -p "Do you want to create a volume group using $pvinput" input 
		fn input
		if [ $output == true ]; then
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
