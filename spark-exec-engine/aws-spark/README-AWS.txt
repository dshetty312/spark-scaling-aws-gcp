
Pre-Requisites Package execution Steps for Spark cloud execution engine on AWS.

1. Extract the tar ball provided. 

2. Execute the General pre-requisites package. This will check the availability of JAVA,PYTHON,PIP and some basic general utilities required irrespective of the cloud choice. 

3. If your choose cloud type AWS, then you need to execute the package aws_pre_install_pkg_part1.ksh. This script does not require any parameters. 
	a. This script verifies if AWS and Kubernetes are installed in your system. If not it will go ahead and install the applications.
	b. This also verifies if the version of the installed AWS/Kubectl are expected ones for SCEE. For the earlier versions a warning message will be displayed.

4. After the successful execution of aws_pre_install_pkg_part1.ksh, you need to configure AWS credentials and region in your client system using the below command.
	[ec2-user@ip-172-31-23-41 ~]$ aws configure
	AWS Access Key ID [****************EWHA]:       <Access_Key will be generated when you create a user in AWS IAM console>
	AWS Secret Access Key [****************LFNS]:   <Secret_key will be generated when you create a user in AWS IAM console>
	Default region name [us-east-1]:				<Please give the exact name of region looking at AWS console>
	Default output format [None]:     				< you can leave blank if you dont want to update this parameter.
	
5. After aws is configured you can verify connection by executing "aws s3 ls" command which should give the list of buckets available in S3.

6. If you have all steps executed successfully, please run the aws pre-installation package part-2 using script aws_pre_install_pkg_part2.ksh with the parameters choice of private resources{1/0}, file path
	a. This script create iam_authenticator.
	b. Also this script creates a Cloudformation Stack with name SCEEMaster which is designed to create a VPC,subnetIds,securitygroup. If you have project specific VPC,SubnetIDs,SecurityGroup Please provide 1 as first parameter to skip creation of cloudformation stack.
	
7. A Role need to be created before Proceeding with next actions. You can create Role with required EKS policies as mentioned in the below link.
   https://docs.aws.amazon.com/eks/latest/userguide/getting-started.html#role-create
   
8. Verify the installations through below commands.
	aws --version   <For AWS CLI installation check and to find the Version of AWS CLI>
	kubectl version <For Kubectl installation check and to find the version of kubectl>
	

AWS_EMR_Cluster_Creation (Using Native AWS Cluster confirgurations):

1. Please update the config file located in scee/config/aws_emr_cluster.config with the values as per your cloud configuration and requirements.

export applications="Name=Hadoop Name=Spark"   								<Application Names>
export KeyName="EKSDemo"													<Name of the Key-Pair if you do not have one or leave it empty>
export InstanceProfile="EMR_EC2_DefaultRole"                                <EMR_EC2_Role if you do not have one leave it EMR_EC2_DefaultRole>
export SubnetId="subnet-46b8e122"											<Create or get your Default SubnetID and keep it here>
export EmrManagedSlaveSecurityGroup="sg-0da5425887ee5aa7f"					<Create or get your default security group and keep it here>
export EmrManagedMasterSecurityGroup="sg-04d0134143b871d41"					<Create or get your default security group and keep it here>
export EMR_version="emr-5.17.0"												<Select EMR version out of the list of EMR versions available>
export class="org.apache.spark.examples.SparkPi"							<Give the class Name of the application you want to execute>
export jar="dynamicclustersparkdemo/code/spark/spark-examples_2.11-2.3.2.jar"<Give the s3 location of the jar file without s3:// prefix>
export InstanceType="m4.xlarge"												<Give the instance type that need to be used for EMR creation>
export servicerole="EMR_DefaultRole"										<Give the role EMR creation. If you do not have one please leave as is EMR_DefaultRole>
export name="Step-execution-example_naresh"									<You can define multiple steps. At this point Framwork support one step at a time>
export region="us-east-1"													<Please give the region where your job need to be executed>
export input_location=<s3_path>												<Please give S3 path as input path to take the input files>
export output_location=<s3_path>											<please give S3 path as output path to create the file in output directory>

2. Go to scee/scripts folder and execute aws_emr_cluster.ksh script. 


AWS_EKS_Cluster_Creation (Using Kubernetes Cluster configurations):

1. Please update the config file located in scee/config/aws_eks_cluster.config with the values as per your cloud configuration and requirements.

export name="EKSDemo"                              <Name of the EKS Cluster>
export role="arn:aws:iam::246453331714:role/EKSID" <Role ARN ID which created in Pre-requisites step 7>
export subnetIds="subnet-022533c9d10886676,subnet-08035de61b73936aa,subnet-01ef5fc5daeb23246"  < Subnet ID's created in pre-installation step 6/private subnet ID's>
export securityGroupIds="sg-0ff896a320ebe2e1d"     <SecurityGroup created in pre-installation step 6/private security group>
export region="us-east-1"						   <Region where Kubernetes cluster needs to be created>
export VpcId="vpc-02cfe033ecee48139"               <VPCId created in pre-installation step 6/private VPC name>
export worker_cluser_name="${name}workers"         <Worker name details>
export NodeImageId="ami-0c24db5df6badc35a"         <NodeImageId: https://docs.aws.amazon.com/eks/latest/userguide/getting-started.html#eks-launch-workers  AWS pre-installed image for Kubernetes compatibility on each region. Please select from the link based on your region selection>
export KeyName="EKSDemo"                           <Key-Pair combination if you would like to use>
export NodeGroupName="EKSWorkerStack"              <User Friendly node group name. This will be used to create worker stack>
export subnetIds_escape_comma="subnet-022533c9d10886676\\,subnet-08035de61b73936aa\\,subnet-01ef5fc5daeb23246"  <subnet ID's mentioned above with escape comma char>
export worker_stack_cft="https://amazon-eks.s3-us-west-2.amazonaws.com/cloudformation/2019-01-09/amazon-eks-nodegroup.yaml"<Worker stack CFT.Do not change.Use as is>
export SPARK_HOME="/home/ec2-user/spark-2.4.0-bin-hadoop2.7"      <Spark_Home path in your local>
export config_params="--conf spark.executor.instances=5 --conf spark.kubernetes.container.image=gcr.io/cloud-solutions-images/spark:v2.3.0-gcs --conf spark.kubernetes.driver.pod.name=spark-pi-driver"                 < Spark Configuration parameters >
export APP_JAR="s3:///dynamicclustersparkdemo/code/spark/spark-examples_2.11-2.2.0-k8s-0.5.0.jar" <application jar location>
export APP_PARAM="1000"																			  <Application parameters>
export APP_NAME="spark-pi"																		  <Application Name>
export APP_CLASS_NAME="org.apache.spark.examples.SparkPi"										  <Application Class Name>

2. Go to scee/scripts folder and execute aws_eks_cluster.ksh script.





