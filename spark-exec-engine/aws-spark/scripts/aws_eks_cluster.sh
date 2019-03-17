#!/bin/sh
#########################################################################################################################################
#File 		: aws_eks_cluster_creation.sh												#
#Description    : This script is used to create the AWS EKS cluster based on the 							#	
#		  selection of cloud and clouster type on main script from user.							#
#																	#
#Pre-requisites : 1. AWS EKS Role with EKS Creation permission										#
#		    Referece:  https://docs.aws.amazon.com/eks/latest/userguide/getting-started.html#eks-prereqs			#
#		  2. Create your Amazon EKS Cluster VPC with required SubnetID's							#
#		    Reference: https://docs.aws.amazon.com/eks/latest/userguide/getting-started.html#eks-prereqs			#
#		  3. Install Kubectl on the client from where we are triggering the Spark-submit command.				#
#		  4: Assuming AWS CLI is installed on client										#
#		  5. Download and install AWS iam-authenticator for AWS EKS								#
#		    Reference: https://docs.aws.amazon.com/eks/latest/userguide/getting-started.html#eks-prereqs			#
#																	#
#Usage 		: sh aws_eks_cluster.sh <config_file_name> 										#
#	          ex: sh aws_eks_cluster.sh /home/ec2-user/scee/config/aws_eks_config.txt						#
#																	#
#Date Created   : 01/28/2019														#
#Author         : Naresh Babu M (Deloitt)												#
#########################################################################################################################################
#Revision History  
#----------------------------------------------------------------------------------------------------------------------------------------
#Sno		Modified By			Description
#----------------------------------------------------------------------------------------------------------------------------------------
#1		Naresh Babu. M (Deloitt)	Initial Draft 
#########################################################################################################################################

#########################################################################################################################################
# AWS EKS Cluster creation
#########################################################################################################################################

echo "Hi, We are Creating AWS EKS Cluster here"
export SPARK_HOME=`env | grep -i SPARK_HOME | cut -d'=' -f2`
export config_file_path=$1

#--------------------------------------------------------------------------------------
# Checking no.of parameters passed
#-------------------------------------------------------------------------------------

if [ "$#" -ne 1 ]; then
  echo "You did not pass the configuration file path or invalid no.of parameters are passed"
  echo "Usage: sh aws_eks_cluster.sh <config_file_name>"
  exit 1
fi

#--------------------------------------------------------------------------------------
# Validating provided configration file
#-------------------------------------------------------------------------------------

if [[ ! -s $config_file_path ]]; then
   echo "$config_file_path provided is empty. Can't proceed with empty parameters. Exiting..!"
   exit 1
fi

#--------------------------------------------------------------------------------------
# read config file and sourcing the parameters
#-------------------------------------------------------------------------------------

echo `cat $config_file_path`

export CLUSTER_STATUS="\"CREATING\""
export s_status="\"CREATE_IN_PROGRESS\""
source $config_file_path

#--------------------------------------------------------------------------------------
# Define Cluster Status Function. Get the status
#-------------------------------------------------------------------------------------

fn_Clster_Status_Query () {
	echo "**** Quering Cluster for Status....... ****"
	export c_name=$1
	export CLUSTER_STATUS=`aws eks describe-cluster --name ${c_name} --query cluster.status`
	echo "${name} is ${CLUSTER_STATUS}"
	echo "*******************************************"
}

fn_cft_stack_status_Query () {
	echo "*** Quering the Stack for Status......****"
	export s_name=$1
	export s_status=`aws cloudformation describe-stacks --stack-name ${s_name} --query Stacks[0].StackStatus`
	echo "Status of ${s_name} is ${s_status}"
	echo "*******************************************"
}

########################################################################################
# Creating EKS cluster with the parameters given in config file
########################################################################################

aws eks create-cluster --name ${name} --role-arn ${role} --resources-vpc-config subnetIds=${subnetIds},securityGroupIds=${securityGroupIds}

export RC_CC=$?

if [[ $RC_CC == 0 ]];then
	while :
	do
		if [[ ${CLUSTER_STATUS} == "\"CREATING\"" ]]; then
			fn_Clster_Status_Query ${name}
			sleep 60
			continue
		elif [[ ${CLUSTER_STATUS} == "\"ACTIVE\"" ]]; then
			echo "${name} cluster created successfully"
			break
		else
			echo ${CLUSTER_STATUS}
			echo" ${name} cluster creation failed. Check AWS Console for more information"
			exit 1
		fi
	done
