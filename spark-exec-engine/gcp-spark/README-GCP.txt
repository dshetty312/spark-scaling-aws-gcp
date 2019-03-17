  #####Please reach out to Dikshith Shetty(dishetty@deloitte.com) in case of any issues/questions.########
  
  1)Run the gcp installer script(install-gcp-packages.sh) present in GCP_HOME/install folder.Run the following commands once gcloud sdk is installed .
   
       gcloud init
       gcloud config set project [PROJECT_ID] .Here is the project created in gcp
  
  2)Update dataproc.properties for running jobs on dataproc and kubernetes.properties for GKE instance.Update the project name accordingly in properties.
  
  3)Create gs bucket spark-input using create-gcp-bucket.sh and copy SparkPi jar to gs bucket.The script is prsent in GCP_HOME/scripts.

  4)Default machine configuration and job configuration are specified in dataproc.properties and kubernetes.properties.

    
	For eg: dataproc.properties
	
	export PROJECT=gcp-dataproc-dikshith
	export REGION=us-east1
	export CLUSTER_NAME=dataproc-spark-test
	export MAIN_CLASS=org.apache.spark.examples.SparkPi 
        export SPARK_ETL_JAR=spark-examples_2.11-2.3.2.jar
	export REGION=us-east1
	export ZONE=us-east1-b
	export NUM_WORKERS=3
	export MACHINE_TYPE_LARGE=n1-standard-2
	export WORKER_MACHINE_TYPE=n1-standard-1
	
	Note:
	-PROJECT             -> Once you create a gcp account you need to create a project.Sample project name given here.
	-REGION              -> Geographical location which consists of many zones.
	-ZONE                -> A Physical data center within a region.
	-CLUSTER_NAME        -> A sample name given to the cluster.
	-NUM_WORKERS         -> Number of worker nodes.
	-MACHINE_TYPE_LARGE  -> 2vCPUs and 7.5 gb memory.
	-WORKER_MACHINE_TYPE -> 1vCPU and 3.75 gb memory.
        -MAIN_CLASS          -> The entry point for your application: for example, org.apache.spark.examples.SparkPi.
        -SPARK_ETL_JAR       -> Sample Spark pi jar present in gs bucket. 
