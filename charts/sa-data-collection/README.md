# security-advisor-data-collection-helm-chart
A helm chart, that installs skydive and minio OS

***Pre-Requisites:***
1. IBM Cloud Private version 3.1.0 or higher running on Linux® 64-bit (x86_64) systems. 
2. Kubernetes cluster 1.7 or higher
3. At least 3 worker nodes
4. GlusterFS storage, available through dynamic volume provisioning by using a storage class. 

***Installing the chart:***
1. first clone skydive from it's git repository, since it's helm cart is currently not in any helm repository (skydive is the sa compatible version):
  
    *git clone git@github.ibm.com:cloud-platforms/ICP-skydive-chart.git*


2. Skydive is taken from it's local repository, so make sure that the repository entry in requirments.yaml point to where you actually cloned it. 
Then execute **sudo helm dependency update** to get the zipped packages from the locations that are mentioned in the requirements.yaml
Make sure all the dependencies zip packages now appear in the charts directory (2 dependencies)

3. Add ibm-charts repository to your cluster, if it isn’t already added:

    *sudo helm repo add ibm-charts https://raw.githubusercontent.com/IBM/charts/master/repo/stable/*

4. Create secret for minio OS:

    *kubectl create secret generic sa-icp --from-literal=accesskey=admin --from-literal=secretkey=admin1234*
    
5.	Create secret for registry.ng.bluemix.net:  
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
 
 6. Update the sa-helm/values.yaml or use –set for the following parameters:
 
    (1)	minio.existingSecret = sa-icp (note that the secret that is created must be in the same namespace where the helm is installed and must be named like the name of the release)
    (2)	minio.persistence.storageClass = the persistent storage class (see minio documentation)
    
    (3)	minio.minioConfig.region = currently, due to skydive-minio bug it must be set to dontcare, generally it has to be one of the strings in datacontrol.global. supportedRegions (or update supportedRegions to include it)
    
    (4)	minio.defaultBucket = the name of the bucket (Set by default to ‘icptest’)

    (5)	ibm-skydive-dev.env.SKYDIVE_STORAGE_DEFENDER_ENDPOINT = http://sa-icp:9000 (note that the helm release name is the name of the endpoint – here it is sa-icp) – can’t make the endpoint template – should be done in config map, I only pass in values…
    
    (6)	ibm-skydive-dev.env.SKYDIVE_STORAGE_DEFENDER_ACCESS_KEY= the access key, that matches the secret created for minio (here admin)
    
    (7)	ibm-skydive-dev.env.SKYDIVE_STORAGE_DEFENDER_SECRET_KEY = the secret key, that matches the secret created for minio (here admin1234)
    
    (8)	ibm-skydive-dev.env.SKYDIVE_STORAGE_DEFENDER_BUCKET = bucket name that is created in minio, this must match minio. defaultBucket
    
    (9)	ibm-skydive-dev.env.SKYDIVE_STORAGE_DEFENDER_REGION region configured in minio – must match minio.minioConfig.region
    
    (10)ibm-skydive-dev.env.SKYDIVE_STORAGE_DEFENDER_KUBERNETES_GUID

 

7. sudo helm install --name=<release-name> --namespace=<your-namespace> . --tls

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


