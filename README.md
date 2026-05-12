# Magento 2 DevOps Assessment — Dockerised Stack on AWS

## Overview

This project deploys a production-style Magento 2.4.7 e-commerce stack on a single AWS EC2 instance using Docker Compose. All services run in isolated containers connected through internal Docker networks. Only NGINX is publicly exposed on ports 80 and 443.

The deployment was intentionally designed to operate within AWS Free Tier constraints while maintaining:

* HTTPS accessibility
* Dockerized architecture
* Redis integration
* OpenSearch integration
* Reverse proxy caching
* Persistent storage
* Resource optimization
* Magento storefront and admin functionality

---

# Architecture

```text
Browser
   │
   ▼
NGINX:443
(SSL termination, HTTP→HTTPS redirect, static files)
   │
   ▼
Varnish:6081
(Full-page cache)
   │
   ▼
NGINX:8080
(Internal Magento backend)
   │
   ▼
PHP-FPM:9000
(Magento application)
   │
   ├── MySQL:3306
   ├── Redis:6379
   └── OpenSearch:9200

phpMyAdmin
(Reverse proxied through NGINX with Basic Authentication)

Cron
(Magento scheduled tasks)
```

---

# Docker Networks

| Network  | Purpose                          |
| -------- | -------------------------------- |
| frontend | Public-facing traffic            |
| backend  | Internal container communication |

Only NGINX is attached to both networks. All backend services remain isolated internally.

---

# AWS Infrastructure

| Property       | Value                          |
| -------------- | ------------------------------ |
| Cloud Provider | AWS                            |
| Instance Type  | t3.micro                       |
| vCPU           | 1                              |
| Memory         | 1 GB                           |
| OS             | Debian GNU/Linux 12 (Bookworm) |
| Region         | ap-south-1                     |
| Elastic IP     | 3.111.92.169                   |
| Storage        | 30 GB gp3                      |
| Swap           | 4 GB                           |

The entire deployment operates within AWS Free Tier limits.

---

# Reviewer Access

## Hosts File Entry

Add the following line to your local hosts file:

```text
3.111.92.169 test.dyna.com
```

## URLs

| Resource    | URL                                 |
| ----------- | ----------------------------------  |
| Storefront  | https://test.dyna.com               |
| Admin Panel | https://test.dyna.com/admin_pn9srs7 |
| phpMyAdmin  | https://test.dyna.com/pma/          |

Because self-signed TLS is used, browsers may show a certificate warning that can safely be bypassed for testing purposes.

---

# Security Group Configuration

| Port | Protocol | Purpose                           |
| ---- | -------- | --------------------------------- |
| 22   | TCP      | SSH administrative access         |
| 80   | TCP      | HTTP redirect to HTTPS            |
| 443  | TCP      | HTTPS storefront and admin access |

No database, Redis, OpenSearch, or internal application ports are exposed publicly.

---

# SSH Security

* SSH authentication is key-based only
* Password authentication disabled
* Security Group restricts SSH access
* Administrative access limited to trusted IPs

---

# Container Stack

| Container  | Purpose                         |
| ---------- | ------------------------------- |
| nginx      | SSL termination + reverse proxy |
| varnish    | Full-page cache                 |
| php        | Magento PHP-FPM application     |
| mysql      | Magento database                |
| redis      | Cache + sessions                |
| opensearch | Catalog search engine           |
| phpmyadmin | Database management             |
| cron       | Magento scheduled jobs          |

Each service runs in its own dedicated container.

---

# Magento Installation

## Installed Components

* Magento 2 Open Source 2.4.7
* Magento Sample Data
* Redis integration
* OpenSearch integration
* HTTPS base URLs
* Custom admin URL
* Varnish integration

---

# HTTPS Configuration

HTTPS enabled using self-signed TLS certificates.

## Features

* HTTP → HTTPS redirect
* TLSv1.2 and TLSv1.3 enabled
* HTTP/2 enabled
* SSL configured through NGINX
* Self-signed certificate with SAN support

## Certificate Validation

```bash
curl -k -I https://test.dyna.com
```

---

# NGINX Configuration

NGINX responsibilities:

* TLS termination
* Reverse proxy
* Static asset serving
* PHP-FPM upstream proxy
* Varnish frontend integration

## Magento Static Asset Fix

The following configuration resolved Magento frontend asset rendering issues:

```nginx
location /static/ {
    expires max;
    access_log off;

    try_files $uri $uri/ /static.php?resource=$uri&$args;
}
```

---

# Varnish Configuration

Varnish 7.x deployed as a reverse proxy cache layer.

## Responsibilities

* Full-page caching
* Reduced PHP load
* Faster storefront responses
* Static asset acceleration

## Cache Logic

| Request Type       | Action |
| ------------------ | ------ |
| Anonymous GET/HEAD | Cached |
| Static assets      | Cached |
| Admin requests     | Passed |
| Checkout/customer  | Passed |
| POST requests      | Passed |

## Example Validation

```bash
curl -Ik --resolve test.dyna.com:443:127.0.0.1 https://test.dyna.com
```

---

# Redis Configuration

Redis configured for:

* Default cache
* Full-page cache
* Session storage

## Redis Databases

