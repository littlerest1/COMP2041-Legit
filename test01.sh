#!/bin/bash
var=$(./legit.pl init)
if [ -d ".legit" ]
then
	comp=$(echo Initialized empty legit repository in .legit)
	if [[ $var == $comp ]]
		then
			var2=$(seq 1 7 >7.txt)
			if [ -e "7.txt" ]
				then
					var3=$(./legit.pl add 7.txt)
					if [ -e ".legit/index/7.txt" ]
						then 
							echo "Add pass"
					else	
						echo "index not contains 7.txt"
						exit 1;
					fi
			else
				echo "7.txt creation error"
				exit 1;
			fi
	else
		echo "Incorrect output $var"
		exit 1;
	fi
	rm -rf ".legit"
	rm "7.txt"
else
	echo ".legit does not exists"
fi