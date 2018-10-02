#!/bin/bash
var=$(./legit.pl init)
comp=$(seq -f "line %.0f" 1 7 >c)
var=$(./legit.pl add c)
var=$(./legit.pl commit -m first)
var=$(./legit.pl branch b1)
var=$(./legit.pl checkout b1)
comp=$(seq -f "line %.0f" 0 8 >c)
var=$(./legit.pl commit -a -m commit-1)
var=$(./legit.pl checkout master)
comp=$(sed -i 4d c)
var=$(./legit.pl commit -a -m commit-2)
var=$(./legit.pl merge -m merge1 b1)
comp=$(echo "Auto-merging c")
if [[ $var == $comp ]]
	then
		rm -rf ".legit"
		rm "c"
		echo "Merge pass"
else
	rm -rf ".legit"
	rm "c"
	echo "Merge failed"
fi
