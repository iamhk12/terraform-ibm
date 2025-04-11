region               = "us-east"
resource_name_prefix = "himkothatf-ftd"
zone                 = "us-east-1"
image_id             = "r014-3f780c4b-d9db-4fdf-bef0-ef551ff44d03" # Replace with valid image ID from IBM Cloud
ssh_key_id           = "r014-00433883-5a98-4ff7-a6b3-bb255ef39c97" # Replace with your actual SSH key ID
profile              = "cx3d-4x10"

mgmt_ip_cidr_range    = "10.10.0.0/24"
inside_ip_cidr_range  = "10.20.0.0/24"
outside_ip_cidr_range = "10.30.0.0/24"
diag_ip_cidr_range    = "10.40.0.0/24"
