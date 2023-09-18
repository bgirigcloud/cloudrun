  #Activate your lab account:
  
  gcloud auth list --filter=status:ACTIVE --format="value(account)"
  #git clone 
  
  git clone https://github.com/Deleplace/pet-theory.git
  cd pet-theory/lab03
  
#Now run the following to build the application
go build -o server
#Initiate a rebuild of the pdf-converter image using Cloud Build:
gcloud builds submit   --tag gcr.io/$GOOGLE_CLOUD_PROJECT/pdf-converter
#Run these commands to build the container and to deploy it
 gcloud run deploy pdf-converter   --image gcr.io/$GOOGLE_CLOUD_PROJECT/pdf-converter   --platform managed   --region us-east1   --memory=2Gi   --no-allow-unauthenticated   --set-env-vars PDF_BUCKET=$GOOGLE_CLOUD_PROJECT-processed   --max-instances=3
  #Create a Pub/Sub notification to indicate a new file has been uploaded to the docs bucket ("uploaded"). The notifications will be labeled with the topic "new-doc
   gsutil notification create -t new-doc -f json -e OBJECT_FINALIZE gs://$GOOGLE_CLOUD_PROJECT-upload
   #Create a new service account to trigger the Cloud Run services:
    gcloud iam service-accounts create pubsub-cloud-run-invoker --display-name "PubSub Cloud Run Invoker"
   #Give the service account permission to invoke the PDF converter service
    gcloud run services add-iam-policy-binding pdf-converter   --member=serviceAccount:pubsub-cloud-run-invoker@$GOOGLE_CLOUD_PROJECT.iam.gserviceaccount.com   --role=roles/run.invoker   --region us-east1   --platform managed
 #Find your project number by running this command  
   PROJECT_NUMBER=$(gcloud projects list \
 --format="value(PROJECT_NUMBER)" \
 --filter="$GOOGLE_CLOUD_PROJECT")
#Enable your project to create Cloud Pub/Sub authentication tokens
 
    gcloud projects add-iam-policy-binding $GOOGLE_CLOUD_PROJECT   --member=serviceAccount:service-$PROJECT_NUMBER@gcp-sa-pubsub.iam.gserviceaccount.com   --role=roles/iam.serviceAccountTokenCreator
#Save the URL of your service in the environment variable $SERVICE_URL   
   
   SERVICE_URL=$(gcloud run services describe pdf-converter \
  --platform managed \
  --region us-east1 \
  --format "value(status.url)")
  
   echo $SERVICE_URL
   #Make an anonymous GET request to your new service
   curl -X GET $SERVICE_URL
   #Now try invoking the service as an authorized user
    curl -X GET -H "Authorization: Bearer $(gcloud auth print-identity-token)" $SERVICE_URL
    
    curl -X GET $SERVICE_URL
    curl -X GET -H "Authorization: Bearer $(gcloud auth print-identity-token)" $SERVICE_URL
    #Create a Pub/Sub subscription so that the PDF converter will be run whenever a message is published to the topic new-doc
   gcloud pubsub subscriptions create pdf-conv-sub   --topic new-doc   --push-endpoint=$SERVICE_URL   --push-auth-service-account=pubsub-cloud-run-invoker@$GOOGLE_CLOUD_PROJECT.iam.gserviceaccount.com
   #Copy the test files into your upload bucket
   gsutil -m cp -r gs://spls/gsp762/* gs://$GOOGLE_CLOUD_PROJECT-upload
