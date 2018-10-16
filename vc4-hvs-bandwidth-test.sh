#!/bin/sh

MAX_PLANES=8

RES_FILE=$1

run_test() {
	local mode="$1"
	local format="$2"
	local nplanes="$3"
	local alpha="$4"
	local scaling="$5"
	local planes=""
	local hvserr=0
	local extra=""
	local res=`echo $mode|cut -d '-' -f1|cut -d 'i' -f1`
	local refresh=`echo $mode|cut -d '-' -f2`

	if [ $nplanes -gt $MAX_PLANES ]; then
		return -1
	fi

	if [ $nplanes -gt 0 ]; then
		planes="$planes -P 96@95:$res*$scaling@$format -w 96:alpha:$alpha"
	fi

	if [ $nplanes -gt 1 ]; then
		planes="$planes -P 98@95:$res*$scaling@$format -w 98:alpha:$alpha"
	fi

	if [ $nplanes -gt 2 ]; then
		planes="$planes -P 100@95:$res*$scaling@$format -w 100:alpha:$alpha"
	fi

	if [ $nplanes -gt 3 ]; then
		planes="$planes -P 102@95:$res*$scaling@$format -w 102:alpha:$alpha"
	fi

	if [ $nplanes -gt 4 ]; then
		planes="$planes -P 104@95:$res*$scaling@$format -w 104:alpha:$alpha"
	fi

	if [ $nplanes -gt 5 ]; then
		planes="$planes -P 106@95:$res*$scaling@$format -w 106:alpha:$alpha"
	fi

	if [ $nplanes -gt 6 ]; then
		planes="$planes -P 108@95:$res*$scaling@$format -w 108:alpha:$alpha"
	fi

	if [ $nplanes -gt 7 ]; then
		planes="$planes -P 110@95:$res*$scaling@$format -w 110:alpha:$alpha"
	fi

	killall modetest 2>/dev/null
	sleep 1
	echo 0 > /sys/kernel/debug/dri/128/vc4_rejected
	echo 0 > /sys/kernel/debug/dri/128/vc4_hvs_err
	echo 0 > /sys/kernel/debug/dri/128/vc4_hvs_load_too_high
	echo 0 > /sys/kernel/debug/dri/128/vc4_membus_load_too_high

	echo "modetest -M vc4 -s 29:$res-$refresh $planes" >> /dev/kmsg
	echo ">>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>" >> /dev/kmsg
	modetest -M vc4 -s 29:$res-$refresh $planes 2>/dev/null 1>&2 &
	sleep 3
	killall modetest 2>/dev/null
	echo "<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<" >> /dev/kmsg

	local result=""
	if [ `cat /sys/kernel/debug/dri/128/vc4_rejected` == "Y" ]; then
		info="Other"
		result="Rejected"
	else
		result="Accepted"
		info=""
		if [ `cat /sys/kernel/debug/dri/128/vc4_hvs_load_too_high` == "Y" ]; then
			result="Rejected"
			info="$info 'HVS load too high'"
		fi

		if [ `cat /sys/kernel/debug/dri/128/vc4_membus_load_too_high` == "Y" ]; then
			result="Rejected"
			info="$info 'membus load too high'"
		fi

		if [ $result == "Accepted" ]; then
			if [ `cat /sys/kernel/debug/dri/128/vc4_hvs_err` == "Y" ]; then
				info="HVS error"
			else
				info="Okay"
			fi
		else
			if [ `cat /sys/kernel/debug/dri/128/vc4_hvs_err` == "Y" ]; then
				info="$info Okay"
			else
				info="$info Would have worked"
			fi
		fi
	fi

	testname="mode=$mode format=$format nplanes=$nplanes alpha=$alpha scaling=$scaling"
	echo "test $testname	=> $result ($info)" >> $RES_FILE
}


modes="1920x1080-60 1920x1080i-60 1920x1080-50 1920x1080i-50"
modes="$modes 1280x1024-75"
modes="$modes 1440x900-75 1440x900-60"
modes="$modes 1280x720-60 1280x720-50"
modes="$modes 1024x768-75 1024x768-70 1024x768-60"
modes="$modes 800x600-75 800x600-72 800x600-60 800x600-56"
modes="$modes 720x576-50 720x576i-50"
modes="$modes 720x480-60 720x480i-60"
modes="$modes 720x400-70"
modes="$modes 640x480-75 640x480-73 640x480-60"

planes="1 2 3 4 5 6 7 8"

formats="XR24 NV12"

#alphas="65535 32768 00000"
alphas="65535"

scalings="1 0.5 2"

mount -t debugfs dbg /sys/kernel/debug/ 2>/dev/null
rm -f $RES_FILE

for mode in $modes; do
	for format in $formats; do
		for nplanes in $planes; do
			for alpha in $alphas; do
				for scaling in $scalings; do
					run_test $mode $format $nplanes $alpha $scaling
				done
			done
		done
	done
done

#run_test $1 $2 $3 $4


#rm $2

#while read line; do
#	run_test $line
#	if [ $? -eq 0 ]; then
#		echo "$line => success" >> $2
#	else
#		echo "$line => failure" >> $2
#	fi
#done < $1

