+++
title = "Resolving DNS Resolution Issues in Minikube for Kubernetes Service "
date = "2024-10-31"
authors = ["nully0x"]
[taxonomies]
tags = ["cloud, k8s"]
+++


When using Kubernetes on Minikube, you might encounter DNS resolution errors that prevent your containers from reaching external resources. This can cause issues for jobs that rely on fetching packages or updates from the internet. A typical error might look like this:

Temporary failure resolving 'deb.debian.org'
WARNING: fetching https://dl-cdn.alpinelinux.org/alpine/v3.18/main: temporary error (try again later)

This guide provides a step-by-step solution to resolve DNS issues in Minikube, configure CoreDNS, and ensure stable access to external repositories.

> Prerequisites:

- Minikube installed and running locally.
- Basic knowledge of Kubernetes, Kubernetes jobs, and how to access Minikube.
- kubectl CLI configured to interact with your Minikube instance.

### Problem Overview

When running a job or pod in Minikube, if you encounter errors indicating DNS failures (like Temporary failure resolving 'deb.debian.org'), this is usually due to DNS misconfiguration within the Minikube environment. Minikube uses CoreDNS for internal DNS resolution, and by default, it forwards DNS requests to the local system’s /etc/resolv.conf. However, this may fail if local DNS configurations are restricted or unreliable.

Here's an example of the type of error you might encounter in job logs:

```bash
Temporary failure resolving 'deb.debian.org'
Failed to fetch http://deb.debian.org/debian/dists/bookworm/InRelease
Unable to locate package kubectl
```

The issue prevents packages from being installed, which can disrupt jobs that need specific tools, like kubectl or ssh-keygen.

> To fix this issue:

- Modify the CoreDNS configuration in Minikube to directly use external DNS servers (e.g., Google’s 8.8.8.8 and Cloudflare’s 1.1.1.1).
- Restart CoreDNS pods to apply changes.
- Verify that DNS resolution is working from within the Minikube cluster.


### Step 1: Edit the CoreDNS ConfigMap

In Kubernetes, DNS settings are managed by the CoreDNS ConfigMap located in the kube-system namespace. Follow these steps to configure CoreDNS to forward requests to reliable external DNS servers.

Run the following command to open the CoreDNS ConfigMap in an editor:

```bash
kubectl edit configmap coredns -n kube-system
```

Update the forward configuration within the Corefile to use external DNS servers 8.8.8.8 and 1.1.1.1 instead of /etc/resolv.conf. Your modified Corefile should look like this for the forward section:

```yaml
forward . 8.8.8.8 1.1.1.1 {
max_concurrent 1000
}
```

Save and close the editor. Kubernetes will automatically apply the ConfigMap changes.

### Step 2: Restart CoreDNS Pods

To apply the DNS changes, the CoreDNS pods need to be restarted:

```bash
kubectl delete pod -n kube-system -l k8s-app=kube-dns
```

This command deletes the existing CoreDNS pods, and Kubernetes will recreate them automatically with the new configuration.

### Step 3: Verify DNS Resolution

Once the CoreDNS pods restart, it’s essential to verify that DNS resolution works correctly within the Minikube environment.

Run a Test Pod: Launch a temporary pod with DNS utilities installed:

```bash
kubectl run -i --tty dnsutils --image=tutum/dnsutils --restart=Never -- /bin/sh
```

Test DNS Resolution: Inside the pod’s shell, test DNS resolution with the following commands:

```bash
nslookup deb.debian.org
ping -c 4 deb.debian.org
```

Expected output for nslookup:

```bash
Server:         8.8.8.8
Address:        8.8.8.8#53

Non-authoritative answer:
deb.debian.org  canonical name = debian.map.fastlydns.net.
Name:   debian.map.fastlydns.net
Address: 151.101.1.130
```

If you see an IP address returned without errors, the DNS is correctly configured.

### Step 4: Retry the Kubernetes Job

With DNS resolution working, re-run any Kubernetes job or pod that was previously failing due to DNS issues.

For example, if you were using a job to generate SSH keys and create a Kubernetes secret, redeploy the job:

```bash
kubectl delete job/pod  <job-name>
kubectl apply -f <your-job-manifest.yaml>
```

Then, monitor the job’s logs to verify that it installs packages successfully:

```bash
kubectl logs -f job/<job-name> (could be pod name as well)
```

### Troubleshooting
Common Errors and Fixes
- Temporary Failure Resolving ‘deb.debian.org’: This error usually means the CoreDNS configuration is not applied correctly. Double-check the forward block in the CoreDNS ConfigMap and ensure that you specified valid DNS IPs.

- No External Connectivity in the Pod: If ping or nslookup fails, the problem may be with Minikube’s network configuration. Restart Minikube and verify that you’re using a network that allows external internet access.

### Resetting DNS to Defaults

If you want to reset the CoreDNS configuration to its default state, simply remove the custom DNS IPs and revert to using /etc/resolv.conf:

```yaml
forward . /etc/resolv.conf {
max_concurrent 1000
}
```

Delete the CoreDNS pods to apply changes.

### Summary

In this guide, we covered how to resolve DNS issues in a Minikube-powered Kubernetes environment by modifying CoreDNS to use reliable external DNS servers. This fix is essential for jobs and pods that require stable internet access to install packages or interact with external APIs.

By following these steps, you should be able to:

- Configure CoreDNS for reliable external DNS.
- Resolve DNS resolution errors in Kubernetes jobs.
- Troubleshoot DNS connectivity in Minikube.
