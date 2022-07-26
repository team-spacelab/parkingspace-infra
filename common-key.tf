resource "tls_private_key" "pk" {
  algorithm = "RSA"
  rsa_bits = 4096
}

resource "local_file" "ssh_key" {
  file_permission = 600
  filename = "./output/${aws_key_pair.database.key_name}.pem"
  content = tls_private_key.pk.private_key_pem
}

resource "aws_key_pair" "database" {
  key_name = "parkingspace-key"
  public_key = tls_private_key.pk.public_key_openssh
}
