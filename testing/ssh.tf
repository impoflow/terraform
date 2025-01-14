resource "aws_key_pair" "locust_ssh_key" {
  key_name   = "my-locust-key-pair"
  public_key = file(var.key-name)
}