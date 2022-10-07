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

It is a best practice to define these variables definitions under separate files `variables.tf`.

- `variables.tf`

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

By default the state is stored in a local file called `terraform.tfstate`. Prior to any modification operation, terraform refreshes the state file. When terraform creates a resource it records its identity in the state. Each resource that is created and managed by terraform will have a unique ID, which is used to identiy the resources in the real world.

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

It is recommended best practice to store the backend configuration under `backend.tf`

```
terraform {
    backend "s3" {
        profile = "demo" // aws-cli profile
        region  = "us-east-1" 
        key     = "terraformstatefile"
        bucket  = "somebucketname"
    }
}
```

#### Terraform Modules
---

A module is a container for multiple resources that are used together.

Every terraform configuration has at least one module, called `root` module, which consists of code files in your main working directory.

Once you reference other modules inside your code, these newley refrenced modules are known as child modules, one can pass inputs to and get outputs back from these child modules.

Modules can be downloaded from:

- Terraform public registry
- A private registry
- Your local system
  
Modules are referenced using a `module` block.

```
module "module-name" {
    source  = "./modules/vpc"
    version = "0.0.5"
    region  = var.region
}
```

**Accessing module outputs in your code**

Inside Child Module:

```
output "subnet_id" {
    value = aws_instance.private_ip
}
```

Inside Root Module:

```
resource "aws_instance" "some_name" {
    subnet_id = module.module_name.subnet_id 
}
```

#### Terraform built-in functions
---

Terraform comes pre-packaged with functions to help you transform and combine values.

User-defined functions are not allowed - only built-in ones.

Syntax: `function_name(arg1, arg2, ...)`

These functions allows you to write flexible and dynamic terraform code.

https://www.terraform.io/docs/configuration/functions.html

`terraform console` command provides an interactive CLI that allows us to experiment with built in functions.

#### Variables type constraints
---

https://developer.hashicorp.com/terraform/language/expressions/type-constraints

#### Dynamic Blocks
---

Dynamically constructs repeatable nested configuration blocks inside terraform resources.

Supports within the following block types:
- resource
- data
- provider
- provisioner

https://developer.hashicorp.com/terraform/language/expressions/dynamic-blocks

**Example:** without dynamic block.

```
resource "aws_security_group" "sg" {
    name    = "sg_name"
    vpc_id  = aws_vpc.my_vpc.id
    ingress {
        from_port   = 22
        to_port     = 22
        protocol    = "tcp"
        cidr_blockc = ["1.2.3.4", "5.6.7.8"]
    }
    ingress {
        ...
    }
    ingress {
        ...
    }
}
```

**Example:** with dynamic block.
```
resource "aws_security_group" "sg" {
    name    = "sg_name"
    vpc_id  = aws_vpc.my_vpc.id
    dynamic "ingress" {
        for_each = var.rules
        content {
            from_port   = ingress.value["from_port"] 
            to_port     = ingress.value["to_port"]
            protocol    = ingress.value["proto"]
            cidr_blocks = ingress.value["cidrs"]
        }
    }
}
```

**Note:** Only use dynamic block when you need to hide detail in order to build a cleaner user interface when writing reusable modules.

#### Terraform fmt, taint and import commands
---

- `terraform fmt` formats the code blocks.

- `terraform taint` the taint command basically marks an existing terraform resource forcing it to be deleted and re-created. It modifies the state file only which causes the recreating workflow. During the next terraform apply it deletes the resources and re-creates it.
- Tainting a resource may affect the other resources that are dependent on it to be modified.
- `terraform taint <resource_address>`
- Taint's scenario:
  - To cause provisioners to run. Since provisioners are not tracked by terraform, they are ran during resource creation and deletion.
  - Replace the misbehaving resources forcefully.
  - To mimic the side effects of recreation not modeled by any attributes of the resource.
 
- `terraform import`
  - Maps an existing resource that is not managed by terraform using an **ID**.
  - **ID** is dependent on underlying vendor, for example to import an AWS EC2 instance you will need to provide it's instance ID.
  - `terraform import <Resource_Address> <ID>`
  - Scenarios:
    - When you need to work with the existing resources.
    - Not allowed to create new resources.
    - When you are not in control of creation process of infrastrcture.

#### Terraform workspaces
---

The terraform workspaces are alternate state files withing the same working directory.
Terraform starts with a default workspace that is always called `default`. It cannot be deleted. Each workspace tracks independent copy of statefile against the terraform code in that directory.

**Commands:**

- `terraform workspace new <workspacename>`
- `terraform workspace select <workspacename>`

**Scenarios:**

- Test changes using a parallel, distinct copy of infrastructure.
- It can be modeled against branches in version control such as Git.

Workspaces are meant to share resources and to help enable collaboration. Access to a workspace name is provided through the `${terraform.workspace}` variable.

**Examples:**

```
resource "aws_instance" "example" {
    count = terraform.workspace == "default" ? 5 : 1
    ...
}
```

```
resource "aws_s3_bucket" "example" {
    bucket = "somebucket-${terraform.workspace}"
    acl    = "private"
}
```

#### Debugging Terraform
---

**TF_LOG and TF_LOG_PATH**
- **TF_LOG** is an environment variable for enabling verbose logging in terraform. By default it will send logs to `stderr`
- Can be sent to the following levels: **TRACE**, **DEBUG**, **INFO**, **WARN**, **ERROR**
- **TRACE** is the most reliable one.
- To persist logged output, use the **TF_LOG_PATH** environment variable.

```
export TF_LOG=TRACE
export TF_LOG_PATH=/some/path/log.txt
```

#### Terraform cloud and Enterprise offerings
---

- Best practices to secure terraform code and deployments
  - Hashicorp sentinel
  - Terraform vault provider

**Sentinel**
- Enforces policies on your terraform code. (code that enforces restrictions on your terraform code)
- Sentinel has it's own policy language which you write policies in, this allows you to identify and avoid using dangerous and malicious terraform code written.
- Designed to be approachable by non programmers.
- It runs in terraform enterprise after terraform plan and before terraform apply.

**Usecases**
- For enforcing CIS standards across AWS accounts.
- Checking to make sure only certain type of EC2 instances are allowed to launch.
- Ensuring no security group allows traffic on port 22.
- Ensure all EC2 instances has atleast on tag.

#### Terrafor Vault Provider for injecting secrets securely
---
Hashicorp Vault is a secret management software, it is used to store sensitive data securely and provides short lived temp credentials to the users.
Dynamically provisions credentials and rotates them. Encrypts sensitive data in transit and at rest and provides fine-grained access to secrets using ACL's.