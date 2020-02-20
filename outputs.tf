output "master_dns" {
  value = "${aws_spot_instance_request.master.public_dns}"
}
