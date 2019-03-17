#####Please reach out to Dikshith Shetty(dishetty@deloitte.com) in case of any issues/questions.########

1.Download the spark execution engine package and unzip it.You should see something like this assuming the package was extracted in home directory.	

dikshithshetty312@gcp-edge-node:~/spark-exec-engine$ ls -ltr
total 20
drwxr-xr-x 2 dikshithshetty312 dikshithshetty312 4096 Feb 26 01:26 driver
drwxr-xr-x 2 dikshithshetty312 dikshithshetty312 4096 Feb 26 01:33 conf
drwxr-xr-x 2 dikshithshetty312 dikshithshetty312 4096 Feb 26 01:53 install
drwxr-xr-x 6 dikshithshetty312 dikshithshetty312 4096 Feb 26 01:53 gcp-spark
drwxr-xr-x 3 dikshithshetty312 dikshithshetty312 4096 Feb 26 01:56 aws-spark


2.Update the driver.properties in the spark-exec-engine/conf folder.Set SCEE_HOME to location where spark-exec-engine is installed.

For eg:If the zip is extracted in the home directory then the driver.properties can be updated as below:
       export SCEE_HOME=$HOME/spark-exec-engine
   
3. The folder gcp-spark hosts all the scripts and configuration required for gcp execution.aws-spark folder has all aws related scripts and configuration.
   
4. Install the common pre-requisites/dependency packages using install-packages.sh present in spark-exec-engine/install folder.GCP dependencies should be installed using install-gcp-packages.sh present in gcp-spark/install folder.

5.Install AWS packages using install-aws-packages.sh present in aws-spark/install folder.Please update SPARK_HOME to location where spark is installed in driver.properties present in SCEE_HOME/conf folder.

6.For running jobs on the cloud you need to have a account with the cloud vendor.Ensure that you have a active google cloud platform for using GCP services and Amazon web services account for using AWS services.

7.The scee-driver script is present in the driver folder.Execute the script by providing cloud vendor and job type.

For eg:
    a)For running managed spark instance on GCP run below command:
	 $SCEE_HOME/driver/scee-driver.sh GCP MANAGED
	 
	b)For running Kubernetes instance on AWS run below command:
	$SCEE_HOME/driver/scee-driver.sh AWS KUBERNETES
	
	
8.For setting up the environment on GCP follow README-GCP.txt present under SCEE_HOME folder

9.For setting up the environment on AWS follow README-AWS.txt present under SCEE_HOME folder



	 
