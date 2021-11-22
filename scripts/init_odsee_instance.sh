#!/bin/bash
# ---------------------------------------------------------------------------
# Trivadis AG, Infrastructure Managed Services
# Saegereistrasse 29, 8152 Glattbrugg, Switzerland
# ---------------------------------------------------------------------------
# Name.......: create_oud_instance.sh 
# Author.....: Stefan Oehrli (oes) stefan.oehrli@trivadis.com
# Editor.....: Stefan Oehrli
# Date.......: 2017.12.04
# Revision...: 
# Purpose....: Helper script to create the OUD instance 
# Notes......: Script to create an OUD instance. If configuration files are
#              provided, the will be used to configure the instance.
# Reference..: --
# License....: Licensed under the Universal Permissive License v 1.0 as 
#              shown at http://oss.oracle.com/licenses/upl.
# ---------------------------------------------------------------------------
# Modified...: 
# see git revision history for more information on changes/updates
# -----------------------------------------------------------------------
# - Environment Variables -----------------------------------------------
# - Set default values for environment variables if not yet defined. 
# -----------------------------------------------------------------------
# Default name for ODSEE instance
export ODSEE_INSTANCE=${ODSEE_INSTANCE:-dsDocker}

# ODSEE instance base directory
export OUD_INSTANCE_BASE=${OUD_INSTANCE_BASE:-"$ORACLE_DATA/instances"}

# ODSEE instance home directory
export ODSEE_INSTANCE_HOME=${OUD_INSTANCE_BASE}/${ODSEE_INSTANCE}
export ODSEE_HOME=${ORACLE_BASE}/product/${ORACLE_HOME_NAME}
export OUD_INSTANCE_HOME=${ODSEE_INSTANCE_HOME}

# Default values for the instance home and admin directory
export OUD_INSTANCE_ADMIN=${OUD_INSTANCE_ADMIN:-${ORACLE_DATA}/admin/${ODSEE_INSTANCE}}

# Default values for host and ports
export HOST=$(hostname 2>/dev/null ||cat /etc/hostname ||echo $HOSTNAME)   # Hostname
export PORT=${PORT:-1389}                               # Default LDAP port
export PORT_SSL=${PORT_SSL:-1636}                       # Default LDAPS port
export ADS_PORT=${ADS_PORT:-3998}                       # Default ads port
export ADS_PORT_SSL=${ADS_PORT_SSL:-3999}               # Default adsS port 
export AGENT_PORT=${AGENT_PORT:-3997}                   # Default agent port
export ADS_HOST=${ADS_HOST:-127.0.0.1}                      

# Default value for the directory
export ADMIN_USER=${ADMIN_USER:-'cn=Directory Manager'} # Default directory admin user
export PWD_FILE=${PWD_FILE:-${OUD_INSTANCE_ADMIN}/etc/${ODSEE_INSTANCE}_pwd.txt}

echo "admin file path: ${PWD_FILE}"
echo "--- check ads status -------------"
# check if dse.ldif does exists
if [ -d ${ODSEE_HOME}/var/dcc/ads ]; then
    # ads 
    echo "ads is ok"
    ${ODSEE_HOME}/bin/dsadm start ${ODSEE_HOME}/var/dcc/ads
else
    # create ads
    echo "---------------------------------------------------------------"
    echo "   create ads "
    echo "---------------------------------------------------------------"
    # dsccsetup prepare
    ${ODSEE_HOME}/bin/dsccsetup prepare-patch -i
    ${ODSEE_HOME}/bin/dsccsetup complete-patch -i
    # ads create 
    ${ODSEE_HOME}/bin/dsccsetup ads-create -w ${PWD_FILE} -p ${ADS_PORT} -P ${ADS_PORT_SSL} -i
    # create war file
    ${ODSEE_HOME}/bin/dsccsetup war-file-create

fi

# create agent
echo "---------------------------------------------------------------"
echo "   start create or start dscc agent "
echo "---------------------------------------------------------------"

if [ -d ${ODSEE_HOME}/var/dcc/agent ]; then
    # agent start 
    # register agent
    ${ODSEE_HOME}/bin/dsccreg add-agent -h ${ADS_HOST} -p ${ADS_PORT} -G ${PWD_FILE} -w ${PWD_FILE} -i
    echo "dscc agent is ok , start it"
    ${ODSEE_HOME}/bin/dsccagent start
    ${ODSEE_HOME}/bin/dsccagent info
else
    echo "dscc agent is not ok, create it"
    # create agent
    ${ODSEE_HOME}/bin/dsccagent create -w ${PWD_FILE} -p ${AGENT_PORT} -i
    # register agent
    echo "${ODSEE_HOME}/bin/dsccreg add-agent -h ${ADS_HOST} -p ${ADS_PORT} -G ${PWD_FILE} -w ${PWD_FILE} -i"
    ${ODSEE_HOME}/bin/dsccreg add-agent -h ${ADS_HOST} -p ${ADS_PORT} -G ${PWD_FILE} -w ${PWD_FILE} -i
    # agent start yum
    ${ODSEE_HOME}/bin/dsccagent start
    ${ODSEE_HOME}/bin/dsccagent info
fi


# create agent
echo "---------------------------------------------------------------"
echo "   start check tomcat "
echo "---------------------------------------------------------------"
if [ -f ${TOMCAT_ROOT}/webapps/dscc7.war ]; then
    # start tomcat 
    echo "   start tomcat "
    sh ${TOMCAT_ROOT}/bin/startup.sh
else
    echo "   start copy tomcat and start tomcat"
    # copy war
    cp ${ODSEE_HOME}/var/dscc7.war ${TOMCAT_ROOT}/webapps
    # start tomcat
    chmod +x ${TOMCAT_ROOT}/bin/*.sh
    sh ${TOMCAT_ROOT}/bin/startup.sh
fi