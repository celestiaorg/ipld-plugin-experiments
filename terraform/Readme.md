```
export DO_API_TOKEN="abcdef01234567890abcdef01234567890"
export SSH_KEY_FILE="$HOME/.ssh/id_rsa.pub"
```

```
terraform init
terraform apply -var DO_API_TOKEN="$DO_API_TOKEN" -var SSH_KEY_FILE="$SSH_KEY_FILE"
```