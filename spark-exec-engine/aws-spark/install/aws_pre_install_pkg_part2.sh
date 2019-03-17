#!/bin/sh
#######################################################################################
#File           : aws_pre_install_pkg_part2.sh
#Description    : This script is used to install the pre-requisites required for SCEE on AWS
# 
#
#Usage          : sh aws_pre_install_pkg_part2.sh <output_file_name>
#                 ex: 1. sh aws_pre_install_pkg.sh </home/ec2_user/scee/config/SCEEMaster_config>
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

export private_res_ind=${1:-0}
export config_outputs=$2/SCEEMaster_config.output
export s_status="\"CREATE_IN_PROGRESS\""

if [[ $# -eq 0 ]]; then
	echo " Please give output file path as an input parameter"
	exit 1
fi

if [[ -z ${config_outputs} ]]; then
	echo "Config file already existing, Rename/delete it and execute again"
	exit 1
fi
########################################################################################
# CloudFormation Stack creation status check function
########################################################################################

fn_cft_stack_status_Query () {
        echo "*** Quering the Stack for Status......****"
        export s_name=$1
        export s_status=`aws cloudformation describe-stacks --stack-name "SCEEMaster" --query Stacks[0].StackStatus`
        echo "Status of SCEEMaster Cloud stack is ${s_status}"
        echo "*******************************************"
}

#######################################################################################
#Create aws-iam-authenticator for EKS creation
#######################################################################################

export AWS_AUTH_test=`aws-iam-authenticator help | grep -i 'Usage' `

if [[ -z ${AWS_AUTH_test} ]]; then
	echo " AWS IAM authenticator download and installation"
	`curl -o aws-iam-authenticator https://amazon-eks.s3-us-west-2.amazonaws.com/1.11.5/2018-12-06/bin/linux/amd64/aws-iam-authenticator`
	`chmod +x ./aws-iam-authenticator`
	`cp ./aws-iam-authenticator $HOME/bin/aws-iam-authenticator && export PATH=$HOME/bin:$PATH`
	echo 'export PATH=$HOME/bin:$PATH' >> ~/.shrc
	export AWS_AUTH_test=`aws-iam-authenticator help`

	RC_IAM_AUTH=$?

	if [[ ${RC_IAM_AUTH} -ne 0 ]]; then
		echo " AWS IAM authenticator download and installation failed"
		exit 1
	fi

	echo " AWS IAM authenticator download and installation successfully completed"
else
	echo " AWS IAM authenticator is already installed"
fi

#######################################################################################
# Creating SCEE cloud stack VPC/SG/SUBNETS if there is no private VPN specified
#######################################################################################

if [[ ${private_res_ind} -eq 0 ]]; then

    aws cloudformation create-stack --stack-name "SCEEMaster" --template-url "https://amazon-eks.s3-us-west-2.amazonaws.com/cloudformation/2019-02-11/amazon-eks-vpc-sample.yaml" --parameters ParameterKey="Subnet01Block",ParameterValue="192.168.64.0/18" ParameterKey="Subnet02Block",ParameterValue="192.168.128.0/18" ParameterKey="Subnet03Block",ParameterValue="192.168.192.0/18" ParameterKey="VpcBlock",ParameterValue="192.168.0.0/16" --capabilities "CAPABILITY_IAM"

    RC_CFT_SCEE=$?

    if [[ $RC_CFT_SCEE == 0 ]];then
        echo "***************************************SUCCESS**********************************"
	while :
        do
                if [[ ${s_status} == "\"CREATE_IN_PROGRESS\"" ]]; then
                        fn_cft_stack_status_Query ${worker_cluser_name}
                        sleep 50
                        continue
                elif [[ ${s_status} == "\"CREATE_COMPLETE\"" ]]; then
                        echo "${worker_cluser_name} stack created successfully" | tee -a ${config_outputs}
			export sec_grp=`aws cloudformation describe-stacks --stack-name "SCEEMaster" --query Stacks[0].Outputs[0].OutputValue`
			export vpc_id=`aws cloudformation describe-stacks --stack-name "SCEEMaster" --query Stacks[0].Outputs[1].OutputValue`
			export subnet_id=`aws cloudformation describe-stacks --stack-name "SCEEMaster" --query Stacks[0].Outputs[2].OutputValue`
			echo "***************************************************************************************" |  tee -a ${config_outputs}
			echo " Security Group Created for SCEEMaster CloudFormation stack is : ${sec_grp} " | tee -a ${config_outputs}
			echo " VPC created for SCEEMaster CloudFormation stack is : ${vpc_id} " | tee -a ${config_outputs}
			echo " subnets created for SCEEMaster CloudFormation stack is : ${subnet_id} " | tee -a ${config_outputs}
			echo "****************************************************************************************" | tee -a ${config_outputs}
                        break
                else
                        echo" ${worker_cluser_name} stack creation failed. Check AWS Console for more information"
                        exit 1
                fi
        done
	
    else
        echo "***************************************FAILED***********************************"
        exit 1
    fi
else
   echo "Please update the aws_eks_cluster.config file manually with your private VPC/SG/SUBNET details"
   exit 0
fi
#############################################################################################
