#!/bin/sh
gcloud container clusters create $1 --num-nodes 1 --zone asia-southeast1-b
