resource "aws_key_pair" "tests_ssh_key" {
  key_name   = "tests-key-pair"
  public_key = file(var.key-name)
}