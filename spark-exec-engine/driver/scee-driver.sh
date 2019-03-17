#Created by - Dikshith S Shetty(dishetty@deloitte.com)
#This is the driver program to support cluster creation ,job execution using spark and cluster deletion on Google Cloud platform and AWS.
#Based on the cloud vendor selected and parameter Managed or kuberenetes corresponding program will be invoked.

#Validate the arguments
if [ $# -ne 2 ]
then
   echo "Please provide the correct arguments.."
   echo ""
   echo "Please specify cloud vendor as GCP/AWS and job type as MANAGED or KUBERNETES"
   echo ""
   echo "Usage:$0 AWS/GCP MANAGED/KUBERNETES"
   exit 1
fi

export CLOUD_VENDOR=$1
export JOB_TYPE=$2


export CONF_PATH="../conf"

if [ ! -f ${CONF_PATH}/driver.properties ]
then
    echo "Properties file missing - driver.properties"
    exit 1
fi

echo "Source the driver.properties file"
source ${CONF_PATH}/driver.properties

echo "SCEE_HOME is set to $SCEE_HOME"
echo "GCP_HOME is set to $GCP_HOME"
echo "AWS_HOME is set to $AWS_HOME"
echo "SPARK_HOME is set to $SPARK_HOME"

if [ ${CLOUD_VENDOR} != "AWS" ] && [ ${CLOUD_VENDOR} != "GCP" ] 
then
   echo "Incorrect cloud vendor provided"
   echo "Please select AWS or GCP"
   exit 1
fi
echo "The cloud vendor provided is $CLOUD_VENDOR and job type provided  is :$JOB_TYPE"

if [ ${CLOUD_VENDOR} == "GCP" ]
then
    echo "Cloud vendor selected - $CLOUD_VENDOR"
    if [ ${JOB_TYPE} == "MANAGED" ]
    then
       echo "Running managed dataproc hadoop service on gcp.."
       ${GCP_HOME}/scripts/gcp-spark-dataproc.sh

     elif [ ${JOB_TYPE} == "KUBERNETES" ]
     then
       echo "Running kubernetes on gcp.."
       ${GCP_HOME}/scripts/gcp-spark-kubernetes.sh
     else
       echo "Incorrect Job type"
       exit 1
     fi
else
    echo "Cloud vendor selected - $CLOUD_VENDOR"
    if [ ${JOB_TYPE} == "MANAGED" ]
    then
       echo "Running managed emr on aws.."
       ${AWS_HOME}/scripts/aws_cluster_creation.sh emr ${AWS_HOME}/conf/aws_emr_cluster.config 
        
     elif [ ${JOB_TYPE} == "KUBERNETES" ]
     then
       echo "Running kubernetes(EKS) on aws.."
       ${AWS_HOME}/scripts/gcp-spark-kubernetes.sh eks ${AWS_HOME}/conf/aws_eks_cluster.config
     else
       echo "Incorrect Job type"
       exit 1
     fi
fi
