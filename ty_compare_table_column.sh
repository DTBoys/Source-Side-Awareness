#!/bin/bash
################################################################################
# SCRIPT_NAME     : ty_compare_table_column.sh
#
# CREATE_TIME     : 2018/08/17
# AUTHOR          : Mochou_liqb
# DESCRIBETION    : comparing oracle today's and yesterday's all_columns to get changing_tables
# PARAMETER       : 1 baseConf, such as HX
# EXAMPLE         : ./ty_compare_table_column.sh HX
# UPDATE_RECORD   : this is the first version and kill some bugs
#
# DATE      OPERATION       CZR         DESCRIBETION
# ________  _____________   ________    __________________________________
#
# 2018/11/06  UPDATE Mochou_liqb
################################################################################

if [ $# -lt 1 ] ;then
	echo  "请输入参数:源端系统名"
	exit 1;
fi
#sending parameter
baseConf=$1
baseProject="SC_YS_TY"
echo "当前系统是 ${baseConf}"
#building these pathes
curdt="`date +%Y%m%d`"
basePath="/u01/ZJSY/version/TY"
shellPath="$basePath/shell"
confBase="$basePath/$baseConf/conf"
#desc every tableName by oracle and save into this dir one by one
#eg.file_name : T_YS_HX_DJ_NSRXX
logPathConf="$shellPath/log/odpsTb/$baseConf/conf"
logPathOra="$shellPath/log/odpsTb/$baseConf/ora"
logPathReport="$shellPath/log/odpsTb/$baseConf/report/${curdt}"
logPathTmp="$shellPath/log/odpsTb/$baseConf/tmp"
odpsPath="/u01/ZJSY/ODPS/odpscmd_20"
#build && delete log_dir
if [ ! -d $logPathConf ] ;then
	mkdir -p $logPathConf
fi
if [ ! -d $logPathOra ] ;then
	mkdir -p $logPathOra
fi
if [ ! -d $logPathReport ] ;then
	mkdir -p $logPathReport
fi
if [ ! -d $logPathTmp ] ;then
	mkdir -p $logPathTmp
fi
if [ -f $logPathReport/ydbbgdjmx_$curdt.csv ] ;then
	rm -rf $logPathReport/ydbbgdjmx_$curdt.csv
fi
if [ -f $logPathReport/dbxx_$curdt.csv ] ;then
	rm -rf $logPathReport/dbxx_$curdt.csv
fi
if [ -f $logPathTmp/bgdjtmp_$curdt.txt ] ;then
	rm -rf $logPathTmp/bgdjtmp_$curdt.txt
fi
#get SOURCE_TABLE_COLUMNS and TARGET_TABLE_COLUMNS
#oracle sqlplus  environment variable by system servers
reader="oraclereader"
source $confBase/ty_datasource.conf
if [[ "$reader" == "oraclereader" ]];then
	export ORACLE_HOME=$TY_ORACLE_HOME
	export LD_LIBRARY_PATH=$TY_LD_LIBRARY_PATH
	export NLS_LANG="$nls_lang"
	export PATH=$ORACLE_HOME/bin:$LD_LIBRARY_PATH:$PATH
fi

# check database 
function checkDBlink(){
	SQL="select to_char(sysdate,'yyyy-mm-dd') today from dual;"
	ii=0
	flag=false
	DATE=$(date +%Y-%m-%d)
	while [ $ii -lt 3 ]
	do
		OK=`sqlplus -S $user/$pass@$jdbc <<END
			set heading off
			set feedback off
			set pagesize 0
			set verify off
			set echo off
			set line 3000
			$SQL
			quit;
END`
		ii=$[ii+1]
		if [[ $OK == $DATE ]] ; then
			flag=true;
			echo "数据库连接连接成功，开始执行脚本!";
			break;
		fi
		sleep 5;
	done
	if [[ $flag == false ]] ;then
		echo "数据库连接失败，请检查数据库连接信息!";
	fi
}
checkDBlink

# run it before combaring
for line in `cat $confBase/ty_createJson_ql.conf | grep -v "^#"`
do
	tableUser=`echo $line | awk -F '|' '{print $1}' | sed -r "s/\(|\)//g" | tr [a-z] [A-Z]`
	tableName=`echo $line | awk -F '|' '{print $2}' | sed -r "s/\(|\)//g" | tr [a-z] [A-Z]`
	tableODPS=`echo $line | awk -F '|' '{print $3}' | sed -r "s/\(|\)//g" | tr [a-z] [A-Z]`
	loadsql="SELECT COLUMN_NAME||'|'||DATA_TYPE||'|'||DATA_LENGTH FROM ALL_TAB_COLUMNS  WHERE OWNER = '$tableUser' AND TABLE_NAME = '$tableName' ORDER BY COLUMN_ID;"
	tableInfoSQL="$loadsql"
	result=`sqlplus -S $user/$pass@$jdbc <<END
		set heading off
		set feedback off
		set pagesize 0
		set verify off
		set echo off
		set line 3000
		$tableInfoSQL
		quit;
END`
	sselect=`echo  "$result"| awk  '{printf "%s\n", $0}'`
	echo "$sselect" > $logPathOra/$tableODPS
	echo "$tableODPS is done"
done

#comparing source_table and target_table to get changing_tables
#use oracle_table_name_new one by one to get table_parameter
table_num=0
table_num_bg=0
RWBH=`uuid | awk -F '-' '{print $1$2$3$4$5}'`
dbsj=`date -d today +"%Y-%m-%d %T"`
for line in `cat $confBase/ty_createJson_ql.conf | grep -v "^#"`
do
	tableUser=`echo $line | awk -F '|' '{print $1}' | sed -r "s/\(|\)//g" | tr [a-z] [A-Z]`
	tableName=`echo $line | awk -F '|' '{print $2}' | sed -r "s/\(|\)//g" | tr [a-z] [A-Z]`
	tableODPS=`echo $line | awk -F '|' '{print $3}' | sed -r "s/\(|\)//g" | tr [a-z] [A-Z]`
	#read file and  file type is  HX_DJ|DJ_NSRXX|T_TY_HX_DJ_NSRXX|DJXH|NO|247682364
	#get oracle_table_column
	echo "======== table is :  $tableODPS ============="
	
	#declare arr to save columns
	declare -a array_column_ora
	i=0
	for arr in `cat $logPathConf/$tableODPS | awk -F '|' '{print $1}' | tr [a-z] [A-Z]`
	do
		#add element into array_name
		array_column_ora[i]="$arr"
		i=`expr $i+1`
	done
	declare -a array_column_ora_length
	m=0
	for arr in `cat $logPathConf/$tableODPS | awk -F '|' '{print $3}' | tr [a-z] [A-Z]`
	do
		#add element into array_name
		array_column_ora_length[m]="$arr"
		m=`expr $m+1`
	done
	#get oracle_column
	#oracle column to set
	#declare array_column_ora_new
	declare -a array_column_ora_new
	j=0
	for arr in `cat $logPathOra/$tableODPS | awk -F '|' '{print $1}' | tr [a-z] [A-Z]`
	do
		#add element into array_name
		array_column_ora_new[j]=$arr
		j=`expr $j+1`
	done
	declare -a array_column_ora_new_length
	n=0
	for arr in `cat $logPathOra/$tableODPS | awk -F '|' '{print $3}' | tr [a-z] [A-Z]`
	do
		#add element into array_name
		array_column_ora_new_length[n]=$arr
		n=`expr $n+1`
	done
	display_old=`cat  $logPathConf/$tableODPS | xargs`
	display_new=`cat  $logPathOra/$tableODPS | xargs`
	echo "当前表结构是${display_new}"
	echo "初始表结构是${display_old}"
	num_comp=0
	#compare all columns	
	for table in `ls $logPathOra`
	do
		if [ ${#array_column_ora_new[*]} -ge ${#array_column_ora[*]} ]; then
			num_comp=${#array_column_ora_new[*]}
			if [ "$table" = "$tableODPS" ] ;then
				for((k=0;k<${num_comp};k++))
				do
					if [ "${array_column_ora[k]}" = "${array_column_ora_new[k]}" ]; then
						if [ "${array_column_ora_length[k]}" = "${array_column_ora_new_length[k]}" ]; then
							continue
						elif [ "${array_column_ora_length[k]}" != "${array_column_ora_new_length[k]}" ] && [ $k -le `expr ${num_comp} - 1` ]; then 
							UUID=`uuid | awk -F '-' '{print $1$2$3$4$5}'`
							table_num_bg=`expr ${table_num_bg} + 1`
							# write into ydbbgdjmx
							echo "${UUID},${RWBH},预生产库,${baseConf},${tableUser}.${tableName},${baseProject},$tableODPS,字段类型改变,${dbsj},${display_old},${display_new}" >> $logPathReport/ydbbgdjmx_$curdt.csv
                        	echo "$tableODPS 表字段类型发生变化,具体情况已写入$curdt报告"
							break
						fi
					elif [ "${array_column_ora[k]}" != "${array_column_ora_new[k]}" ] && [ $k -le `expr ${num_comp} - 1`  ] && [ ${#array_column_ora[*]} -eq ${#array_column_ora_new[*]} ]; then
						UUID=`uuid | awk -F '-' '{print $1$2$3$4$5}'`
                        table_num_bg=`expr ${table_num_bg} + 1`
						# write into ydbbgdjmx
						echo "${UUID},${RWBH},预生产库,${baseConf},${tableUser}.${tableName},${baseProject},$tableODPS,字段名称改变,${dbsj},${display_old},${display_new}" >> $logPathReport/ydbbgdjmx_$curdt.csv
                        echo "$tableODPS 表字段名称发生变化,具体情况已写入$curdt报告"
						break
					else	
						UUID=`uuid | awk -F '-' '{print $1$2$3$4$5}'`
						table_num_bg=`expr ${table_num_bg} + 1`
						# write into ydbbgdjmx
						echo "${UUID},${RWBH},预生产库,${baseConf},${tableUser}.${tableName},${baseProject},$tableODPS,字段新增,${dbsj},${display_old},${display_new}" >> $logPathReport/ydbbgdjmx_$curdt.csv
						echo "$tableODPS 表字段有新增,具体情况已写入$curdt报告"
						break
					fi
				done
			fi
		else 
			num_comp=${#array_column_ora[*]}
			if [ "$table" = "$tableODPS" ] ;then
				for((k=0;k<${num_comp};k++))
				do
					if [ "${array_column_ora[k]}" = "${array_column_ora_new[k]}" ]; then
						continue
					else	
						UUID=`uuid | awk -F '-' '{print $1$2$3$4$5}'`
						table_num_bg=`expr ${table_num_bg} + 1`
						# write into ydbbgdjmx
						echo "${UUID},${RWBH},预生产库,${baseConf},${tableUser}.${tableName},${baseProject},$tableODPS,字段减少,${dbsj},${display_old},${display_new}" >> $logPathReport/ydbbgdjmx_$curdt.csv
						echo "$tableODPS 表字段有减少,具体情况已写入$curdt报告"
						break
					fi
				done
			fi
		fi
	done
	echo ""
	echo "---------------下一个----------------"
	table_num=`expr ${table_num} + 1`
	# clear , start next
	unset array_column_ora_new
	unset array_column_ora
done
# more rows merge into one row
# sed -i  ':a ; N;s/\n/ / ; t a ; ' $logPathTmp/bgdjtmp_$curdt.txt
SQL="select PERCENT_SPACE_USED||'%' From v\$flash_recovery_area_usage  where file_type='ARCHIVED LOG';"
OK=`sqlplus -S $user/$pass@$jdbc <<END
			set heading off
			set feedback off
			set pagesize 0
			set verify off
			set echo off
			set line 3000
			$SQL
			quit;
END`
logDC=`echo  "$OK"| awk  '{printf "%s\n", $0}'`
# write into dbxx
echo "${RWBH},预生产库,${baseConf},${logDC},${table_num},${table_num_bg},${dbsj}" >> $logPathReport/dbxx_$curdt.csv


