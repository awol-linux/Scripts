#/bin/env bash
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

echo 'Please enter physcal device path or press Enter to skip'
read pvinput
if [[ ! -z $pvinput ]] ; then
	echo $pvinput
	for partition in $(sudo fdisk -l | cut --delimiter=' ' --fields=1  | grep dev)
	do
		
	done
else
	echo 'Not assigning any physical devices'	
fi

pvs

# assign volume group
echo "Enter volume group name"
read vgname
if [[ ! -z $pvinput ]] ; then
		read -r -p "Do you want to create a volume group using $pvinput" input 
		fn input
		if [ $output == true ]; then
			physical-volumes=$output
		else
			echo "Please enter disk names"
			read pvs
		fi 
fi
#	
#else 
#	read -r -p "please" 
#echo $vginput
