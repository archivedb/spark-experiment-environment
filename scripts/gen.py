#!/usr/bin/env python3

base = [
  ("hibench.spark.home", "/PATH/TO/YOUR/SPARK/ROOT"),
  ("hibench.spark.master", "spark://master:7077"),
  ("spark.driver.memory", "${spark.executor.memory}"),
  ("spark.sql.shuffle.partitions", "${spark.default.parallelism}"),
  ("spark.eventLog.dir", "file:///vagrant/hibench/report/spark-event-logs"),
  ("spark.eventLog.enabled", "true"),
]

candidates = [
  ("spark.executor.cores", ["2"]),
  ("spark.executor.memory", ["512m"]),
  ("spark.default.parallelism", ["12", "16", "20"]),
  ("spark.shuffle.compress", ["true", "false"]),
  ("spark.shuffle.spill.compress", ["true", "false"]),
  ("spark.io.compression.codec", ["lz4", "lzf", "snappy"]),
  ("spark.serializer", [f"org.apache.spark.serializer.{t}Serializer" for t in ["Java", "Kryo"]]),
]

def generate():
  cs = [base]
  for k, vs in candidates:
    cs = [c + [(k, v)] for c in cs for v in vs]
  return cs

def serialize(c):
  return "\n".join([f"{k}\t{v}" for k, v in c])

def write(c, i, d):
  with open(f"{d}/{i:03}", "w") as file:
    file.write(serialize(c))

def main():
  import sys
  for i, c in enumerate(generate()):
    write(c, i, sys.argv[1])

if __name__ == "__main__": main()
