# Deployment Guide

## Kamal Deployment

Catalyst includes Docker containerization and Kamal deployment configuration for easy production deployment.

### Quick Start Commands

```bash
bin/kamal setup                     # Initial server setup
bin/kamal deploy                    # Deploy application  
bin/kamal app logs                  # View application logs
bin/kamal app exec --interactive "bin/rails console"  # Remote console
```

### Available Kamal Commands

```bash
# Deployment
bin/kamal deploy                    # Full deployment
bin/kamal redeploy                  # Redeploy current version
bin/kamal rollback                  # Rollback to previous version

# Application Management  
bin/kamal app start                 # Start application
bin/kamal app stop                  # Stop application
bin/kamal app restart              # Restart application
bin/kamal app logs                  # View logs
bin/kamal app logs -f               # Follow logs
bin/kamal app exec --interactive "bash"  # Shell access

# Server Management
bin/kamal server bootstrap          # Bootstrap servers
bin/kamal server reboot             # Reboot servers
bin/kamal server upgrade            # Upgrade server packages

# Utilities
bin/kamal console                   # Rails console (alias)
bin/kamal shell                     # Bash shell (alias)
bin/kamal dbc                       # Database console (alias)
```

## Configuration

### Main Configuration: `config/deploy.yml`

```yaml
# Service configuration
service: catalyst
image: your-user/catalyst

# Server configuration
servers:
  web:
    - 192.168.0.1

# SSL and domain
proxy:
  ssl: true
  host: app.example.com

# Registry credentials  
registry:
  username: your-user
  password:
    - KAMAL_REGISTRY_PASSWORD

# Environment variables
env:
  secret:
    - RAILS_MASTER_KEY
  clear:
    SOLID_QUEUE_IN_PUMA: true
```

### Key Configuration Sections

#### SSL Configuration
```yaml
proxy:
  ssl: true                    # Enable SSL
  host: app.example.com        # Your domain
  # Automatic Let's Encrypt certificates
```

#### Database and Storage
```yaml
volumes:
  - "catalyst_storage:/rails/storage"   # Persistent storage

# For external database
env:
  clear:
    DB_HOST: 192.168.0.2              # Database server IP
```

#### Background Jobs
```yaml
env:
  clear:
    SOLID_QUEUE_IN_PUMA: true         # Run jobs in web process
    JOB_CONCURRENCY: 3               # Job worker threads
    WEB_CONCURRENCY: 2               # Web worker processes
```

#### Asset Management  
```yaml
asset_path: /rails/public/assets      # Fingerprinted assets
```

## Pre-Deployment Setup

### 1. Server Requirements
- Ubuntu 20.04+ or similar Linux distribution
- Docker installed
- SSH access with key-based authentication
- Open ports: 80, 443, 22

### 2. DNS Configuration
```bash
# Point your domain to server IP
app.example.com.    A    192.168.0.1
```

### 3. Environment Variables
Create `.kamal/secrets` file:
```bash
RAILS_MASTER_KEY=your-rails-master-key
KAMAL_REGISTRY_PASSWORD=your-docker-registry-password
```

### 4. Docker Registry
```bash
# Docker Hub (default)
docker login
export KAMAL_REGISTRY_PASSWORD=your-docker-password

# GitHub Container Registry
docker login ghcr.io
export KAMAL_REGISTRY_PASSWORD=your-github-token
```

## Initial Deployment

### 1. Update Configuration
```bash
# Edit config/deploy.yml
service: your-app-name
image: your-user/your-app-name
servers:
  web:
    - your.server.ip
proxy:
  host: your-domain.com
registry:
  username: your-docker-username
```

### 2. Server Bootstrap
```bash
bin/kamal server bootstrap
```

### 3. Application Setup
```bash
bin/kamal setup
```

### 4. First Deployment
```bash
bin/kamal deploy
```

## Production Checklist

