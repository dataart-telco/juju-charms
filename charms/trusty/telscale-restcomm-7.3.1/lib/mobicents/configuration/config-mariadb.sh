#!/bin/bash
## Description: Enables and configures MariaDB datasource
## Params:
## 			1. RESTCOMM_VERSION
## Author: Henrique Rosa

# IMPORTS
source lib/mobicents/utils/read-network-props.sh

# VARIABLES
RESTCOMM_HOME=/opt/restcomm
RESTCOMM_DEPLOY=$RESTCOMM_HOME/standalone/deployments/restcomm.war

## Description: Configures MyBatis for MariaDB
## Parameters : none
configMybatis() {
	FILE=$RESTCOMM_DEPLOY/WEB-INF/conf/mybatis.xml
	
	grep -q '<environment id="mariadb">' $FILE || sed -i '/<environments.*>/ a \
	\	<environment id="mariadb">\
	\		<transactionManager type="JDBC"/>\
	\		<dataSource type="JNDI">\
	\			<property name="data_source" value="java:/MariaDS" />\
	\		</dataSource>\
	\	</environment>\
	' $FILE
	
	sed -e '/<environments.*>/ s|default=".*"|default="mariadb"|' $FILE > $FILE.bak
	mv $FILE.bak $FILE
	juju-log 'Activated mybatis environment for MariaDB';
}

## Description: Configures MariaDB Datasource
## Parameters : 1. Private IP
configureDataSource() {
	FILE=$RESTCOMM_HOME/standalone/configuration/standalone-sip.xml
	
	# Update DataSource
	sed -e "/<datasource jndi-name=\"java:\/MariaDS\" .*>/ {
		N
		s|<connection-url>.*</connection-url>|<connection-url>jdbc:mariadb://$1:3306/restcomm</connection-url>|
		N
		N
		N
		N
		N
		N
		s|<user-name>.*</user-name>|<user-name>telestax</user-name>|
		s|<password>.*</password>|<password>m0b1c3nt5</password>|
	}" $FILE > $FILE.bak
	mv $FILE.bak $FILE	
	juju-log 'Updated MariaDB DataSource Configuration'
}

## Description: Enables MariaDB Datasource while disabling the remaining
## Parameters : none
enableDataSource() {
	FILE=$RESTCOMM_HOME/standalone/configuration/standalone-sip.xml
	
	# Disable all datasources but MariaDB
	sed -e '/<datasource/ s|enabled="true"|enabled="false"|' \
	    -e '/<datasource.*MariaDS/ s|enabled=".*"|enabled="true"|' \
	    $FILE > $FILE.bak
	
	mv $FILE.bak $FILE
	juju-log 'Enabled MariaDB datasource'
}

## Description: Configures RestComm DAO manager to use MariaDB
## Params: none
configDaoManager() {
	FILE=$RESTCOMM_DEPLOY/WEB-INF/conf/restcomm.xml
	
	sed -e '/<dao-manager class="org.mobicents.servlet.restcomm.dao.mybatis.MybatisDaoManager">/ {
		N
		N
		s|<data-files>.*</data-files>|<data-files></data-files>|
		N
		s|<sql-files>.*</sql-files>|<sql-files>${restcomm:home}/WEB-INF/scripts/mariadb/sql</sql-files>|
	}' $FILE > $FILE.bak
	
	mv $FILE.bak $FILE
	juju-log 'Configured iBatis Dao Manager for MariaDB'
}

# MAIN
juju-log 'Configuring MariaDB datasource...'
#configureDataSource $PRIVATE_IP
configureDataSource 127.0.0.1
enableDataSource
configMybatis
configDaoManager
juju-log 'Finished configuring MariaDB datasource!'
