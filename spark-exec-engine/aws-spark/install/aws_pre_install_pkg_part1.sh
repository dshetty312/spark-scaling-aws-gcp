#!/bin/sh
#######################################################################################
#File           : aws_pre_install_pkg.sh
#Description    : This script is used to install the pre-requisites required for SCEE on AWS
# 
#
#Usage          : sh aws_pre_install_pkg.sh
#                 ex: 1. sh aws_pre_install_pkg.sh
#Date Created   : 02/25/2019
#Author         : Naresh Babu M (Deloitt)
#######################################################################################
#Revision History
#-------------------------------------------------------------------------------------
#Sno            Modified By                     Description
#--------------------------------------------------------------------------------------
#1              Naresh Babu. M (Deloitt)        Initial Draft
#######################################################################################

echo " ******** Welcome to SCEE on AWS *********"

#---------------------------------------------------------------------------------------
#Checking Pre-requisites for EMR
#--------------------------------------------------------------------------------------

AWS_CLI_VERSION=`echo $(aws --version 2>&1)| cut -d ' ' -f1 | cut -d '/' -f2`
typeset -i  AWS_CLI_VER=`echo ${AWS_CLI_VERSION}|cut -d '.' -f1,2|tr -d .`

KUBECTL_VERSION=`kubectl version --short | grep -i "client" | cut -d ':' -f2 | cut -d 'v' -f2`
typeset -i KUBECTL_VER=`echo ${KUBECTL_VERSION}|cut -d '.' -f1,2|tr -d .`

#----------------------------------------------------------------------------------------
#Checking Pre-requisites for installation
#----------------------------------------------------------------------------------------
if [[ -z ${AWS_CLI_VERSION} ]]; then
	echo " *** AWS CLI is not Found ***"
        echo " *** Proceeding for AWS CLI installation ***"
	`pip install awscli --upgrade --user`
	RC_AWS_CLI=$?
elif [[ ${AWS_CLI_VER} -lt 116 ]]; then
        echo "***ERROR*** Looks like AWS CLI version ${AWS_CLI_VERSION} is old. Please update to 1.16 or higher to proceed"
	echo " *** Proceeding for AWS CLI installation ***"
	`pip install awscli --upgrade --user`
	RC_AWS_CLI=$?
else
        echo "*** AWS CLI is Good..!! Proceeding..."
fi

if [[ -z ${KUBECTL_VERSION} ]]; then
	echo "*** Kubernetes is not Found ***"
	echo "*** Proceeding with installation ***"
	`curl -o kubectl https://amazon-eks.s3-us-west-2.amazonaws.com/1.11.5/2018-12-06/bin/linux/amd64/kubectl`
	`chmod +x ./kubectl`
	`mkdir $HOME/bin && cp ./kubectl $HOME/bin/kubectl && export PATH=$HOME/bin:$PATH`
	echo 'export PATH=$HOME/bin:$PATH' >> ~/.shrc
	RC_KUBECTL_CLI=$?
elif [[ ${KUBECTL_VER} -lt 111 ]]; then
	echo "*** WARNING *** Kubectl need to be upgraded"
else
	echo "*** Kubernetes is Good..!! Proceeding..."
fi


#------------------------------------------------------------------------------------------
# Final Status
#------------------------------------------------------------------------------------------

if [[ $RC_AWS_CLI == 0 && $RC_KUBECTL_CLI == 0 ]];then
        echo "***************************************SUCCESS**********************************"
        exit 0
else
        echo "***************************************FAILED***********************************"
        exit 1
fi
#############################################################################################
