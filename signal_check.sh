#! /bin/bash

INTERFACE="wlx008733419552"

echo "=============== Signal strength checking ==============="
printf "\t\t\tINTERFACE : $INTERFACE\n"
IFS_backup="$IFS"
IFS=$'\n'
connectedIP=(192.168.168.183)

function getSignal(){
	# Get Mac add & signal strength
	result=0
	for i in {1..10}
	do
		for aIP in "${connectedIP[@]}"
		do
			ping -c 1 -w 1 -b $aIP > /dev/null 2>&1
			aMac=(`arp -i $INTERFACE | grep $aIP | grep -oE "([a-f0-9]{2}[-:]){5}[a-f0-9]{2}"`)
			sSignal=(`iw dev $INTERFACE station get $aMac | grep "signal:" | awk '{print $2}'`)

			((result+=${sSignal}))
			#echo $sSignal
			#printf "$aIP\t$aMac\t$sSignal\n"
		done
	done
	((result/=10))
	echo $result
}

while :
do
	timestamp=`date +%Y/%m/%d/%H:%M:%S`
	printf "\t\t\t\t$timestamp\n"
	echo "--------------------------------------------------------" #56
	#printf "\nIP\t\tMac\t\t\tSignal\n"
	printf "\n Average of RSSI ( 10 times ) : "	
	getSignal
	sleep 1
	iperf3 -c $connectedIP	
	echo "========================================================" #56
	sleep 1
done

IFS="$IFS_backup"