else
	echo "Cluster Creation Failed. Command executed is:"
	echo "aws eks create-cluster --name ${name} --role-arn ${role} --resources-vpc-config subnetIds=${subnetIds},securityGroupIds=${securityGroupIds}"
fi

########################################################################################
# Creating config file to connect to the Kubernetes cluster through Kubectl
########################################################################################

aws eks update-kubeconfig --name ${name}

export RC_UC=$?

if [[ $RC_UC == 0 ]];then
	echo "Config file created"
	cat ~/.kube/config
else
	echo "Config file creation has an issue"
	exit 1
fi

########################################################################################
# kubectl get svc
########################################################################################

kubectl get svc

########################################################################################
# Worker CFT Stack creation
########################################################################################

echo "Calling CloudFormation create-stack"

aws cloudformation create-stack --stack-name ${worker_cluser_name} --template-url ${worker_stack_cft} --parameters ParameterKey="NodeGroupName",ParameterValue=${NodeGroupName} ParameterKey="ClusterControlPlaneSecurityGroup",ParameterValue=${securityGroupIds} ParameterKey="KeyName",ParameterValue=${KeyName} ParameterKey="NodeImageId",ParameterValue=${NodeImageId} ParameterKey="Subnets",ParameterValue=${subnetIds_escape_comma}  ParameterKey="VpcId",ParameterValue=${VpcId} ParameterKey="ClusterName",ParameterValue=${worker_cluser_name} --capabilities "CAPABILITY_IAM"

export RC_WC=$?

if [[ $RC_WC == 0 ]];then
        echo "Stack Provision is in progress."
        while :
	do
                if [[ ${s_status} == "\"CREATE_IN_PROGRESS\"" ]]; then
                        fn_cft_stack_status_Query ${worker_cluser_name}
			sleep 60
			continue
                elif [[ ${s_status} == "\"CREATE_COMPLETE\"" ]]; then
                        echo "${worker_cluser_name} stack created successfully"
                        break
                else
                        echo" ${worker_cluser_name} stack creation failed. Check AWS Console for more information"
			exit 1
                fi
        done
else
        echo "Stack Creation has few issues...!!!"
        exit 1
fi

export s_node_instance_role_arn=`aws cloudformation describe-stacks --stack-name ${worker_cluser_name} --query Stacks[0].Outputs[0].OutputValue`
export yaml_config="${AWS_HOME}/conf"

cat ${yaml_config}/aws-auth-cm_yaml.config | sed "s|<ARN>|${s_node_instance_role_arn}|g" > ${yaml_config}/aws-auth-cm.yaml

kubectl apply -f ${yaml_config}/aws-auth-cm.yaml

export nodes=`kubectl get nodes`

echo $nodes

nohup kubectl proxy > ${yaml_config}/proxy_nohup.dat 2>&1 &
export proxy_open=$!
echo ${proxy_open}

#######################################################################################
# Run the Spark job 
#######################################################################################

echo $SPARK_HOME
cd $SPARK_HOME

echo "./bin/spark-submit --master k8s://http://127.0.0.1:8001 --deploy-mode cluster --name ${APP_NAME} --class ${APP_CLASS_NAME} ${config_params} ${APP_JAR} ${APP_PARAM}"

./bin/spark-submit --master k8s://http://127.0.0.1:8001 --deploy-mode cluster --name ${APP_NAME} --class ${APP_CLASS_NAME} ${config_params} ${APP_JAR} ${APP_PARAM}

export RC_SJ=$?

if [[ $RC_SJ == 0 ]];then
        echo "****SUCCESS*** SPARK JOB Executed successfully"
	`kill -9 ${proxy_open}`  ##proxy close
	aws eks delete-cluster --name ${name}
	sleep 60
	fn_Clster_Status_Query ${name}
else
        echo "****FAILED*** PLEASE RE_RUN the job by enabling debug parameter to know the issue"
	`kill -9 ${proxy_open}`  ##proxy close
        exit 1
fi


########################################################################################
#Checking the status and closing the job execution
########################################################################################

export RC=$?

if [[ $RC == 0 ]];then
	echo "****SUCCESS*** JOB completed EKS:Cluser ${name} is being destroyed. Current status is "
	exit 0
else
	echo "****FAILED*** PLEASE RE_RUN the job by debugging step by step"
	exit 1
fi
#############################################################################################
