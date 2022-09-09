resource "aws_ssm_parameter" "space_env" {
  name = "/parkingspace/space/enviroment"
  description = "SpaceServer@ParkingSpace Enviroment Configuration"
  type = "SecureString"

  value = "S3_BUCKET_NAME=${aws_s3_bucket.uploads.name}"

  lifecycle {
    ignore_changes = [
      value
    ]
  }
}
