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

#### How to enable the verbose logging in terraform?
---

```
export TF_LOG=TRACE

terraform init
```

#### Variables in terraform
---

```
variable "my-var" {
    type        = string
    description = "description"
    default     = "default value"
}
```

In this case you need to pass a value to this variable either through os environment variable or command line input.
```
variable "my-var" {}
```

If no default values are given to the variables, you will be prompted to enter the values during `terraform apply` in interactive mode.

To avoid entering variables in interactive mode we can follow few approaches.

- we can pass it directly using command line flags `terraform apply -var "key=value" -var "key=value" -var "key=value"`
- we can make use of environment variables `export TF_VAR_VARIABLE_NAME` and `terraform apply`
- we can make use of variable definition file `terraform.tfvars` or `terraform.tfvars.json`  or `somefile.auto.tfvars` or `somefile.auto.tfvars.json`
- *.auto.* will be loaded automatically.
  ```
  key1 = value2
  key2 = value2
  ```
- if you are using any other file name, we should use `terraform apply -var-file <filename>.tfvars`

**Referencing a variable:**
```
var.my-var
```

It is a best practice to define these variables under separate files.

- `variables.tf`
- ``

**Variable validation:**

```
variable "my-var" {
    type        = string
    description = "description"
    default     = "default value"
    validation {
        condition     = length(var.my-var) > 4
        error_message = "The string must be more than 4 characters"
    }
}
```

If you don't want terraform to show the sensitive values during run time, add the `sensitive = true` attribute.

**Variable types:**

*Base types:*
- string
- bool
- number

*Complex types:*
- list, set, map, object, tuple
  - list can have duplicate entries
  - set should not have duplicate entries
  - tupe is similar to list, but it can have entries of different types 

*Example list type variable declaration:*

```
variable "availablity_zone" {
    type        = list(string)
    description = "aws availablity_zone"
    default     = ["us-east-1"]
}
```

*Example object type variable declaration:*

```
variable "docker_ports" {
    type = list(object({
        internal = number
        external = number
        protocol = string
    }))
    default = [
        {
            internal = 8300
            external = 8080
            protocol = "TCP"
        }
    ]
}
```

*Example tuple variable declaration:*

```
variable "kitty" {
    type    = tupe([string, int, bool])
    default = ["cat", 1, false]
}
```

**Terraform output values**

```
output "instance_ip" {
    description = "VM's Private IP"
    value       = aws_instance.my_vm.private_ip
}
```

**Variable precedence**

- Environment variables `TF_VAR_VARIABLE_NAME=<VALUE>`
- `terraform.tfvars`
- `*.auto.tfvars` (alphabetical order)
- `-var` or `-var-file` (command line flags) (TAKES HIGHEST PRECEDENCE)

#### Terraform provisioners
---

Terraform way of bootstrapping custom scripts, commands or actions.

Can be run either locally(on the same system where the terraform commands are being executed) or remotely on resources spun up through the terraform deployment.

Within terraform code, each individual resource can have its own provisioner defining the connection method and the actions/commands or script to execute.

There are 2 types of provisioners: `Creation-time` and `Destroy-time` provisioners which you can set to run when a resource is being created or destroyed.

`Note:` Terraform cannot track changes to provisioners as they can take any independent action, hence they are not tracked by terraform state file.

*Example:*

```
resource "null_resource" "dummy_resource" {
    provisioner "local-exec" {
        command = "echo '0' > status.txt"
    }

    provisioner "local-exec" {
        when = destroy
        command = "echo ${self.id} > status.txt"
    }
}
```

If a creation time provisioner fails, terraform will mark that resource as tainted and on the next apply it will try to delete and re-create that resource.

If a destroy time provisioner fails, terraform will try to re-run the provisioner on the next destroy attempt.

#### Interpolation sequence
---

```
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
```

#### Implicit and Explicit Dependency
---

In the below example, terraform builds a dependency tree automatically. `local_file` resource depends on `null_resource`. This is an example of implicit dependency.

```
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
```

In the below example we use the `depends_on` key word explicitly.

```
resource "null_resource" "dummy_resource" {
  provisioner "local-exec" {
    command = "echo ${self.id} > status.txt"
  }
}

resource "local_file" "foo" {
  filename = "foo.txt"
  # ${null_resource.dummy_resource.id} is called as interpolation sequence
  content = "id is ${null_resource.dummy_resource.id}"
  depends_on = [
    null_resource.dummy_resource
  ]
}
```

#### Terraform State
---

It maps the real-world resources to Terraform configuration.

By default the state is stored in a local file called `terraform.tfstate`. Prior to any modification operation, terraform refreshes the state file.

Resource dependency metadata is also tracked via the state file.

**terraform state** command:

- Utility for manipulating and reading the terraform state file.
  - `terraform state list` (list out all the resources tracked by the terraform state file)
  - `terraform state rm` (delete resource from the terraform state file)
  - `terraform state show` (show the details of a resource tracked in the terraform state file)

#### Terraform remote and local state storage
---

Terraform saves the statefiles locally on the system where you execute your commands. This is a default behavior.

It also have an option to store these state files in remote data stores like AWS S3, google storage. This allows storing state file between distributed teams.

**state locking** allows locking state so parallel executions don't coincide.

On a local storage state locking is enabled by default.

Enabled sharing "output" values with other Terraform configuration or code.

```
Project-A ---> TerraformStateFile(Remote Store) --> Project-B (Access the output from Project-A) 
```

#### Persisting terraform state in AWS S3
---

