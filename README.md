Terraform scripts to create an affordable Kubernetes Cluster hosted in a Public Cloud and trying to use affordable cloud resources (~7 euros/month).
The Kubernetes Cluster will be built on top of cheaper resources or something like [AWS Spot Instances](https://aws.amazon.com/ec2/spot) or [Google Cloud Preemptible VM Instances](https://cloud.google.com/preemptible-vms).

These Terraform scripts are based in the `0.2.1-chilcano` branch of [forked GitHub repo](https://github.com/chilcano/kubeadm-aws). 

## Design of Kubernetes Cluster

![affordablek8s-aws-01-arch-ingress-dns-tls-cert-manager](/docs/20200129-affordablek8s-aws-01-arch-ingress-dns-tls-cert-manager.png)

### Kubernetes versions tested

K8s version | Worked? | Observations
---         | ---     | ---
[1.13.12](https://github.com/kubernetes/kubernetes/releases/tag/v1.13.12)  | Yes     | N/A
[1.14.3](https://github.com/kubernetes/kubernetes/releases/tag/v1.14.3)    | Yes     | N/A
[1.14.10](https://github.com/kubernetes/kubernetes/releases/tag/v1.14.10)  | Yes     | N/A
[1.15.3](https://github.com/kubernetes/kubernetes/releases/tag/v1.15.3)    | ???     | ???
[1.15.10](https://github.com/kubernetes/kubernetes/releases/tag/v1.15.10)  | ???     | ???
[1.16.3](https://github.com/kubernetes/kubernetes/releases/tag/v1.16.3)    | ???     | ???
[1.16.7](https://github.com/kubernetes/kubernetes/releases/tag/v1.16.7)    | ???     | ???
[1.17.3](https://github.com/kubernetes/kubernetes/releases/tag/v1.17.3)    | ???     | ???

### Components included


Component                | Version | Observations
---                      | ---     | ---
[Helm](https://helm.sh)                                                 | 2.12.0  | The `k8s_master.sh` bash installs it downloading the [helm-v2.12.0-linux-amd64.tar.gz](https://storage.googleapis.com/kubernetes-helm/helm-v2.12.0-linux-amd64.tar.gz) and running its installation process.
[NGINX Ingress Controller](https://github.com/kubernetes/ingress-nginx) | 0.20.0  | Terraform installs it through `nginx-ingress-mandatory.yaml` (quay.io/kubernetes-ingress-controller/nginx-ingress-controller:0.20.0)
[Jetstack Cert-Manager](https://cert-manager.io)                        | 0.13.1  | The `k8s_master.sh` bash installs it running `kubectl apply cert-manager.yaml`.
[External-DNS](https://github.com/kubernetes-sigs/external-dns)         | 0.5.8   | Terraform installs it through `external-dns.yaml` (registry.opensource.zalan.do/teapot/external-dns:v0.5.8)

## Samples


**1) Simple K8s Cluster (1 Master, 1 Worker)**

...

**2) K8s Cluster (1 Master, 1 Worker) with Ingress, TLS and Router 53 custom DNS**

```sh
$ terraform init

$ terraform plan \
  -var cluster_name="cheapk8s" \
  -var k8s_ssh_key="ssh-key-for-us-east-1" \
  -var admin_cidr_blocks="83.45.101.2/32" \
  -var region="us-east-1" \
  -var kubernetes_version="1.14.3" \
  -var external_dns_enabled="1" \
  -var nginx_ingress_enabled="1" \
  -var nginx_ingress_domain="ingress-nginx.cloud.holisticsecurity.io" \
  -var cert_manager_enabled="1" \
  -var cert_manager_email="cheapk8s@holisticsecurity.io"

$ terraform apply \
  -var cluster_name="cheapk8s" \
  -var k8s_ssh_key="ssh-key-for-us-east-1" \
  -var admin_cidr_blocks="83.45.101.2/32" \
  -var region="us-east-1" \
  -var kubernetes_version="1.14.3" \
  -var external_dns_enabled="1" \
  -var nginx_ingress_enabled="1" \
  -var nginx_ingress_domain="ingress-nginx.cloud.holisticsecurity.io" \
  -var cert_manager_enabled="1" \
  -var cert_manager_email="cheapk8s@holisticsecurity.io"

# Check installation
$ ssh ubuntu@$(terraform output master_dns) -i ~/Downloads/ssh-key-for-us-east-1.pem -- cat /var/log/cloud-init-output.log
  
$ terraform destroy \
  -var cluster_name="cheapk8s" \
  -var k8s_ssh_key="ssh-key-for-us-east-1" \
  -var admin_cidr_blocks="83.45.101.2/32" \
  -var region="us-east-1" \
  -var kubernetes_version="1.14.3" \
  -var external_dns_enabled="1" \
  -var nginx_ingress_enabled="1" \
  -var nginx_ingress_domain="ingress-nginx.cloud.holisticsecurity.io" \
  -var cert_manager_enabled="1" \
  -var cert_manager_email="cheapk8s@holisticsecurity.io"

# Removing unwanted records in our AWS Hosted Zone
$ export MY_SUBDOMAIN="cloud.holisticsecurity.io"
$ export HZ_ID=$(aws route53 list-hosted-zones-by-name --dns-name "${MY_SUBDOMAIN}." | jq -r '.HostedZones[0].Id')
$ aws route53 list-resource-record-sets --hosted-zone-id $HZ_ID --query "ResourceRecordSets[?Name != '${MY_SUBDOMAIN}.']" | jq -c '.[]' |
  while read -r RRS; do
    read -r name type <<< $(jq -jr '.Name, " ", .Type' <<< "$RRS") 
    CHG_ID=$(aws route53 change-resource-record-sets --hosted-zone-id $HZ_ID --change-batch '{"Changes":[{"Action":"DELETE","ResourceRecordSet": '"$RRS"' }]}' --output text --query 'ChangeInfo.Id')
    echo " - DELETING: $type $name - CHANGE ID: $CHG_ID"    
  done
```

## ToDo

...

**References:**

- aws-terraform-kubeAdm
  * [https://github.com/graykode/aws-kubeadm-terraform](https://github.com/graykode/aws-kubeadm-terraform)
- terraform-provider-kubeadm
  * [https://github.com/inercia/terraform-provider-kubeadm](https://github.com/inercia/terraform-provider-kubeadm)
- Kubernetes Cluster Provisioner (Terraform + Ansible + AWS + Kubespray)
  * [https://github.com/alicek106/aws-terraform-kubernetes](https://github.com/alicek106/aws-terraform-kubernetes)
- Build Your Own K8S or with Installers like kops, kubeadm, and, kubicorn
  * [https://www.weave.works/technologies/kubernetes-installation-options/](https://www.weave.works/technologies/kubernetes-installation-options/)
- Kubernetes clusters for the hobbyist
  * [https://github.com/hobby-kube/guide](https://github.com/hobby-kube/guide)