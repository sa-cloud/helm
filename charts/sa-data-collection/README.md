# security-advisor-data-collection-helm-chart
A helm chart, that installs skydive and minio OS

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
3. helm install --name=sa-data --namespace=<your-namespace> --set host=<cluster's ingress sub-domain> sa-charts/sa-data-collection
   Note: if ICP cluster does not have domain name defined, then remove --set host=.. from the above command


***Notes:***
 1. Minio create bucket job some times gets stuck for some reason, which results in timeout and failed release. Then need to create the bucket manually in the minio GUI
 2. Accessing Minio GUI in the browser:
 * For ICP: < master node ip > / < bucket name >
   
 * For other cluster types: < cluster's ingress sub-domain > / < bucket name >
 
 * The default bucket name is icptest
   

***About this Chart:***

The chart's dependencies are minio and skydive charts

This chart runs a pre-install-job, that collects needed values from k8s and puts the results into **skydive-configuration config map** (that it creates)
The values:
- netmasks - for skydive netflow collection
- objectPrefix - for skydive to store objects
- guid - a unique id identifying the cluster's objects in object store
- containerRuntime

An additional configmap **sa-configuration** is defined as a template and stores the values related to minio configuration, that can be this way accessible to the skydive chart too.
