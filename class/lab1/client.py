from confluent_kafka import Consumer, KafkaError

conf = { 'bootstrap.servers': 'kafka-0:9092,kafka-1:9092', 'group.id': 'ttkb-hcmut-0', 'auto.offset.reset': 'earliest' }

def on_(msg):
  print(f'new post: {msg.value().decode('utf-8')}')
  pass

def main(on_):
  as_consumer = Consumer(conf)
  as_consumer.subscribe(['newpost'])
  try:
    while True:
      msg = as_consumer.poll(1.0)
      if msg is None:
        print('no msg')
        continue
      if msg.error():
        print(f'error: {msg.error()}')
        break
      on_(msg)
  except KeyboardInterrupt: print()
  finally:
    as_consumer.close()

if __name__.__eq__('__main__'): main(on_)
