resource "null_resource" "dummy_resource" {
  provisioner "local-exec" {
    command = "echo ${self.id} > status.txt"
  }
}

resource "local_file" "foo" {
  filename = "foo.txt"
  # ${null_resource.dummy_resource.id} is called as interpolation sequence
  content = "id is ${null_resource.dummy_resource.id}"
}