### Security
- [ ] Set `RAILS_MASTER_KEY` in Kamal secrets
- [ ] Configure `KAMAL_REGISTRY_PASSWORD` for Docker registry
- [ ] Use SSH keys, not passwords
- [ ] Configure firewall (allow only 80, 443, 22)
- [ ] Enable automatic security updates

### Configuration
- [ ] Update `config/deploy.yml` with your server IPs and domain
- [ ] Set up DNS records pointing to your server
- [ ] Configure SSL certificates (automatic with Let's Encrypt)
- [ ] Set appropriate `WEB_CONCURRENCY` and `JOB_CONCURRENCY`

### Monitoring
- [ ] Set up log monitoring
- [ ] Configure uptime monitoring
- [ ] Set up error tracking (e.g., Sentry, Rollbar)
- [ ] Monitor disk usage for SQLite database

### Backups
- [ ] Set up database backups (SQLite files in storage volume)
- [ ] Configure file storage backups
- [ ] Test restore procedures

## Common Deployment Patterns

### Zero-Downtime Deployment
```bash
# Kamal deploys are zero-downtime by default
bin/kamal deploy
```

### Rolling Back
```bash
# Rollback to previous version
bin/kamal rollback

# Check deployment history
bin/kamal app images
```

### Maintenance Mode
```bash
# Put site in maintenance mode
bin/kamal app stop

# Bring back online
bin/kamal app start
```

### Database Migrations
```bash
# Migrations run automatically during deploy
# To run manually:
bin/kamal app exec "bin/rails db:migrate"
```

## Troubleshooting

### Deployment Issues

**Build fails:**
```bash
# Check build logs
bin/kamal build logs

# Build locally to debug
docker build .
```

**Deploy fails:**
```bash
# Check server logs
bin/kamal app logs

# SSH to server for debugging
ssh root@your.server.ip
docker ps
```

**SSL issues:**
```bash
# Check SSL certificate status
bin/kamal proxy logs

# Manual certificate renewal
bin/kamal proxy exec "certbot renew"
```

### Performance Issues

**High memory usage:**
```yaml
# Reduce worker processes
env:
  clear:
    WEB_CONCURRENCY: 1
    JOB_CONCURRENCY: 1
```

**Database performance:**
```bash
# Monitor SQLite performance
bin/kamal app exec "bin/rails db:migrate:status"
bin/kamal app exec "sqlite3 storage/production.sqlite3 '.schema'"
```

### Monitoring Commands

```bash
# System resources
bin/kamal app exec "df -h"        # Disk usage
bin/kamal app exec "free -h"      # Memory usage
bin/kamal app exec "top"          # Process list

# Application health
bin/kamal app exec "bin/rails runner 'puts Rails.application.config.database_configuration'"
bin/kamal app exec "bin/rails console" # Interactive debugging
```

## Advanced Configuration

### Multiple Environments
```yaml
# config/deploy.staging.yml
service: catalyst-staging
proxy:
  host: staging.example.com
```

```bash
# Deploy to staging
bin/kamal deploy -c config/deploy.staging.yml
```

### Database Accessories
```yaml
accessories:
  db:
    image: mysql:8.0
    host: 192.168.0.2
    port: "127.0.0.1:3306:3306" 
    env:
      secret:
        - MYSQL_ROOT_PASSWORD
    directories:
      - data:/var/lib/mysql
```

### Build Arguments
```yaml
builder:
  args:
    RUBY_VERSION: ruby-3.4.5
  secrets:
    - GITHUB_TOKEN
```

## Monitoring and Logs

### Log Management
```bash
# Application logs
bin/kamal app logs -f

# System logs  
bin/kamal proxy logs
bin/kamal app exec "tail -f /var/log/syslog"

# Log rotation
bin/kamal app exec "logrotate -f /etc/logrotate.conf"
```

### Health Checks
```bash
# Built-in health check
curl https://your-domain.com/up

# Custom health monitoring
bin/kamal app exec "bin/rails runner 'puts ActiveRecord::Base.connection.active?'"
```