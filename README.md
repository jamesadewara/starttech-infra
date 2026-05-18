# starttech-infra

aws s3 mb s3://starttech-terraform-state --region us-east-1
aws s3api put-bucket-versioning --bucket starttech-terraform-state \
  --versioning-configuration Status=Enabled