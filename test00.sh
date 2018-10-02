#!/bin/bash
var=$(./legit.pl init)
if [ -d ".legit" ]
then
	comp=$(echo Initialized empty legit repository in .legit)
	if [[ $var == $comp ]]
		then
			var2=$(./legit.pl init)
			comp2=$(echo legit.pl: error: .legit already exists)
			if [[ $var2 == $comp2 ]]
			then
				echo "Init pass"
			else	
				echo "Incorrect output: $var2"
			fi
		else
			echo "Incorrect output: $var"
	fi
	rm -rf ".legit"
else
	echo ".legit does not exists"
fi