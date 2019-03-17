##Created by Dikshith S Shetty(dishetty@deloitte.com)
##Creates bucket to store etl jar

export SPARK_INPUT=spark-input
echo "Creating gcp bucket $SPARK_INPUT"

gsutil mb -c regional -l us-east1 gs://${SPARK_INPUT}

echo "Copying SparkPi jar to gs bucket"
gsutil cp ../input/*jar gs://${SPARK_INPUT}
