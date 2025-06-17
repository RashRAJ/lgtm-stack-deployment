# infrastructure/environments/production/backend.tf

# Configure Terraform state backend
# Uncomment and configure after creating the state bucket

# terraform {
#   backend "gcs" {
#     bucket = "YOUR_PROJECT_ID-terraform-state"
#     prefix = "lgtm-stack/production"
#   }
# }

# To create the state bucket, run these commands:
# gsutil mb -p YOUR_PROJECT_ID gs://YOUR_PROJECT_ID-terraform-state
# gsutil versioning set on gs://YOUR_PROJECT_ID-terraform-state
# gsutil lifecycle set lifecycle.json gs://YOUR_PROJECT_ID-terraform-state

# Example lifecycle.json for state bucket:
# {
#   "lifecycle": {
#     "rule": [
#       {
#         "action": {"type": "Delete"},
#         "condition": {
#           "age": 365,
#           "isLive": false
#         }
#       }
#     ]
#   }
# }