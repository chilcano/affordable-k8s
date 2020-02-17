Terraform scripts to create an affordable Kubernetes Cluster hosted in affordable Public Cloud (~7 euros/month).
The Kubernetes Cluster will be built on top of cheaper resources or something like [AWS Spot Instances](https://aws.amazon.com/ec2/spot) or [Google Cloud Preemptible VM Instances](https://cloud.google.com/preemptible-vms).

These Terraform scripts are based in the `0.2.1-chilcano` branch of [forked GitHub repo](https://github.com/chilcano/kubeadm-aws). 

## Creating Kubernetes Cluster

### AWS samples

![affordablek8s-aws-01-arch-ingress-dns-tls-cert-manager](20200129-affordablek8s-aws-01-arch-ingress-dns-tls-cert-manager.png)

**1) Simple K8s Cluster (1 Master, 1 Worker)**

...

**2) K8s Cluster (1 Master, 1 Worker) with Ingress and Router 53 custom DNS**

....

### Google samples

...

## ToDo

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