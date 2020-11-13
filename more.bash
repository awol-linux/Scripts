declare -A rules
rules+=([meow]=cisco [awol]=linux)
for key in ${!rules[@]}; do
    echo more ${rules[${key}]}\: ${key}
done

echo "who are you talking to"




while true ;do
	read input
	case $input in
		meow )
        		echo "more cisco"
			break;;
   		 awol )
        		echo "more linux"
			break;;
		*)
			echo "invalid input"
	esac
done
