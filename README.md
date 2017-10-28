# ipfs-terraform-template

## Usage

- Go into `gateways` folder: `cd gateways`
- Copy `terraform.tfvars.dist` to `terraform.tfvars`, changing the vars to your own: `cp terraform.tfvars.dist terraform.tfvars && vim terraform.tfvars`
- Run `terraform init`
- Run `terraform plan -out wanted-change`, and confirm the changes
- Run `terraform apply wanted-change`
