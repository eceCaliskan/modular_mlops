resource "google_storage_bucket" "static" {
 name          = "modular-mlops" 
 location      = "us-central1"
 storage_class = "STANDARD"
 uniform_bucket_level_access = true
}

resource "google_secret_manager_secret" "ml_input_file" {                                                                                          
    secret_id = "ml-input-file"                                                                                                                      
    project   = "project-a280d5fe-bdeb-4fbe-aa0"                                                                                                                                                                                                                                                     
    replication {                                                                                                                                    
        auto {}
    }
}

  resource "google_storage_bucket_iam_member" "gcf_access" {                                                                                                                                                              
    bucket = "gcf-sources-614602581181-us-central1"                                                                                                                                                                       
    role   = "roles/storage.objectViewer"                                                                                                                                                                                 
    member = "serviceAccount:614602581181-compute@developer.gserviceaccount.com"                                                                                                                                          
  }   