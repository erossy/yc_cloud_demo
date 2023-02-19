resource "null_resource" "container-build" { 
  provisioner "local-exec" {
   command = "docker build -t ${var.yc_cr_id}/sample-image . --network=host"
   working_dir = "web-app"

  }
}

resource "null_resource" "container-push" { 
  provisioner "local-exec" {
   command = "docker push ${var.yc_cr_id}/sample-image:latest"
  }
}