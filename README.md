### Terraform
---

#### Terraform workflow
---

- `terraform init` downloads the modules and plugins. This also sets up the backend for terraform state file, a mechanism by which terraform tracks resources.
- `terraform plan` this command reads the code and then creates and shows a "plan" of execution/deployment. This command will allow the users to review the action plan before executing anything. At this stage authentication credentials are used to connect to your infrastructure if required.
- `terraform apply` deploys the instructions and statements in the code. Updates the state tracking mechanism file, a.k.a "state file".
- `terraform destroy` looks at the recorded, stored state file created during deployment and destroys all resources created by your code. This command should be used with caution as it is non-reversible command. Take backups and be sure that you want to delete the infrastructure.

#### Resource Addressing
---

**resource** block

```
resource "aws_instance" "web" {
    ami           = <ami-id>
    instance_type = <ec2-instance-type>
}
```

*resource address:*
```
aws_instance.web
```

**data** block

```
data "aws_instance" "web" {
    instance_id = <aws-instance-id>
}
```

*resource address:*
```
data.aws_instance.web
```

**provider** block

```
provider "aws" {
    region = "us-east-1"
}
```