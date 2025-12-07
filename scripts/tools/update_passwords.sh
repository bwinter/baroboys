# gcloud secrets create server-password --replication-policy=automatic
gcloud secrets versions add server-password --data-file=<(echo "$1")

# gcloud secrets delete SECRET_ID