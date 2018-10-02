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
							var4=$(./legit.pl commit -m all)
							comp=$(echo Committed as commit 0)
							if [[ $var4 == $comp ]]
								then
									if [ -e ".legit/repository/Commit_0/7.txt" ]
										then
											var5=$(./legit.pl log)
											comp=$(echo 0 all)
											if [[ $var5 == $comp ]]
												then 
													echo "Log pass"
											else
												rm -rf ".legit"
												rm "7.txt"
												echo "No log presented"
												exit 1;
											fi
									else
										rm -rf ".legit"
										rm "7.txt"
										echo "Commit 0 does not contains 7.txt"
										exit 1;
									fi
							else
								rm -rf ".legit"
								rm "7.txt"
								echo "Incorrect output $var4"
								exit 1;
							fi
					else	
						rm -rf ".legit"
						rm "7.txt"
						echo "index not contains 7.txt"
						exit 1;
					fi
			else
				rm -rf ".legit"
				rm "7.txt"
				echo "7.txt creation error"
				exit 1;
			fi
	else
		rm -rf ".legit"
		rm "7.txt"
		echo "Incorrect output $var"
		exit 1;
	fi
else
	echo ".legit does not exists"
fi

rm -rf ".legit"
rm "7.txt"