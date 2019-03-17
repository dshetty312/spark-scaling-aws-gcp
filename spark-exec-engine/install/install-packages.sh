#Install python and java.We are using Debian distribution version of linux
sudo apt-get update
sudo apt-get install default-jre
sudo apt-get install default-jdk
#sudo apt-get install oracle-java8-installer
sudo apt-get install python-pip
sudo apt-get install python2.7

#Install kubectl and spark package.
sudo apt-get install kubectl

wget http://mirrors.gigenet.com/apache/spark/spark-2.3.2/spark-2.3.2-bin-hadoop2.7.tgz
tar xvf spark-2.3.2-bin-hadoop2.7.tgz

rm -rf spark-2.3.2-bin-hadoop2.7.tgz
