To run the experiments, run the following commands:
```
cd terraform/
# initialize working directory:
terraform init
# provision the droplets and run the experiments:
terraform apply -var="DO_API_TOKEN=use_your_own_do_token" -var="SSH_KEY_FILE=$HOME/.ssh/id_rsa.pub" -var="pvt_key=$HOME/.ssh/id_rsa" -var="NODES=10" -var="ROUNDS=25" -var="NUM_doctlLEAVES=32"
```

Check out [variables.tf](./variables.tf) for more variables. These variables can be assigned on the commandline. 
Check out the terraform [documentation](https://www.terraform.io/docs/configuration/variables.html#assigning-values-to-root-module-variables) 
on assigning variables. 

To destroy the droplets that were created above afterwards:
```
terraform destroy -var="DO_API_TOKEN=use_your_own_do_token" -var="SSH_KEY_FILE=$HOME/.ssh/id_rsa.pub" -var="pvt_key=$HOME/.ssh/id_rsa"
```
