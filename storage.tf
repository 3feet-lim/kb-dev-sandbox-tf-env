# module "test_bucket" {
#   source = "./modules/terraform-aws-s3/"
#   bucket = "test_bucket_smlim"

#   lifecycle_rules = [
#     {
#       id = "eksenginelog-1"
#       enabled = true
#       expiration = 30
#       filter = {
#         prefix = "/"
#       }
#     }
#   ]
# }