| DB | Purpose         |
| -- | --------------- |
| 0  | Default cache   |
| 1  | Full-page cache |
| 2  | Sessions        |

---

# OpenSearch Optimization

OpenSearch required aggressive tuning due to Free Tier memory constraints.

## Optimizations Applied

* Reduced Java heap size
* Lower memory footprint
* Single-node configuration
* Limited background overhead

## Heap Configuration

```bash
OPENSEARCH_JAVA_OPTS="-Xms128m -Xmx128m"
```

Purpose:

* Prevent OOM kills
* Stabilize PHP-FPM
* Maintain system responsiveness

---

# PHP-FPM Optimization

## Pool Configuration

```ini
pm = ondemand
pm.max_children = 5
pm.process_idle_timeout = 10s
pm.max_requests = 100
```

## Reasoning

The t3.micro instance provides only:

* 1 GB RAM
* 1 vCPU

`ondemand` mode prevents idle PHP workers from consuming memory continuously.

This significantly reduced:

* memory pressure
* container instability
* PHP worker exhaustion

---

# PHP Optimization

## php.ini Tuning

```ini
memory_limit = 512M
max_execution_time = 1800
max_input_time = 1800
```

## OPcache

```ini
opcache.enable=1
opcache.memory_consumption=128
opcache.max_accelerated_files=4000
```

Purpose:

* improve Magento performance
* reduce repeated PHP parsing
* reduce CPU utilization

---

# Swap Configuration

Swap memory was required because Magento, OpenSearch, MySQL, and PHP-FPM exceeded available RAM during peak load.

## Swap Creation

```bash
fallocate -l 4G /swapfile
chmod 600 /swapfile
mkswap /swapfile
swapon /swapfile
```

Purpose:

* prevent OOM kills
* stabilize containers
* improve service reliability

---

# Filesystem Ownership & Permissions

Containers run as non-root user:

```bash
uid=1001(test-ssh)
gid=1001(clp)
```

Writable Magento directories:

* var/
* generated/
* pub/static/
* pub/media/

---

# phpMyAdmin

phpMyAdmin is reverse proxied through NGINX and protected with HTTP Basic Authentication.

It is not directly exposed through Docker port publishing.

This reduces attack surface while still allowing controlled administrative access.

---

# Magento Cron

Magento cron runs in a dedicated container.

During validation and troubleshooting, cron workload was temporarily minimized to reduce memory pressure on the Free Tier instance.

In production, cron and indexers would typically run on separate worker infrastructure.

---

# Data Persistence

Persistent Docker volumes used for:

| Volume          | Purpose                   |
| --------------- | ------------------------- |
| mysql_data      | Database storage          |
| redis_data      | Cache/session persistence |
| opensearch_data | Search indexes            |

Magento application directories are bind-mounted from the host filesystem.

---

# Troubleshooting Performed

## Issues Encountered

* Magento static asset 404 errors
* Broken frontend rendering
* PHP-FPM SIGKILL events
* OpenSearch memory pressure
* 503 backend fetch failures
* HTTPS routing problems
* NGINX fallback configuration issues

---

# Key Resolutions Applied

## Static Asset Resolution

try_files $uri $uri/ /static.php?resource=$uri&$args;


## Resource Stabilization

* Reduced OpenSearch heap
* Optimized PHP-FPM workers
* Added swap memory
* Reduced unnecessary background load
* Regenerated Magento static assets
* Flushed Magento cache

---

# Magento Commands Used

## Static Content Deployment

php -d memory_limit=-1 bin/magento setup:static-content:deploy -f

## Reindex

php bin/magento indexer:reindex

## Cache Flush

php bin/magento cache:flush

---

# Final Validation

Successfully validated:

* HTTPS storefront access
* Magento admin access
* Static asset rendering
* Redis connectivity
* OpenSearch indexing
* Varnish reverse proxy flow
* Container health checks
* Docker persistence after restart
* Magento cache operations
* Magento indexing operations

---

# Known Limitations & Production Improvements

## Current Constraints

* Self-signed TLS certificate
* Single EC2 instance deployment
* No horizontal scaling
* Free Tier resource limitations

## Production Improvements

In production environments I would:

- use AWS ACM or Let’s Encrypt
- move MySQL to Amazon RDS
- deploy stateless services on ECS/EKS
- implement Secrets Manager
- enable centralized monitoring and alerting
- separate cron/indexers into worker nodes
- implement CI/CD pipelines

---

# Useful Commands

## View Containers

docker ps

## Restart Services

docker compose restart nginx php

## View Logs

docker logs nginx --tail 20
docker logs php --tail 20

## Enter PHP Container

docker exec -it php bash

---

# Repository

https://github.com/AkshaySuruse/magento-devops-assessment

---

# Conclusion

This project demonstrates deployment and optimization of a production-style Magento 2 stack on AWS Free Tier infrastructure using Docker Compose.

The environment successfully delivers:

- containerized architecture
- HTTPS security
- Redis integration
- OpenSearch integration
- Varnish caching
- Magento storefront/admin functionality
- operational troubleshooting
- infrastructure optimization
- resource-aware engineering

while remaining within the constraints of a single t3.micro EC2 instance.

