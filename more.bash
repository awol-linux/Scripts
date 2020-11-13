declare -A rules
rules+=([meow]=cisco [awol]=linux)
for key in ${!rules[@]}; do
    echo more ${rules[${key}]} ${key}
done
