#!/bin/bash
##Created by - Dikshith Shetty - 01/17/2019
##This script will create a kubernetes cluster ,submit a spark job and tear down the cluster

export SPARK_HOME=`env | grep -i SPARK_HOME | cut -d'=' -f2`
export GCP_HOME=`env | grep -i GCP_HOME | cut -d'=' -f2`
export GCP_CONF=${GCP_HOME}/conf

echo "GCP_HOME is set to $GCP_HOME"
echo "SPARK_HOME is set to $SPARK_HOME"

echo "Reading the config file for kubernetes.."
source ${GCP_CONF}/kubernetes.properties

#Kubernetes cluster creation
echo "Creating a kubernetes cluster with the configuration provided.. - ${GCP_CONF}/kubernetes.properties"
KUBERNETES_START_TIME=$SECONDS

gcloud container clusters create $CLUSTER_NAME --machine-type $MACHINE_TYPE --num-nodes $NUM_OF_NODES --enable-autoscaling --min-nodes $MIN_NUM_WORKERS --max-nodes $MAX_NUM_WORKERS --zone $ZONE

if [ $? -eq 0 ]; then
   echo "Kubernetes cluster $CLUSTER_NAME created successfully in zone $ZONE.."
else
   echo "Failure encountered while creating kubernetescluster $CLUSTER_NAME in zone $ZONE.."
   exit 1
fi

KUBERNETES_TIME=$(($SECONDS - $KUBERNETES_START_TIME))

#Add permissions for spark to be able to launch jobs in kubernetes cluster
#This might need sudo permissions
gcloud container clusters get-credentials $CLUSTER_NAME --zone $ZONE

sudo kubectl create clusterrolebinding user-admin-binding --clusterrole=cluster-admin --user=$(gcloud config get-value account);
sudo kubectl create clusterrolebinding --clusterrole=cluster-admin --serviceaccount=default:default spark-admin;

if [ $? -eq 0 ]; then
   echo "Spark permissions added successfully for kubernetes.."
else
    echo "Failure encountered while adding spark permissions in kubernetes"
    exit 1
fi

#create kubernetes master variable
export KUBERNETES_MASTER_IP=$(gcloud container clusters list --filter name=$CLUSTER_NAME --format='value(MASTER_IP)');

#Spark job submission to the kubernetes cluster
echo "Submitting spark job to gcp kubernetes cluster.."

START_TIME=$SECONDS
$SPARK_HOME/bin/spark-submit --deploy-mode cluster --class $MAIN_CLASS --master k8s://https://$KUBERNETES_MASTER_IP:443 --conf spark.kubernetes.container.image=gcr.io/cloud-solutions-images/spark:v2.3.0-gcs gs://spark-input/${SPARK_ETL_JAR}  -- 1000 

if [ $? -eq 0 ]; then
   echo "Spark job completed successfully.."
else
    echo "Failure encountered during spark job.."
    exit 1
fi
ELAPSED_TIME=$(($SECONDS - $START_TIME))


###Deleting the kubernetes cluster
echo "Deleting the kubernetes cluster - $CLUSTER_NAME"

DEL_TIME_START=$SECONDS

yes | gcloud container clusters delete $CLUSTER_NAME --zone $ZONE;

DEL_TIME=$(($SECONDS - $DEL_TIME_START))

echo ""

echo "**************************************************"
echo "Statistics for the job:"
echo "Kubernetes cluster creation time:$KUBERNETES_TIME secs"
echo "Spark job execution time : $ELAPSED_TIME secs"
echo "Kubernetes cluster deletion time:$DEL_TIME secs"
echo "**************************************************"

