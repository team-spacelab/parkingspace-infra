resource "aws_ssm_parameter" "auth_env" {
  name = "/parkingspace/auth/enviroment"
  description = "AuthServer@ParkingSpace Enviroment Configuration"
  type = "SecureString"

  value = "\u0000"

  lifecycle {
    ignore_changes = [
      value
    ]
  }
}
