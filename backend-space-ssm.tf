resource "aws_ssm_parameter" "space_env" {
  name = "/parkingspace/space/enviroment"
  description = "SpaceServer@ParkingSpace Enviroment Configuration"
  type = "SecureString"

  value = "\u0000"

  lifecycle {
    ignore_changes = [
      value
    ]
  }
}
