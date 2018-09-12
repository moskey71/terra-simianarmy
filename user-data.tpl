#!/bin/bash

cd /opt/

echo "##cloning repo"
echo "##cloning repo"
echo "##cloning repo"
git clone git://github.com/Netflix/SimianArmy.git
cd SimianArmy

echo "##installing dependancies"
echo "##installing dependancies"
echo "##installing dependancies"
apt-get update && apt-get install awscli default-jre openjdk-8-jdk -y

echo "##building the simianarmy!!!"
echo "##building the simianarmy!!!"
echo "##building the simianarmy!!!"
./gradlew build

echo "Downloading configs from ${s3configbucket}"
echo "Downloading configs from ${s3configbucket}"
echo "Downloading configs from ${s3configbucket}"
aws s3 cp s3://${s3configbucket} /opt/SimianArmy/src/main/resources/. --recursive

echo "## Deploying the simianarmy!!!"
echo "## Deploying the simianarmy!!!"
echo "## Deploying the simianarmy!!!"
./gradlew jettyRun
