#!/bin/bash
# @author: bismarckh

max_calc_cnt=-1;
calc_cnt=0;

cpussrotated=0;
cpusscored=0;
cpuavgssd=0;
cpuallssd=0;
cpussroutined=0;
cpussdaemonmonitord=0;
cpussnotifyd=0;
cpusslogd=0;
cpussfailoverd=0;
cpussactruled=0;
cpussrtpdataproviderd=0;
cpussrtspserverd=0;
cpudisplayd=0;
cpussarchivingd=0;
cpussmessaged=0;

while [[ 0 -gt ${max_calc_cnt} ]] || [[ ${calc_cnt} -lt ${max_calc_cnt} ]]
do
	if [[ 1 -ne ${max_calc_cnt} ]]; then
		sleep 1
	fi
	calc_cnt=$(($calc_cnt+1));

	echo "============" $calc_cnt "============";
	#cpuavgssd=$(($cpuavgssd+$(ps -p $(pidof ssd) -o %cpu,%mem,cmd | grep ssd | awk '{print $1}')));
	cpuavgssd=$(echo ${cpuavgssd} \
			$(ps aux | grep Sur | grep 'ssd -c' | awk '{print $2}' | xargs ps -o %cpu,%mem,cmd -p | grep ssd | awk '{sum+=$1} END {print sum}') \
			$(ps aux | grep Sur | grep 'ssd -c' | wc -l) \
			| awk '{print $1+($2/$3)}');
	cpuallssd=$(echo ${cpuallssd} \
			$(ps aux | grep Sur | grep 'ssd -c' | awk '{print $2}' | xargs ps -o %cpu,%mem,cmd -p | grep ssd | awk '{sum+=$1} END {print sum}') \
			| awk '{print $1+$2}');
	cpussrotated=$(echo ${cpussrotated} $(ps -p $(pidof ssrotated) -o %cpu,%mem,cmd | grep ssrotated | awk '{print $1}') | awk '{print $1+$2}');
	cpusscored=$(echo ${cpusscored} $(ps -p $(pidof sscored) -o %cpu,%mem,cmd | grep sscored | awk '{print $1}') | awk '{print $1+$2}');
	cpussroutined=$(echo ${cpussroutined} $(ps -p $(pidof ssroutined) -o %cpu,%mem,cmd | grep ssroutined | awk '{print $1}') | awk '{print $1+$2}');
	cpussdaemonmonitord=$(echo ${cpussdaemonmonitord} $(ps -p $(pidof ssdaemonmonitord) -o %cpu,%mem,cmd | grep ssdaemonmonitord | awk '{print $1}') | awk '{print $1+$2}');
	cpussnotifyd=$(echo ${cpussnotifyd} $(ps -p $(pidof ssnotifyd) -o %cpu,%mem,cmd | grep ssnotifyd | awk '{print $1}') | awk '{print $1+$2}');
	cpusslogd=$(echo ${cpusslogd} $(ps -p $(pidof sslogd) -o %cpu,%mem,cmd | grep sslogd | awk '{print $1}') | awk '{print $1+$2}');
	cpussfailoverd=$(echo ${cpussfailoverd} $(ps -p $(pidof ssfailoverd) -o %cpu,%mem,cmd | grep ssfailoverd | awk '{print $1}') | awk '{print $1+$2}');
	cpussactruled=$(echo ${cpussactruled} $(ps -p $(pidof ssactruled) -o %cpu,%mem,cmd | grep ssactruled | awk '{print $1}') | awk '{print $1+$2}');
	cpussrtpdataproviderd=$(echo ${cpussrtpdataproviderd} $(ps -p $(pidof ssrtpdataproviderd) -o %cpu,%mem,cmd | grep ssrtpdataproviderd | awk '{print $1}') | awk '{print $1+$2}');
	cpussrtspserverd=$(echo ${cpussrtspserverd} $(ps -p $(pidof ssrtspserverd) -o %cpu,%mem,cmd | grep ssrtspserverd | awk '{print $1}') | awk '{print $1+$2}');
	cpudisplayd=$(echo ${cpudisplayd} $(ps -p $(pidof displayd) -o %cpu,%mem,cmd | grep displayd | awk '{print $1}') | awk '{print $1+$2}');
	cpussarchivingd=$(echo ${cpussarchivingd} $(ps -p $(pidof ssarchivingd) -o %cpu,%mem,cmd | grep ssarchivingd | awk '{print $1}') | awk '{print $1+$2}');
	cpussmessaged=$(echo ${cpussmessaged} $(ps -p $(pidof ssmessaged) -o %cpu,%mem,cmd | grep ssmessaged | awk '{print $1}') | awk '{print $1+$2}');

	echo ${cpuavgssd} ${calc_cnt} | awk '{print "cpuavgssd: " $1/$2}'
	echo ${cpuallssd} ${calc_cnt} | awk '{print "cpuallssd: " $1/$2}'
	echo ${cpussrotated} ${calc_cnt} | awk '{print "cpussrotated: " $1/$2}'
	echo ${cpusscored} ${calc_cnt} | awk '{print "cpusscored: " $1/$2}'
	echo ${cpussroutined} ${calc_cnt} | awk '{print "cpussroutined: " $1/$2}'
	echo ${cpussdaemonmonitord} ${calc_cnt} | awk '{print "cpussdaemonmonitord: " $1/$2}'
	echo ${cpussnotifyd} ${calc_cnt} | awk '{print "cpussnotifyd: " $1/$2}'
	echo ${cpusslogd} ${calc_cnt} | awk '{print "cpusslogd: " $1/$2}'
	echo ${cpussfailoverd} ${calc_cnt} | awk '{print "cpussfailoverd: " $1/$2}'
	echo ${cpussactruled} ${calc_cnt} | awk '{print "cpussactruled: " $1/$2}'
	echo ${cpussrtpdataproviderd} ${calc_cnt} | awk '{print "cpussrtpdataproviderd: " $1/$2}'
	echo ${cpussrtspserverd} ${calc_cnt} | awk '{print "cpussrtspserverd: " $1/$2}'
	echo ${cpudisplayd} ${calc_cnt} | awk '{print "cpudisplayd: " $1/$2}'
	echo ${cpussarchivingd} ${calc_cnt} | awk '{print "cpussarchivingd: " $1/$2}'
	echo ${cpussmessaged} ${calc_cnt} | awk '{print "cpussmessaged: " $1/$2}'

	if [[ 0 -ne $? ]]; then
		break
	fi
done
