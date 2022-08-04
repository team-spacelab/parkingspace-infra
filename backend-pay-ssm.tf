resource "aws_ssm_parameter" "payments_env" {
  name = "/parkingspace/payments/enviroment"
  description = "PaymentsServer@ParkingSpace Enviroment Configuration"
  type = "SecureString"

  value = "\u0000"

  lifecycle {
    ignore_changes = [
      value
    ]
  }
}
