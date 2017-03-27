#!/bin/bash
# @author: bismarckh

max_calc_cnt=-1;
calc_cnt=0;

cpuavgssd=0;
cpuallssd=0;

AddNum()
{
	echo $1 $2 | awk '{print $1+$2}';
}

tidList=$(ls /proc/$(ps aux | grep 'ssd -c' | grep -v grep | awk '{print $2}')/task)
declare -A map=();

for tid in $tidList
do
	map[$tid]=0;
done


while [[ 0 -gt ${max_calc_cnt} ]] || [[ ${calc_cnt} -lt ${max_calc_cnt} ]]
do
 	calc_cnt=$(($calc_cnt+1));
 	echo "============" $calc_cnt "============";
	thNum=$(ps -eLo comm,pcpu,tid | grep ssd | grep -v mini | grep -v monitor | wc -l);
	ssdPsList=$(ps -eLo comm,pcpu,tid | grep ssd | grep -v mini | grep -v monitor);

	i=0;
	while [[ $thNum -gt $i ]]
	do
		cpu=$(echo $ssdPsList | awk -v idx="$i" '{print $(idx*3+2);}');
		tid=$(echo $ssdPsList | awk -v idx="$i" '{print $(idx*3+3);}');
		map[$tid]=$(AddNum ${map[$tid]} $cpu);
		echo $tid ${map[$tid]} $calc_cnt | awk '{ print $1": " $2/$3 }';
		i=$(($i+1));
	done

	if [[ 1 -ne ${max_calc_cnt} ]]; then
		sleep 1
	fi
done
