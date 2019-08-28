# security-advisor-helm-chart
An all-in-one helm chart, that installs tia, data-control, and all it's dependencies

This chart uses an unsecured version of kafka (kafkaSaalMechanism: 'PLAIN', kafkaSecurityProtocol: 'PLAINTEXT')
The chart is supported for ICP, IKS and Openshift

***Pre-Requisites:***
1. A kubernetes Cluster: ICP/IKS/Openshift
For ICP:
1.1 IBM Cloud Private version 3.1.0 or higher running on Linux® 64-bit (x86_64) systems. 
1.2 Kubernetes cluster 1.7 or higher
1.3 At least 3 worker nodes

2. Helm tiller installed and running on the cluster + helm client

***Installing the chart:***
1. helm repo add sa-charts https://github.com/sa-cloud/helm/blob/master/repo?raw=true
2. helm repo update
3. helm install --name=sa-shard --namespace=<your-namespace> sa-charts/sa-shard
    
* Create secret for registry.ng.bluemix.net:  
    https://kubernetes.io/docs/tasks/configure-pod-container/pull-image-private-registry/
      
      but I don’t have username and password on docker – only user to bluemix, so this is my alternative way:
    
      (a)	bx login --sso
      
      (b)	bx cr login
      
      (c)	bx cr token-add --readwrite --non-expiring --description jlerner
      
      (d)	sudo docker login registry.ng.bluemix.net -u token -p <Token>
      
      (e)	Create a secret in icp side, that can be supplied in the yaml to pull the image from registry
      (section: Create a Secret in the cluster that holds your authorization token)
      
      (f)	login to the icp cluster
      
      (g)	kubectl create secret docker-registry my-secret --namespace <my-ns> --docker-server=registry.ng.bluemix.net --docker-username=token --docker-password=<token_password>


***About this Chart:***

* The chart's dependencies are tia, data-control, kafka, findingsLog, redis charts

* This chart creates shard-configmap, that has the accountsApiEndpoint

***Configuration:***

* global.securityAdvisorShardId has the default shard ID. It should be set to a unique value.

* configmgr.global.shardData has the json that defines the accounts that are monitored by this shard and should be configured.

  An example JSON for 3 accounts:
  
'{"accounts":[{"account_id":"fa53b6717d5e9c9979101d8dac5fd4ad","bucket_url":"http://customerv11.us-south.containers.appdomain.cloud/icptest","auth":{"type":"AMAZON_S3", "accessKey":"admin","secretKey":"admin1234","region":"dontcare"},"collect_from":{"netflow_ingress":true,"netflow_egress":true,"netflow_internal":true,"netflow_other":true,"at_cadf":true},"sa_analytics":{"tia":true,"ata":true,"nba":true},"sa_instance_crn":"crn:v1:staging:public:security-advisor:us-south:a/d0c8a917589e40076961f56b23056d16:ef71b41c-3239-5ff0-ad6e-5f8059f1130b:security-advisor:","sa_analytics_status":{"ata":[{"packageUrl":"https://","num_active_rules":2,"num_dormant_rules":45,"num_illegal_rules":6,"status":"success"}],"dc":{"num_sources_netflow":3,"num_sources_at":1}}},{"account_id":"2e40efb1287694f11d1f27920543d283","bucket_url":"http://sa-collect-minio-object-store:9000/icptest","auth":{"type":"AMAZON_S3", "accessKey":"admin","secretKey":"admin1234","region":"dontcare"},"collect_from":{"netflow_ingress":true,"netflow_egress":true,"netflow_internal":true,"netflow_other":true,"at_cadf":true},"sa_analytics":{"tia":true,"ata":true,"nba":true},"sa_instance_crn":"crn:v1:staging:public:security-advisor:us-south:a/d0c8a917589e40076961f56b23056d16:ef71b41c-3239-5ff0-ad6e-5f8059f1130b:security-advisor:","sa_analytics_status":{"ata":[{"packageUrl":"https://","num_active_rules":2,"num_dormant_rules":45,"num_illegal_rules":6,"status":"success"}],"dc":{"num_sources_netflow":3,"num_sources_at":1}}},{"account_id":"2e40efb1287694f11d1f27920543d111","bucket_url":"http://9.148.244.87/icptest","auth":{"type":"AMAZON_S3", "accessKey":"admin","secretKey":"admin1234","region":"dontcare"},"collect_from":{"netflow_ingress":true,"netflow_egress":true,"netflow_internal":true,"netflow_other":true,"at_cadf":true},"sa_analytics":{"tia":true,"ata":true,"nba":true},"sa_instance_crn":"crn:v1:staging:public:security-advisor:us-south:a/d0c8a917589e40076961f56b23056d16:ef71b41c-3239-5ff0-ad6e-5f8059f1130b:security-advisor:","sa_analytics_status":{"ata":[{"packageUrl":"https://","num_active_rules":2,"num_dormant_rules":45,"num_illegal_rules":6,"status":"success"}],"dc":{"num_sources_netflow":3,"num_sources_at":1}}}]}'


***Testing***

To test the kafka topics create a testclient pod (in the same namespace as the just installed SA helm release) :

  apiVersion: v1
  kind: Pod
  metadata:
    name: testclient
    namespace: default
  spec:
    containers:
    - name: kafka
      image: confluentinc/cp-kafka:5.0.1
      command:
        - sh
        - -c
        - "exec tail -f /dev/null"


**To list kafka topics:**
kubectl -n default exec testclient -- /usr/bin/kafka-topics --zookeeper sa-icp-zookeeper:2181 --list

**To create a topic:** 
kubectl -n default exec testclient -- /usr/bin/kafka-topics --zookeeper sa-icp-zookeeper:2181 --topic test1 --create --partitions 1 --replication-factor 1

**To produce messages:**
kubectl -n default exec -ti testclient -- /usr/bin/kafka-console-producer --broker-list sa-icp-kafka-headless:9092 --topic test1

**To consume topic:**
kubectl -n default exec -ti testclient -- /usr/bin/kafka-console-consumer --bootstrap-server sa-icp-kafka-headless:9092 --topic test1 --from-beginning
