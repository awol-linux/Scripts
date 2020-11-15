# day 1

declare -A rules
rules+=([meow]=cisco [awol]=linux)
for key in ${!rules[@]}; do
    echo more ${rules[${key}]}\: ${key}
done


# day 2

echo "who are you talking to"
while true ;do
        read input
        case $input in
                meow )
                        echo "more rhel"
                        break;;
                awol )
                        echo "more rhel"
                        break;;
                kelvin )
                        echo "more cisco"
                        break ;;
                *)
                        echo "invalid input"
                        ;;
        esac
done
