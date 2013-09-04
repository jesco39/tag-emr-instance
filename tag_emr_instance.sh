#!/bin/bash
#
# Simple script to tag EMR instances from the instance itself.
# Can (and should) be used as a bootstrap action
#
# Copyright (C) 2013 Tiago Alves Macambira <macambira (@) chaordicsystems.com>
#
# Permission is hereby granted, free of charge, to any person obtaining a
# copy of this software and associated documentation files (the
# "Software"), to deal in the Software without restriction, including
# without limitation the rights to use, copy, modify, merge, publish,
# distribute, sublicense, and/or sell copies of the Software, and to
# permit persons to whom the Software is furnished to do so, subject to
# the following conditions:
#
# The above copyright notice and this permission notice shall be included
# in all copies or substantial portions of the Software.
HADOOP_CONF='/home/hadoop/conf/core-site.xml'
TMP_FILE='/tmp/tags.txt'

function usage {
cat << EOF

usage:$0 options

A bash script that deploys war files to tomcat instances.

OPTIONS:
       -h      Show this messages
       -c      The path to the tags config file in S3

EOF
}

# get config
while getopts "c:" OPTION; do
  case $OPTION in
    h)
      usage
      exit 1
      ;;
    c)
      CONFIG="$OPTARG"
      ;;
    ?)
      usage
      exit 1
      ;;
  esac
done

if [[ -z $CONFIG ]]; then
  echo "Config file is not specified"
  usage
  exit 1
fi

# Create a separate dir to hold our junk
INSTALL_DIR=tag_emr_instance
mkdir --parent ${INSTALL_DIR}
cd ${INSTALL_DIR}

# Grab existing credentials from core-site.xml and set them
export AWS_ACCESS_KEY=`cat ${HADOOP_CONF} | grep fs.s3.awsAccessKeyId | egrep -o "<value>\w.+</value>" | sed -e 's,.*<value>\([^<]*\)</value>.*,\1,g'`
export AWS_SECRET_KEY=`cat ${HADOOP_CONF} | grep  fs.s3.awsSecretAccessKey | egrep -o "<value>\w.+</value>" | sed -e 's,.*<value>\([^<]*\)</value>.*,\1,g'`

echo "Download and install Amazon CLI tools"
wget 'http://s3.amazonaws.com/ec2-downloads/ec2-api-tools.zip'
unzip ec2-api-tools.zip
export EC2_HOME=$(find $(pwd) -type d -name 'ec2-api-tools-*' | tail -1)
EC2_CREATE_TAGS="${EC2_HOME}/bin/ec2-create-tags"
chmod 755 $EC2_CREATE_TAGS

# Retrieve currently running EMR's instance instanceID using Amazon's
# Instance Metadata Service
INSTANCE_ID=$(wget -q -O - http://169.254.169.254/latest/meta-data/instance-id)

# Split a internal hostname like ip-10-44-191-108.eu-west-1.compute.internal
# to figure out the region of this instance.
REGION=$(hostname | cut -d. -f2)

if [[ $REGION == 'ec2' ]]; then
  REGION='us-east-1'
fi

# We need to pull down the config from S3 before reading
echo "pulling tags file from S3 for reading"
hadoop fs -copyToLocal $CONFIG $TMP_FILE

# Finally, call ec2-create-tags with the argument list form tags.txt
echo "Reading in tags from config, and setting them via the CLI"
while read line; do
  $EC2_CREATE_TAGS $INSTANCE_ID --tag "$line"
done < $TMP_FILE
