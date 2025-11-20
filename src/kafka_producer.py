import csv
import json
import logging
import os

from kafka import KafkaProducer

KAFKA_BROKER = os.getenv("KAFKA_BROKER", "localhost:9092")
KAFKA_TOPIC = os.getenv("KAFKA_TOPIC", "transactions")
CSV_PATH = os.getenv("CSV_PATH", "data/train.csv")


def read_from_csv(path: str):
    with open(path, encoding="utf-8") as f:
        reader = csv.DictReader(f)
        for row in reader:
            yield row


def main():
    logging.basicConfig(level=logging.INFO, format="[%(asctime)s] [%(levelname)s] %(message)s")
    logging.info("kafka_producer starting")

    producer = KafkaProducer(bootstrap_servers=[KAFKA_BROKER], value_serializer=lambda v: json.dumps(v).encode("utf-8"))
    sent_count = 0

    try:
        for i, row in enumerate(read_from_csv(CSV_PATH), start=1):
            future = producer.send(KAFKA_TOPIC, value=row)
            sent_count += 1

            if i % 100000 == 0:
                record_metadata = future.get(timeout=10)
                logging.info(
                    f"Sent {i} messages. Offset: {record_metadata.offset} Patrition: {record_metadata.partition}"
                )

        producer.flush()
        logging.info(f"Sending complete. Total messages sent: {sent_count}")

    except Exception as e:
        logging.exception(f"Error while sending messages to Kafka: {e}")
    finally:
        logging.info("Closing Kafka producer")
        producer.close()


if __name__ == "__main__":
    main()
