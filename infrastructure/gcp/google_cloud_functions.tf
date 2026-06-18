resource "google_cloudfunctions2_function" "function" {
  name        = "function-test"
  description = "My function"
  location = "us-central1"
   build_config {
    runtime = "python311"
    entry_point = "trigger_training"  # Set the entry point to the method
    source {
      storage_source {
        bucket = google_storage_bucket.static.name
        object = google_storage_bucket_object.function_zip.name
      }
    }
  }
                                                                                                                                                                                                               
  event_trigger {                                                                                                                                                                                                       
    trigger_region = "us-central1"                                                                                                                                                                                      
    event_type     = "google.cloud.storage.object.v1.finalized"                                                                                                                                                         
    event_filters {                                                                                                                                                                                                     
      attribute = "bucket"                                                                                                                                                                                              
      value     = google_storage_bucket.static.name                                                                                                                                                                     
    }                                                                                                                                                                                                                   
  }      
}
 
 resource "google_storage_bucket_object" "function_zip" {
    name   = "function.zip"
    bucket = google_storage_bucket.static.name
    source = "${path.module}/function.zip"    
  }



  