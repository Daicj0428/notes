#! /bin/bash

########################

for i in ` seq 1 9 `
do
	for j in `seq $i `
	do
	            echo -n -e "$i*$j=$[ i*j ]\t"
	done
	echo " "
done
