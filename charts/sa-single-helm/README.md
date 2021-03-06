# security-advisor-helm-chart
An all-in-one helm chart, that installs data collection and shard, and all the dependencies

This chart uses an unsecured version of kafka (kafkaSaalMechanism: 'PLAIN', kafkaSecurityProtocol: 'PLAINTEXT')
Uses minio as it's object storage

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
3. helm install --name=sa --namespace=<your-namespace> --set sa-data-collection.host=<cluster's ingress sub-domain> sa-charts/sa-single-helm
  
   Note: for ICP cluster that does not have domain name defined, remove --set sa-data-collection.host=.. from the above command

    
*	Create secret for registry.ng.bluemix.net:  
    https://kubernetes.io/docs/tasks/configure-pod-container/pull-image-private-registry/
      
      but I don’t have username and password on docker – only user to bluemix, so this is my alternative way:
    
      (a)	bx login --sso
      
      (b)	bx cr login
      
      (c)	bx cr token-add --readwrite --non-expiring --description jlerner
      
      (d)	sudo docker login registry.ng.bluemix.net -u token -p <Token>
      
      (e)	Create a secret in icp side, that can be supplied in the yaml to pull the image from registry
      (section: Create a Secret in the cluster that holds your authorization token)
      
      (f)	login to the icp cluster
      
      (g)	kubectl create secret docker-registry <my-image-pull-secret> --namespace <my-ns> --docker-server=registry.ng.bluemix.net --docker-username=token --docker-password=<token_password>
 
*default secret name is my-secret, and it can be modified with --set sa-shard.global.imagePullSecret = 'new-name'


4. On openshift only - an additional manual step is required:
This line adds service account to a previously created scc, which allows runAsAny user and group:

```oc adm policy add-scc-to-user <scc name> system:serviceaccount:<project/namespace>:<service account name>```

It is possible to use a default scc that already present in project or create a new scc (You must have cluster-admin privileges to   manage SCCs.)
https://docs.openshift.com/container-platform/3.4/admin_guide/manage_scc.html#updating-the-default-security-context-constraints

I used an existing "privileged" scc which has: runAsUser:
```runAsUser:
  type: RunAsAny
fsGroup:
  type: RunAsAny
```
```oc adm policy add-scc-to-user privileged system:serviceaccount:sa-analytics:default
oc adm policy add-scc-to-user privileged system:serviceaccount:sa-analytics:sa-single-helm-redis
oc adm policy add-scc-to-user privileged system:serviceaccount:sa-analytics:sa-service-account
oc adm policy add-scc-to-user privileged system:serviceaccount:sa-analytics:sa-redis
oc adm policy add-scc-to-user privileged system:serviceaccount:sa-collectors:skydive-service-account
oc adm policy add-scc-to-user privileged system:serviceaccount:sa-collectors:sa-service-account
```

all of the service accounts used in my components must be added the privileged scc


***About this Chart:***

* The chart's dependencies are sa-data-collection and sa-shard charts

* The chart is fully automated.

* The shard is auto-configured to collect and analyze only the single cluster it is installed on.
But this can be re-configured by:

1. setting the global.autoConfig = 'false'
2. and setting configmgr.global.shardData to the custom JSON
