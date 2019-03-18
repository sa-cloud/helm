# security-advisor-data-collection-helm-chart
A helm chart, that installs skydive and minio OS

***Pre-Requisites:***
1. IBM Cloud Private version 3.1.0 or higher running on Linux® 64-bit (x86_64) systems. 
2. Kubernetes cluster 1.7 or higher
3. At least 3 worker nodes

***Installing the chart:***
1. helm repo add sa-charts https://github.com/sa-cloud/helm/blob/master/repo?raw=true
2. helm repo update
3. Create secret for minio OS:

    *kubectl create secret generic sa-data --from-literal=accesskey=admin --from-literal=secretkey=admin1234*
    
 4. Update the sa-helm/values.yaml or use –set for the following parameters:
 
    (1)	minio.existingSecret = sa-data (note that the secret that is created must be in the same namespace where the helm is installed and must be named like the name of the release)
    
    (2)	minio.minioConfig.region = currently, due to skydive-minio bug it must be set to dontcare, generally it has to be one of the strings in datacontrol.global. supportedRegions (or update supportedRegions to include it)
    
    (3)	minio.defaultBucket = the name of the bucket (Set by default to ‘icptest’)

    (4)	ibm-skydive-dev.env.SKYDIVE_STORAGE_DEFENDER_ENDPOINT = http://sa-icp:9000 (note that the helm release name is the name of the endpoint – here it is sa-icp) – can’t make the endpoint template – should be done in config map, I only pass in values…
    
    (5)	ibm-skydive-dev.env.SKYDIVE_STORAGE_DEFENDER_ACCESS_KEY= the access key, that matches the secret created for minio (here admin)
    
    (6)	ibm-skydive-dev.env.SKYDIVE_STORAGE_DEFENDER_SECRET_KEY = the secret key, that matches the secret created for minio (here admin1234)
    
    (7)	ibm-skydive-dev.env.SKYDIVE_STORAGE_DEFENDER_BUCKET = bucket name that is created in minio, this must match minio. defaultBucket
    
    (8)	ibm-skydive-dev.env.SKYDIVE_STORAGE_DEFENDER_REGION region configured in minio – must match minio.minioConfig.region
    
    (9)ibm-skydive-dev.env.SKYDIVE_STORAGE_DEFENDER_KUBERNETES_GUID

 
5. helm install --name=sa-data --namespace=<your-namespace> sa-charts/sa-data-collection

    (Make sure you have all the permissions in the namespace that you are using (kubectl create rolebinding command)

 
 
***Notes:***
 1. minio has several helm bugs, one of which is related to the minio secret. The secret must be named like the helm release name. When create bucket is set to true (we want the bucket to be automatically created), mount volume is looking for secret named as release name, and fails if does not exist. Seems like this was recently fixed for the case where create bucket is false…
 2. Another minio helm feature is that it is created with release name: minio endpoint is called like the release name, and other minio objects do not have distinguishing names and use the release name with no “minio” postfix. The minio endpoint name is of interest to skydive and to DC and is set through the values file(s) to both for them.
 3. Minio create bucket job gets stuck for some reason in 50% of installations, which results in timeout and failed release. Then need to run sudo helm del --purge sa-icp --tls, go and manually delete the batch Job – not deleted as part of the release, and re-run the install command.. Another way is to set the defaultBucket.enabled to false in values.yaml, and after the chart is installed, create the bucket manually (minio gui can be reached the following way:

    *export POD_NAME=$(kubectl get pods --namespace default -l "release=sa-icp" -o jsonpath="{.items[0].metadata.name}")*
    *kubectl port-forward $POD_NAME 9000 --namespace default*

The error in make-bucket-job: kubectl logs sa-icp-make-bucket-job-7d2zl
Connecting to Minio server: http://sa-icp:9000
Added `myminio` successfully.
Creating bucket 'icptest'
mc: <ERROR> Unable to make bucket `myminio/icptest`. The authorization header is malformed; the region is wrong; expecting 'us-east-1'.


