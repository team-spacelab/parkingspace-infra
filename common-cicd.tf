resource "aws_codestarconnections_connection" "conn" {
  name          = "parkingspace-codestar"
  provider_type = "GitHub"
}
