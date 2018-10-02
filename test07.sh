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
													var6=$(./legit.pl show 0:b)
													comp=$(echo "legit.pl: error: 'b' not found in commit 0")
													if [[ $var6 == $comp ]]
														then
															var6=$(./legit.pl show 0:7.txt)
															comp=$(seq 1 7)
															if [[ $var6 == $comp ]]
																then 
																	comp=$(echo 8 >>7.txt)
																	var7=$(./legit.pl commit -a -m changes)
																	comp=$(echo "Committed as commit 1")
																	if [[ $var7 == $comp ]]
																		then
																			var7=$(./legit.pl show 1:7.txt)
																			comp=$(seq 1 8)
																			if [[ $var7 == $comp ]]
																				then
																					var8=$(./legit.pl status)
																					if [[ $var8 = *"7.txt - same as repo"*  ]]
																						then
																							var8=$(echo hahaha >>7.txt)
																							var8=$(./legit.pl status)
																							if [[ $var8 = *"7.txt - file changed, changes not staged for commit"*  ]]
																								then
																									var8=$(./legit.pl branch b1)
																									var8=$(./legit.pl branch)
																									comp=$(printf "b1\nmaster\n")
																									if [[ $var8 == $comp ]]
																										then
																											echo "Branch create pass"
																									else
																										echo "Incorrect output: $var8"
																										rm -rf ".legit"
																										rm "7.txt"
																										exit 1
																									fi
																							else
																								echo "Incorrect output $var8"
																								rm -rf ".legit"
																								rm "7.txt"
																								exit 1
																							fi	
																					else
																						echo "Incorrect output $var8"
																						rm -rf ".legit"
																						rm "7.txt"
																						exit 1
																					fi							
																			else
																				echo "Incorrect output $var7"
																				rm -rf ".legit"
																				rm "7.txt"
																				exit 1
																			fi
																	else
																		echo "Incorrect output $var7"
																		rm -rf ".legit"
																		rm "7.txt"
																		exit 1
																	fi
																			
															else
																echo "Incorrect output $var6"
																rm -rf ".legit"
																rm "7.txt"
																exit 1
															fi
													else
														echo "Incorrect output: $var6"
														rm -rf ".legit"
														rm "7.txt"
														exit 1
													fi
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