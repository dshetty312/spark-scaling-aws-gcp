import org.apache.spark.api.java.JavaPairRDD;
import org.apache.spark.api.java.JavaRDD;
import org.apache.spark.api.java.function.Function2;
import scala.Tuple2;

import java.io.Serializable;
import java.text.ParseException;
import java.text.SimpleDateFormat;
import java.util.Date;

public class SparkDedupeExample {

    public static class Record implements Serializable {
        private String key;
        private String date;
        private String otherData;

        public Record(String key, String date, String otherData) {
            this.key = key;
            this.date = date;
            this.otherData = otherData;
        }

        public String getKey() { return key; }
        public String getDate() { return date; }
        public String getOtherData() { return otherData; }
    }

    public static void main(String[] args) {
        // Assume sparkContext is already initialized
        JavaRDD<Record> inputRDD = sparkContext.parallelize(Arrays.asList(
            new Record("1", "2023-05-01", "Data A"),
            new Record("1", "2023-05-02", "Data B"),
            new Record("2", "2023-05-01", "Data C"),
            new Record("2", "2023-04-30", "Data D")
        ));

        // Convert to PairRDD with key as the tuple (key, date)
        JavaPairRDD<String, Record> keyedRDD = inputRDD.mapToPair(record ->
            new Tuple2<>(record.getKey(), record)
        );

        // Apply reduceByKey with a custom comparator
        JavaPairRDD<String, Record> dedupedRDD = keyedRDD.reduceByKey(
            new Function2<Record, Record, Record>() {
                @Override
                public Record call(Record r1, Record r2) throws ParseException {
                    SimpleDateFormat sdf = new SimpleDateFormat("yyyy-MM-dd");
                    Date date1 = sdf.parse(r1.getDate());
                    Date date2 = sdf.parse(r2.getDate());
                    return date1.after(date2) ? r1 : r2;
                }
            }
        );

        // Convert back to regular RDD if needed
        JavaRDD<Record> resultRDD = dedupedRDD.values();

        // Print results
        for (Record record : resultRDD.collect()) {
            System.out.println("Key: " + record.getKey() + 
                               ", Date: " + record.getDate() + 
                               ", Data: " + record.getOtherData());
        }
    }
}
