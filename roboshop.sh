#!/bin/bash

SG_ID="sg-06836c5944ba0ff00"
AMI_ID="ami-0220d79f3f480ecf5"
HOSTED_ZONE_ID="Z0354649BHBBW98BVSKE"
DOMAIN_NAME="naren83.online"

for instance in $@
do
   INSTANCESID=$(aws ec2 run-instances \
                  --image-id $AMI_ID\
                  --instance-type t3.micro \
                 --security-group-ids $SG_ID \
                 --tag-specifications "ResourceType=instance,Tags=[{Key=Name,Value=$instance}]" \
                 --query 'Instances[0].InstanceId' \
                 --output text)
 
   if [ $instance == forntend ]; then
      IP=$(
          aws ec2 describe-instances \
          --instance-ids $INSTANCESID \
          --query 'Reservations[].Instances[].PublicIpAddress' \
          --region YOUR_REGION \
          --output text
        )
        RECORD_NAME="$DOMAIN_NAME"
    else
       IP=$(
         aws ec2 describe-instances \
         --instance-ids $INSTANCESID \
         --query 'Reservations[*].Instances[*].PrivateIpAddress' \
         --region YOUR_REGION \
         --output text
        )
        RECORD_NAME="$HOSTED_ZONE_ID.$DOMAIN_NAME"
    fi

      echo "IP addres is : $IP"

        aws route53 change-resource-record-sets \
        --hosted-zone-id $HOSTED_ZONE_ID \
        --change-batch '

         {
         "Comment": "Updating a record",
         "Changes": [
             {
             "Action": "UPSERT",
             "ResourceRecordSet": {
                 "Name": "'$RECORD_NAME'",
                 "Type": "A",
                 "TTL": 60,
                "ResourceRecords": [
                 {
                   "Value": "'$IP'"
                 }
                 ]
            }
            }
         ]
         }
         '
    echo "Record upated $instance"

done