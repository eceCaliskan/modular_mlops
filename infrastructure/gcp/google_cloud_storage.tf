#This file is responsible for creating google storage bucket in GCP
#
#This file is a part of OUT2 A reproducible open-source MLOps pipeline modules implemented with IaC approach.
#
#Main sources used
#https://registry.terraform.io/providers/hashicorp/google/latest/docs/list-resources/google_storage_bucket
#https://registry.terraform.io/providers/hashicorp/google/latest/docs/list-resources/google_secret_manager_secret_iam
#https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/secret_manager_secret.html
#
#Creating google storage bucket
resource "google_storage_bucket" "static" {
 name          = "modular-mlops" 
 location      = "us-central1"
 storage_class = "STANDARD"
 uniform_bucket_level_access = true
}

#Creating a secret manager called ml_input_file to store the dataset
#https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/secret_manager_secret.html
resource "google_secret_manager_secret" "ml_input_file" {                                                                                          
    secret_id = "ml-input-file"                                                                                                                      
    project   = "project-8fba7723-3f35-48db-ae1"                                                                                                                                                                                                                                                     
    replication {                                                                                                                                    
        auto {}
    }
}

#Assigning IAM role to objects from the storage bucket
#https://registry.terraform.io/providers/hashicorp/google/latest/docs/list-resources/google_secret_manager_secret_iam
resource "google_storage_bucket_iam_member" "gcf_access" {                                                                                                                                                              
  bucket = "gcf-v2-sources-397832183085-us-central1"                                                                                                                                                                       
  role   = "roles/storage.objectViewer"                                                                                                                                                                                 
  member = "serviceAccount:397832183085-compute@developer.gserviceaccount.com"                                                                                                                                          
}   