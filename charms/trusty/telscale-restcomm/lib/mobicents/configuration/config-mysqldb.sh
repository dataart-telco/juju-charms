#!/bin/bash
## Description: Enables and configures MySQL datasource
## Params:
## 			1. RESTCOMM_VERSION
## Author: Henrique Rosa

# IMPORTS
source lib/mobicents/utils/read-network-props.sh

# VARIABLES
RESTCOMM_HOME=/opt/restcomm
RESTCOMM_DEPLOY=$RESTCOMM_HOME/standalone/deployments/restcomm.war

## Description: Configures MyBatis for MySQL
## Parameters : none
configMybatis() {
	FILE=$RESTCOMM_DEPLOY/WEB-INF/conf/mybatis.xml
	
	grep -q '<environment id="mysql">' $FILE || sed -i '/<environments.*>/ a \
	\	<environment id="mysql">\
	\		<transactionManager type="JDBC"/>\
	\		<dataSource type="JNDI">\
	\			<property name="data_source" value="java:/MySqlDS" />\
	\		</dataSource>\
	\	</environment>\
	' $FILE
	
	sed -e '/<environments.*>/ s|default=".*"|default="mysql"|' $FILE > $FILE.bak
	mv $FILE.bak $FILE
	juju-log 'Activated mybatis environment for MySQL';
}

## Description: Configures MySQL Datasource
## Parameters : 1. Private IP
configureDataSource() {
	FILE=$RESTCOMM_HOME/standalone/configuration/standalone-sip.xml
	
	# Update DataSource
	sed -e "/<datasource jta=\"true\" jndi-name=\"java:\/MySqlDS\" .*>/ {
		s|<connection-url>.*</connection-url>|<connection-url>jdbc:mysql://$1:3306/restcomm</connection-url>|
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
	juju-log 'Updated MySQL DataSource Configuration'
}

configureMySQLDataSource() {
	FILE=$RESTCOMM_HOME/standalone/configuration/standalone-sip.xml
	
	# Update DataSource
	sed -e "s|<connection-url>.*</connection-url>|<connection-url>jdbc:mysql://$1:3306/telscale-restcomm</connection-url>|g" $FILE > $FILE.bak
	mv $FILE.bak $FILE	
	sed -e "s|<user-name>.*</user-name>|<user-name>$2</user-name>|g" $FILE > $FILE.bak
	mv $FILE.bak $FILE	
	sed -e "s|<password>.*</password>|<password>$3</password>|g" $FILE > $FILE.bak
	mv $FILE.bak $FILE		
	juju-log 'Updated MySQL DataSource Configuration'
}

## Description: Enables MySQL Datasource while disabling the remaining
## Parameters : none
enableDataSource() {
	FILE=$RESTCOMM_HOME/standalone/configuration/standalone-sip.xml
	
	# Disable all datasources but MySQL
	sed -e '/<datasource/ s|enabled="true"|enabled="false"|' \
	    -e '/<datasource.*MySqlDS/ s|enabled=".*"|enabled="true"|' \
	    $FILE > $FILE.bak
	
	mv $FILE.bak $FILE
	juju-log 'Enabled MySQL datasource'
}

## Description: Configures RestComm DAO manager to use MySQL
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
	juju-log 'Configured iBatis Dao Manager for MySQL'
}

# MAIN
juju-log 'Configuring MySQL datasource...'
#configureDataSource $PRIVATE_IP
#configureDataSource localhost
enableDataSource
configMybatis
configDaoManager
juju-log 'Finished configuring MySQL datasource!'
