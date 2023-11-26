#!/bin/bash

apt update
apt install unzip -y
apt install git-all -y
apt install python3-pip -y
curl https://www.amazontrust.com/repository/AmazonRootCA1.pem > /home/ubuntu/root-CA.crt 
git clone https://github.com/aws/aws-iot-device-sdk-python-v2.git /home/ubuntu/aws-iot-device-sdk-python-v2 --recursive
python3 -m pip install /home/ubuntu/aws-iot-device-sdk-python-v2
echo '${IOT_TEST_CERT_CONTENTS}' > /home/ubuntu/iot_test.cert.pem
echo '${IOT_TEST_PRIVATE_KEY_CONTENTS}' > /home/ubuntu/iot_test.private.key
python3 /home/ubuntu/aws-iot-device-sdk-python-v2/samples/pubsub.py --endpoint ${IOT_ENDPOINT} --ca_file /home/ubuntu/root-CA.crt --cert /home/ubuntu/iot_test.cert.pem --key /home/ubuntu/iot_test.private.key --client_id basicPubSub --topic sdk/test/python --count 0