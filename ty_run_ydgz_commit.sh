bc1=$1
bc2=$2
curdt="`date +%Y%m%d`"
baseConf="/u01/ZJSY/version/TY/shell/log/odpsTb/kfdy"
ydConf="/u01/ZJSY/version/TY/shell/log/odpsTb"
mbConf="${baseConf}/csv/${curdt}"
if [ ! -d $mbConf ] ;then
        mkdir -p $mbConf
fi
touch ${mbConf}/tmp.txt
echo "${bc1}" >> ${mbConf}/tmp.txt
echo "${bc2}" >> ${mbConf}/tmp.txt
if [ -f ${mbConf}/dbxx_${curdt}.csv ] ;then
        rm -rf ${mbConf}/dbxx_${curdt}.csv
fi
if [ -f ${mbConf}/ydbbgdjmx_${curdt}.csv ] ;then
        rm -rf ${mbConf}/ydbbgdjmx_${curdt}.csv
fi
for baseConf1 in `cat ${mbConf}/tmp.txt`;do
	echo "${baseConf1}系统正在比对中，请稍候。。。"
	sh /u01/ZJSY/version/TY/shell/log/odpsTb/kfdy/ty_compare_table_column.sh ${baseConf1} kf_ys_ty
        cat ${ydConf}/${baseConf1}/report/${curdt}/dbxx_${curdt}.csv >> ${mbConf}/dbxx_${curdt}.csv
        cat ${ydConf}/${baseConf1}/report/${curdt}/ydbbgdjmx_${curdt}.csv >> ${mbConf}/ydbbgdjmx_${curdt}.csv
done
rm -rf ${mbConf}/tmp.txt
echo "各系统已比对完毕，汇总结果在csv里"
echo "汇总结果开始上云到ODPS"
# dataxHome
dataxHome=/u01/ZJSY/dataX/datax
startTime=`date '+%Y%m%d%H%M%S'`

# outpath
outpath="${baseConf}/log/$startTime"
if [ -d $outpath ] ;then
	rm -rf  $outpath
fi
mkdir -p  $outpath
touch $outpath/commitJson.log
touch $outpath/succJson.log
touch $outpath/failJson.log
mkdir -p $outpath/succLog
mkdir -p $outpath/failLog

datxD="-Dcurdt=$curdt"
for file in `ls ${baseConf}/*.json` ;do
	jsonName="${file##*/}"
	fileName="${jsonName%%.*}"
	echo $jsonName
	echo "$file" >> $outpath/commitJson.log
	python $dataxHome/bin/datax.py $file -p "$datxD" 2>&1 >> $outpath/$fileName.log
	result=$?
	if [ $result -eq 0 ] ;then
		echo "$fileName" >> $outpath/succJson.log
		mv -f $outpath/$fileName.log $outpath/succLog
	else
		echo "$fileName" >> $outpath/failJson.log
		mv -f $outpath/$fileName.log $outpath/failLog
	fi
	sleep 1
done
echo "开始时间:$startTime"  >> $outpath/commitJson.log
endTime=`date '+%Y%m%d%H%M%S'`
echo "结束时间:$endTime" >> $outpath/commitJson.log
echo "上云完毕，详细内容请查看log日志和odps表内容"
