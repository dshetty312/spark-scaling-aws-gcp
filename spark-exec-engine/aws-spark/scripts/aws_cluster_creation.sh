#!/bin/sh
#######################################################################################
#File           : aws_cluster_creation.sh
#Description    : This script is used to validate the parameters passed and the 
# 		  pre-requisites available or not
#
#Usage          : sh aws_cluster_creation.sh <cluster_type> <config_file_name>
#                 ex: 1. sh aws_cluster_creation.sh emr /home/ec2-user/scee/config/aws_emr_config.txt
#		      2. sh aws_cluster_creation.sh eks /home/ec2-user/scee/config/aws_eks_config.txt
#Date Created   : 01/28/2019
#Author         : Naresh Babu M (Deloitt)
#######################################################################################
#Revision History
#-------------------------------------------------------------------------------------
#Sno            Modified By                     Description
#--------------------------------------------------------------------------------------
#1              Naresh Babu. M (Deloitt)        Initial Draft
#######################################################################################

echo " ******** Welcome to SCEE on AWS *********"

#--------------------------------------------------------------------------------------
# Checking no.of parameters passed
#-------------------------------------------------------------------------------------

if [ "$#" -ne 2 ]; then
  echo "You did not pass the correct no.of parameters. Please check and re-try"
  echo "Usage: sh aws_cluster_creation.sh <cluster_type> <config_file_name>
		 ex: 1. sh aws_cluster_creation.sh emr /home/ec2-user/scee/config/aws_emr_config.txt
                     2. sh aws_cluster_creation.sh eks /home/ec2-user/scee/config/aws_eks_config.txt"
  exit 1
fi

#---------------------------------------------------------------------------------------
# exporting variable and validating them
#---------------------------------------------------------------------------------------

export CLUSTER_TYPE=$1
export conf_file=$2
export AWS_HOME=`env | grep -i AWS_HOME | cut -d'=' -f2`
if [[ ${CLUSTER_TYPE} == 'emr' || ${CLUSTER_TYPE} == 'eks' ]]; then
	echo "Parameters looks good. Proceeding with remaining process...!!"
else
	echo "Cluster type should be \"emr\" or \"eks\" only"
	exit 1
fi

#---------------------------------------------------------------------------------------
#Checking Pre-requisites for EMR
#--------------------------------------------------------------------------------------

AWS_CLI_VERSION=`echo $(aws --version 2>&1)| cut -d ' ' -f1 | cut -d '/' -f2`
typeset -i  AWS_CLI_VER=`echo ${AWS_CLI_VERSION}|cut -d '.' -f1,2|tr -d .`

KUBECTL_VERSION=`kubectl version --short | grep -i "client" | cut -d ':' -f2 | cut -d 'v' -f2`
typeset -i KUBECTL_VER=`echo ${KUBECTL_VERSION}|cut -d '.' -f1,2|tr -d .`

if [[ ${CLUSTER_TYPE} == 'emr' ]]; then
	if [[ -z ${AWS_CLI_VERSION} ]]; then
		echo "***ERROR*** AWS CLI is not installed ***"
	        exit 1
	elif [[ ${AWS_CLI_VER} -le 115 ]]; then
		echo "***WARNING*** Looks like AWS CLI version ${AWS_CLI_VERSION} is old. Please update it"
	else
		echo "*** ALL Good..!! Calling the aws_emr_cluster.sh script"
	sh  ${AWS_HOME}/scripts/aws_emr_cluster.sh $conf_file
	fi
#----------------------------------------------------------------------------------------
#Checking Pre-requisites for EKS
#----------------------------------------------------------------------------------------
elif [[ ${CLUSTER_TYPE} == 'eks' ]]; then
        if [[ -z ${AWS_CLI_VERSION} ]]; then
                echo "***ERROR*** AWS CLI is not installed ***"
                exit 1
        elif [[ ${AWS_CLI_VER} -lt 116 ]]; then
                echo "***ERROR*** Looks like AWS CLI version ${AWS_CLI_VERSION} is old. Please update to 1.16 or higher to proceed"
		exit 1
        else
                echo "*** AWS CLI is Good..!! Proceeding..."
        fi

	if [[ -z ${KUBECTL_VERSION} ]]; then
		echo "***ERROR*** Kubernetes is not installed ***"
		exit 1
	elif [[ ${KUBECTL_VER} -lt 111 ]]; then
		echo "*** WARNING *** Kubectl need to be upgraded"
	else
		echo "*** Kubernetes is Good..!! Proceeding..."
	fi

	echo "Calling the EKS script for cluster creation"
	sh ${AWS_HOME}/scripts/aws_eks_cluster.sh $conf_file 

else
	echo "***ERROR*** Please select either emr or eks only****"
	exit 1
fi

#------------------------------------------------------------------------------------------
# Final Status
#------------------------------------------------------------------------------------------

export RC=$?

if [[ $RC == 0 ]];then
        echo "***************************************SUCCESS**********************************"
        exit ${RC}
else
        echo "***************************************FAILED***********************************"
        exit 1
fi
#############################################################################################
