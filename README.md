# iot-core-external-proxy

ClearBlade provides a default HA Proxy configuration to allow customers to do their own TLS termination for MQTT device connections, as well as use their own domain name.

The default load balancer using HAProxy runs on Google Cloud Compute Instance Group. To install this load balancer, you need the appropriate permissions to create compute instances and configure their network traffic.

## Deploying

Before deploying the infrastructure with terraform you will need to supply your TLS certificates. These should be placed in the `iot-core-external-proxy/certs` directory. Currently the tool expects you to provide the certificate and key as seperate files, in PEM format, with the names `certificate.pem` and `certificate.pem.key`

After the certificates are in place, you will need to update `backend.tf` with your Google Cloud Bucket name you plan to store the terraform state in.

Next, you will need to create a file in the root directory of this repo named `terraform.tfvars` and populate with the below variables:

```
region               = "<region to deploy haproxy instance in (recommend to be the same region as your registry)>"
project_id           = "<google cloud project to deploy in>"
clearblade_ip        = "34.66.220.210"
clearblade_mqtt_ip   = "<relevant IP from below table for your region>"
instances            = 1
```

### ClearBlade MQTT IPs

| Region       | ClearBlade MQTT IP |
| ------------ | ------------------ |
| us-central1  | 35.226.213.106     |
| europe-west1 | 34.140.42.104      |
| asia-east1   | 35.229.234.173     |

Finally, you can deploy the infrastructure using `terraform init` and `terraform apply` commands ran from the root directory of this repo.

## Next Steps

An IP address will be printed as the output of the final `terraform apply` command ran above. This IP address is the public IP of the proxy server, and should be used when configuring your DNS records.
