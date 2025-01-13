resource "aws_key_pair" "web_ssh_key" {
  key_name   = "my-web-key-pair"
  public_key = file(var.key-name)
}