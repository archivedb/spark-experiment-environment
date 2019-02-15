#!/usr/bin/env bash

set -e

cd "$(dirname "${BASH_SOURCE[0]}")/.."

HIBENCH_HOME="$PWD/hibench"
REPORTS_DIR="$PWD/reports"
CONFS_DIR="$PWD/.tmp/spark-confs"

# process arguments
while getopts "ie" OPT; do
  case "$OPT" in
    i) INITIAL_MODE="on";;
    e) ERREXIT_MODE="on";;
    *) exit 1;;
  esac
done

# backup reports
if [[ -v INITIAL_MODE ]] && [[ -d "$REPORTS_DIR" ]]; then
  mv "$REPORTS_DIR" "$REPORTS_DIR.$(date +"%Y%m%d.%H%M%S")"
fi

# generate configurations
if [[ -v INITIAL_MODE ]] || [[ ! -d "$CONFS_DIR" ]]; then
  rm -rf "$CONFS_DIR"
  mkdir -p "$CONFS_DIR"
  scripts/gen.py "$CONFS_DIR"
fi

# build hibench
if [[ ! -d "$HIBENCH_HOME/sparkbench/assembly/target" ]]; then
  ( # subshell
    cd "$HIBENCH_HOME"
    mvn -Psparkbench -Dspark=2.2 clean package
  )
fi

# configure hibench hadoop.conf
cp "$HIBENCH_HOME/conf/hadoop.conf.template" "$HIBENCH_HOME/conf/hadoop.conf"
sed -i "s#/PATH/TO/YOUR/HADOOP/ROOT#$HADOOP_HOME#g" "$HIBENCH_HOME/conf/hadoop.conf"
sed -i "s#hdfs://localhost:8020#hdfs://master:8020#g" "$HIBENCH_HOME/conf/hadoop.conf"

for CONF in "$CONFS_DIR"/*; do

  while IFS= read -r BENCH; do

    CONF_IDX="${CONF#$CONFS_DIR/}"

    REPORT_ARCHIVE="$REPORTS_DIR/${BENCH//\//-}/$CONF_IDX"

    # exist and pass
    if [[ -d "$REPORT_ARCHIVE" ]]; then continue; fi

    # configure hibench spark.conf
    cp "$CONFS_DIR/$CONF_IDX" "$HIBENCH_HOME/conf/spark.conf"
    sed -i "s#/PATH/TO/YOUR/SPARK/ROOT#$SPARK_HOME#g" "$HIBENCH_HOME/conf/spark.conf"

    # clean report
    rm -rf "$HIBENCH_HOME/report"
    mkdir -p "$HIBENCH_HOME/report/spark-event-logs"

    DATE="$(date +"%Y-%m-%d %H:%M:%S")"
    echo -e "\e[46m[${BENCH//\//-}-$CONF_IDX]\e[0m"
    echo -e "$DATE"

    # run bench
    unset ERR
    WORKLOAD="$HIBENCH_HOME/bin/workloads/${BENCH//-/\/}"
    "$WORKLOAD/prepare/prepare.sh" && "$WORKLOAD/spark/run.sh" || ERR="$?"

    if [[ -v ERR ]]; then
      if [[ -v ERREXIT_MODE ]]; then exit "$ERR"; fi
      REPORT_ARCHIVE="$REPORTS_DIR/failed/${REPORT_ARCHIVE#$REPORTS_DIR/}"
      STATUS="FAILED"
    else
      STATUS="OK"
    fi

    # save report
    mkdir -p "$REPORT_ARCHIVE"
    mv "$HIBENCH_HOME/report" "$REPORT_ARCHIVE"
    echo "$DATE $BENCH $CONF_IDX $STATUS" >> "$REPORTS_DIR/status"

  done < "scripts/benches"

done
