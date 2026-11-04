from confluent_kafka import Producer
import warnings

conf = { 'bootstrap.servers': 'kafka-0:9092,kafka-1:9092' }

def on_sent(msg):
  print(f'Message [{msg.partition()}]')

def main(k):
  as_producer = Producer(conf)

  def on_sent(err, msg, k):
    if err is not None:
      print(f"err: {err}")
      return
    k(msg)

  for i in range(10):
    as_producer.produce('NEWPOST', f"Test message {i}".encode('utf-8'), callback=lambda err, msg: on_sent(err, msg, k))
    as_producer.poll(0)
  as_producer.flush()

if __name__.__eq__('__main__'):
  warnings.warn("for debugging only: executing main function")
  main(on_sent)
