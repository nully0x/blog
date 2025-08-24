+++
title = "A note on provisioning SSL on cloud instance or VPS"
date = "2024-08-02"
authors = ["nully0x"]
[taxonomies]
tags = ["cloud"]
+++

## Introduction

Securing websites with SSL/TLS certificates is crucial for protecting user data and maintaining trust. This article is a guide on provisioning SSL certificates using Let's Encrypt and managing an Nginx web server on EC2 or any Virtual Private Server (VPS).

## Provisioning SSL Certificates with Let's Encrypt

Let's Encrypt offers a free and automated way to obtain SSL/TLS certificates. Here's how to provision an SSL certificate on your EC2 instance or VPS:

### Installing Certbot

Certbot is the official client for Let's Encrypt. To install it on Ubuntu with Nginx:

```bash
sudo apt-get update
sudo apt-get install certbot python3-certbot-nginx
```

### Obtaining the Certificate

With Certbot installed, you can obtain an SSL certificate:

```bash
sudo certbot --nginx
```

This command will guide you through the process, asking for your domain name and handling the Nginx configuration automatically.

### Choosing the Authentication Method

Let's Encrypt typically uses HTTP validation for domain verification. Certbot handles this process automatically by temporarily modifying your web server configuration.

### Setting Up Automatic Renewal

Let's Encrypt certificates are valid for 90 days. Set up automatic renewal to maintain uninterrupted SSL protection:

1. Test the renewal process:
   ```bash
   sudo certbot renew --dry-run
   ```

2. Enable automatic renewal (on systems with systemd):
   ```bash
   sudo systemctl enable certbot.timer
   sudo systemctl start certbot.timer
   ```

## Managing Nginx Web Server

Efficient management of your Nginx server is crucial for maintaining a secure and performant web presence.

### Basic Nginx Management Commands

- Start Nginx: `sudo systemctl start nginx`
- Stop Nginx: `sudo systemctl stop nginx`
- Restart Nginx: `sudo systemctl restart nginx`

### Applying Configuration Changes

After modifying Nginx configuration files, apply changes without service interruption:

```bash
sudo systemctl reload nginx
```

### Monitoring Nginx Status

Check the current status of Nginx:

```bash
sudo systemctl status nginx
```

## Best Practices and Considerations

1. Regularly check Nginx error logs at `/var/log/nginx/error.log` for potential issues.
2. Keep your system and Nginx up to date to protect against vulnerabilities.
3. Use `sudo systemctl enable nginx` to ensure Nginx starts automatically on system boot.
4. Customize your Nginx configuration to optimize performance and security for your specific needs.

## Conclusion

Provisioning SSL certificates with Let's Encrypt and effectively managing your Nginx web server are essential skills for maintaining a secure and reliable web presence on EC2 or any VPS. By following this guide, you can ensure your website is protected with HTTPS and your web server is running smoothly.

For more detailed information, consult the [Certbot documentation](https://certbot.eff.org/) and the [Nginx documentation](https://nginx.org/en/docs/).
