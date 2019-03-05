CREATE TABLE t_yy_ydgz_dbxx (
	rwbh STRING COMMENT '任务编号用于主副表关联',
	ydklx STRING COMMENT '源端库类型如生产库',
	ydbxt STRING COMMENT '源端表系统名如核心征管',
	mbdxm STRING COMMENT '目标端ODPS对比表项目名',
	dbbsl STRING COMMENT '对比表数量',
	bgbsl STRING COMMENT '变更表数量',
	dbsj DATETIME COMMENT '对比时间'
)
COMMENT '对比信息';

CREATE TABLE t_yy_ydgz_ydbbgdjmx (
	bguuid STRING COMMENT '变更UUID',
	rwbh STRING COMMENT '任务编号用于主副表关联',
	ydbgklx STRING COMMENT '源库类型如生产库分发库',
	ydbgbxt STRING COMMENT '源端表变更的系统名如核心征管',
	ydbgbmc STRING COMMENT '源端变更表名称',
	mbdbgbxm STRING COMMENT '目标端ODPS对比表项目名',
	mbdbgbmc STRING COMMENT '目标端ODPS对比表名称',
	bglx STRING COMMENT '变更类型',
	bghqsj DATETIME COMMENT '变更获取时间',
	bgqnr STRING COMMENT '变更前内容',
	bghnr STRING COMMENT '变更后内容'
)
COMMENT '源端表结构变更登记明细表';