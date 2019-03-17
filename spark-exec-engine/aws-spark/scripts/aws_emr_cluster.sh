#!/bin/sh
#######################################################################################
#File 		: aws_emr_cluster_creation.sh
#Description    : This script is used to create the AWS EMR cluster based on the 
#		  selection of cloud and clouster type on main script from user.
#
#Usage 		: sh aws_emr_cluster.sh <config_file_name> 
#	          ex: sh aws_emr_cluster.sh /home/ec2-user/scee/config/aws_emr_config.txt
#
#Date Created   : 01/20/2019
#Author         : Naresh Babu M (Deloitt)
#######################################################################################
#Revision History  
#-------------------------------------------------------------------------------------
#Sno		Modified By			Description
#--------------------------------------------------------------------------------------
#1		Naresh Babu. M (Deloitt)	Initial Draft 
#######################################################################################

########################################################################################
# AWS EMR Cluster creation
########################################################################################

echo "Hi, We are Creating AWS EMR Cluster here"
export config_file_path=$1

#--------------------------------------------------------------------------------------
# Checking no.of parameters passed
#-------------------------------------------------------------------------------------

if [ "$#" -ne 1 ]; then
  echo "You did not pass the configuration file path"
  echo "Usage: sh aws_emr_cluster.sh <config_file_name>"
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

source $config_file_path

#--------------------------------------------------------------------------------------
# Creating all required input json
#--------------------------------------------------------------------------------------

export ec2_attributes_json="{\"KeyName\":\"${KeyName}\",\"InstanceProfile\":\"${InstanceProfile}\",\"SubnetId\":\"${SubnetId}\",\"EmrManagedSlaveSecurityGroup\":\"${EmrManagedSlaveSecurityGroup}\",\"EmrManagedMasterSecurityGroup\":\"${EmrManagedMasterSecurityGroup}\"}"

export steps_json="[{\"Args\":[\"spark-submit\",\"--deploy-mode\",\"cluster\",\"--class\",\"${class}\",\"--conf\",\"spark.executor.instances=5\",\"--executor-memory\",\"500M\",\"s3://${jar}\",\"100\"],\"Type\":\"CUSTOM_JAR\",\"ActionOnFailure\":\"CONTINUE\",\"Jar\":\"command-runner.jar\",\"Properties\":\"\",\"Name\":\"Spark_application\"}]"

export ebs_config_json="\"EbsConfiguration\":{\"EbsBlockDeviceConfigs\":[{\"VolumeSpecification\":{\"SizeInGB\":32,\"VolumeType\":\"gp2\"},\"VolumesPerInstance\":1}]}"

export instance_groups_json="[{\"InstanceCount\":2,${ebs_config_json},\"InstanceGroupType\":\"CORE\",\"InstanceType\":\"${InstanceType}\",\"Name\":\"Core_Instance_Group\"},{\"InstanceCount\":1,${ebs_config_json},\"InstanceGroupType\":\"MASTER\",\"InstanceType\":\"${InstanceType}\",\"Name\":\"Master_Instance_Group\"}]"

export configuration_json="[{\"Classification\":\"spark\",\"Properties\":{\"maximizeResourceAllocation\":\"true\"},\"Configurations\":[]}]"

echo "ec2_attributes_json:: $ec2_attributes_json"
echo "steps_json::$steps_json"
echo "ebs_config_json::$ebs_config_json"
echo "instance_groups_json::$instance_groups_json"
echo "configuration_json::$configuration_json"

########################################################################################
# Creating  the cluster and running the jobs.
########################################################################################

export main_job=`echo aws emr create-cluster --applications ${applications} --ec2-attributes ${ec2_attributes_json} --release-label ${EMR_version} --log-uri "s3n://emrstepexeclogs/" --steps ${steps_json} --instance-groups ${instance_groups_json} --configurations ${configuration_json} --auto-terminate --auto-scaling-role EMR_AutoScaling_DefaultRole --ebs-root-volume-size 10 --service-role ${servicerole} --enable-debugging --name \'${name}\' --scale-down-behavior TERMINATE_AT_TASK_COMPLETION --region ${region}`

echo $main_job

#$main_job

export cluster_id=`$main_job`
echo $cluster_id
export c_id=`echo ${cluster_id} | cut -d ':' -f2 | cut -d '}' -f1| sed -e 's/"//g'`
echo ${c_id}

########################################################################################
#Checking the status and closing the job execution
########################################################################################

export RC=$?

if [[ $RC == 0 ]]; then
	echo "****SUCCESS*** JOB completed EMR:Cluser ${name} is running with id ${cluster_id}"
	while :
	do
	export cluster_stat1=`aws emr describe-cluster --cluster-id ${c_id} --query Cluster.Status.State`
	export cluster_stat2=`aws emr describe-cluster --cluster-id ${c_id} --query Cluster.Status.StateChangeReason.Code`
	export cluster_stat=${cluster_stat1}${cluster_stat2}
	echo ${cluster_stat1}${cluster_stat2}${cluster_stat}
		if [[ ${cluster_stat} == "\"TERMINATED\"\"ALL_STEPS_COMPLETED\"" ]]; then
			echo "All Steps Successfully completed..Cluster Terminated"
			exit 0
			break
		elif [[ ${cluster_stat1} == "\"TERMINATED\"" ]]; then
			echo "Cluster terminated with errors"
			exit 1
		else
			echo "Cluster is ${cluster_stat1}........."
			sleep 60
			continue
		fi
	done
else
	echo "****FAILED*** PLEASE RE_RUN the job by enabling debug parameter to know the issue"
	exit 1
fi
#############################################################################################
