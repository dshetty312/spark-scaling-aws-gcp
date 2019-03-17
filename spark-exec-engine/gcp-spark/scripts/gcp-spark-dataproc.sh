#!/bin/bash
##Created by - Dikshith Shetty - 01/17/2019
##This script is for running a spark job on dataproc cluster.It creates a dataproc cluster,submits a spark job and deletes the cluster.

export SPARK_HOME=`env | grep -i SPARK_HOME | cut -d'=' -f2`
export GCP_HOME=`env | grep -i GCP_HOME | cut -d'=' -f2`
export GCP_CONF=${GCP_HOME}/conf

echo "GCP_HOME is set to $GCP_HOME"
echo "SPARK_HOME is set to $SPARK_HOME"

echo "Reading the config file for dataproc.."
source ${GCP_CONF}/dataproc.properties


#Dataproc cluster creation
echo "Creating a dataproc cluster with the configuration provided.."
DATAPROC_START_TIME=$SECONDS
gcloud dataproc clusters create $CLUSTER_NAME \
	  --region $REGION \
	    --zone $ZONE \
	      --master-machine-type $MACHINE_TYPE_LARGE \
	        --master-boot-disk-size 500 \
		  --num-workers $NUM_WORKERS \
		    --worker-machine-type $WORKER_MACHINE_TYPE \
		      --worker-boot-disk-size 500 \
			  --project $PROJECT

if [ $? -eq 0 ]; then
   echo "Dataproc cluster $CLUSTER_NAME created successfully in region $REGION.."
else
   echo "Failure encountered while creating dataproc cluster $CLUSTER_NAME in region $REGION.."
   exit 1
fi

DATAPROC_TIME=$(($SECONDS - $DATAPROC_START_TIME))

#Spark job submission to the dataproc cluster
echo "Submitting spark job to gcp dataproc cluster.."

START_TIME=$SECONDS
gcloud dataproc jobs submit spark \
	  --region $REGION \
	    --cluster $CLUSTER_NAME \
	      --class $MAIN_CLASS \
	        --jars gs://spark-input/${SPARK_ETL_JAR} -- 1000


if [ $? -eq 0 ]; then
   echo "Spark job completed successfully.."
else
    echo "Failure encountered during spark job.."
    exit 1
fi
ELAPSED_TIME=$(($SECONDS - $START_TIME))


###Deleting the dataproc cluster
echo "Deleting the dataproc cluster - $CLUSTER_NAME"

DEL_TIME_START=$SECONDS
yes | gcloud dataproc clusters delete $CLUSTER_NAME --region $REGION
DEL_TIME=$(($SECONDS - $DEL_TIME_START))

echo ""

echo "**************************************************"
echo "Statistics for the job:"
echo "Dataproc cluster creation time:$DATAPROC_TIME secs"
echo "Spark job execution time : $ELAPSED_TIME secs"
echo "Dataproc cluster deletion time:$DEL_TIME secs"
echo "**************************************************"

