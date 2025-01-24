resource "aws_key_pair" "reports_ssh_key" {
  key_name   = "my-reports-key-pair"
  public_key = file(var.key-name)
}