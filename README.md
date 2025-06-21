# Nagios Infrastructure Monitoring Installation Script

![Nagios Logo]([https://www.nagios.org/wp-content/uploads/2015/05/Nagios-Black-500x124.png](https://www.nagios.org/))

A comprehensive automated installation script for deploying Nagios infrastructure monitoring platform with Docker, Nginx reverse proxy, and SSL certificates.

## 🚀 Features

- **Complete Monitoring Solution**: Full Nagios Core installation with web interface
- **Automated Installation**: Minimal user input required for complete setup
- **Docker-based**: Uses proven Nagios Docker image for easy management
- **SSL/HTTPS Support**: Automatic SSL certificate generation with Let's Encrypt
- **Nginx Reverse Proxy**: Professional web server configuration with security headers
- **Pre-configured Monitoring**: Built-in host and service checks for immediate use
- **Email Notifications**: Automated alert notifications via email
- **Security Hardened**: Modern security practices and authentication
- **Management Scripts**: Built-in scripts for easy maintenance and configuration
- **Custom Plugin Support**: Directory structure for custom monitoring plugins

## 📋 Prerequisites

### System Requirements
- **OS**: Ubuntu 18.04+ / Debian 10+ / CentOS 7+
- **RAM**: Minimum 1GB (recommended 2GB+)
- **Disk Space**: Minimum 5GB free space
- **Network**: Public IP address with domain pointing to it
- **Privileges**: Root access or sudo privileges
- **Email**: SMTP server or mail relay for notifications

### Required Ports
- **80**: HTTP (for SSL certificate validation)
- **443**: HTTPS (Nginx reverse proxy)
- **8080**: Nagios Web Interface (localhost only, configurable)

## 🛠 Installation

### Quick Start

1. **Clone the repository**:
   ```bash
   git clone https://github.com/defendx1/Nagios.git
   cd Nagios
   chmod +x install-nagios.sh
   ```

   **Or download directly**:
   ```bash
   wget https://raw.githubusercontent.com/defendx1/Nagios/main/install-nagios.sh
   chmod +x install-nagios.sh
   ```

2. **Run the installation**:
   ```bash
   sudo ./install-nagios.sh
   ```

3. **Follow the prompts**:
   - Enter your domain name (e.g., `nagios.yourdomain.com`)
   - Provide email for SSL certificate
   - Set admin username (default: nagiosadmin)
   - Set admin password for web interface
   - Configure alert email address

### Manual Installation Steps

The script automatically handles:
- ✅ Docker and Docker Compose installation
- ✅ Nginx web server installation
- ✅ Certbot for SSL certificates
- ✅ System requirements validation
- ✅ Port conflict resolution
- ✅ Directory structure creation
- ✅ Nagios configuration files
- ✅ Host and service definitions
- ✅ SSL certificate generation
- ✅ Nginx reverse proxy setup

## 🔧 Configuration

### Default Access
- **URL**: `https://your-domain.com`
- **Username**: Set during installation (default: nagiosadmin)
- **Password**: Set during installation
- **Alert Email**: Configured during setup

### Docker Services
The installation creates the following container:
- `nagios`: Complete Nagios Core with web interface and monitoring engine

### File Structure
```
/opt/nagios-docker/
├── docker-compose.yml          # Main Docker Compose configuration
├── .env                        # Environment variables
├── manage-nagios.sh           # Management script
├── nagios-etc/                # Nagios configuration directory
│   ├── nagios.cfg             # Main Nagios configuration
│   ├── objects/               # Object definitions
│   │   ├── contacts.cfg       # Contact definitions
│   │   └── commands.cfg       # Command definitions
│   └── conf.d/                # Host and service configurations
│       ├── hosts.cfg          # Host definitions
│       └── services.cfg       # Service definitions
├── nagios-var/                # Nagios runtime data
├── custom-plugins/            # Custom monitoring plugins
└── apache-logs/               # Web server logs
```

## 🎮 Management Commands

Use the built-in management script for easy operations:

```bash
cd /opt/nagios-docker

# Start Nagios
./manage-nagios.sh start

# Stop Nagios
./manage-nagios.sh stop

# Restart Nagios
./manage-nagios.sh restart

# View logs
./manage-nagios.sh logs

# Check status
./manage-nagios.sh status

# Create backup
./manage-nagios.sh backup

# Update Nagios
./manage-nagios.sh update

# Reload configuration (validates and restarts if valid)
./manage-nagios.sh reload-config
```

## 🔐 Security Features

### SSL/TLS Configuration
- **TLS 1.2/1.3** support only
- **HSTS** (HTTP Strict Transport Security) headers
- **Security headers**: X-Content-Type-Options, X-Frame-Options, X-XSS-Protection
- **Automatic HTTP to HTTPS** redirection

### Authentication & Authorization
- **Web-based authentication** with customizable credentials
- **Session management** for secure web interface access
- **Role-based access control** through Nagios user configuration

### Network Security
- Nagios accessible only through Nginx proxy
- Local-only binding for Nagios service
- Configurable port assignments to avoid conflicts

## 📊 Monitoring Capabilities

### Pre-configured Monitoring

The installation includes essential monitoring checks:

1. **System Resources**:
   - **Disk Space**: Root partition usage monitoring
   - **CPU Load**: System load average monitoring
   - **Process Count**: Total running processes
   - **User Sessions**: Current logged-in users

2. **Host Monitoring**:
   - **Host Availability**: Ping-based reachability checks
   - **Host Status**: Up/Down monitoring with notifications

3. **Service Monitoring**:
   - **Service Availability**: Critical service status monitoring
   - **Performance Metrics**: Response times and resource usage

### Built-in Alert Rules

- **Critical Alerts**: Host down, service failures
- **Warning Alerts**: High resource usage, performance degradation
- **Recovery Notifications**: Service restoration alerts
- **Escalation Policies**: Configurable notification escalation

### Notification System

- **Email Notifications**: Instant alert delivery via email
- **Alert States**: OK, Warning, Critical, Unknown status tracking
- **Notification Scheduling**: Time-based notification controls
- **Contact Groups**: Organized notification management

## 🔧 Adding Monitoring Targets

### Adding New Hosts

Edit `/opt/nagios-docker/nagios-etc/conf.d/hosts.cfg`:

```cfg
define host {
    use                    linux-server
    host_name              web-server-01
    alias                  Web Server 01
    address                192.168.1.100
    contact_groups         admins
    notification_interval  30
    notification_period    24x7
}
```

### Adding Services

Edit `/opt/nagios-docker/nagios-etc/conf.d/services.cfg`:

```cfg
define service {
    use                    generic-service
    host_name              web-server-01
    service_description    HTTP Service
    check_command          check_http
    contact_groups         admins
    notification_interval  30
}
```

### Custom Commands

Add custom monitoring commands in `/opt/nagios-docker/nagios-etc/objects/commands.cfg`:

```cfg
define command {
    command_name    check_custom_service
    command_line    $USER1$/check_custom_service -H $HOSTADDRESS$ -p $ARG1$
}
```

## 🔔 Notification Configuration

### Email Setup

Configure email notifications by editing the contacts configuration:

```cfg
define contact {
    contact_name           admin
    use                   generic-contact
    alias                 System Administrator
    email                 admin@yourdomain.com
    service_notification_period    24x7
    host_notification_period       24x7
    service_notification_options   w,u,c,r
    host_notification_options      d,u,r
}
```

### SMTP Configuration

For external SMTP servers, configure in the Docker environment:

```yaml
environment:
  - MAIL_RELAY_HOST=smtp.gmail.com
  - MAIL_RELAY_PORT=587
  - MAIL_RELAY_USER=your-email@gmail.com
  - MAIL_RELAY_PASS=your-app-password
```

## 🔄 Backup and Restore

### Automated Backup
```bash
./manage-nagios.sh backup
```
Creates timestamped backup including:
- Complete Nagios configuration
- Historical monitoring data
- Custom plugins and scripts

### Manual Backup
```bash
# Stop Nagios
./manage-nagios.sh stop

# Create backup
tar -czf nagios-backup-$(date +%Y%m%d).tar.gz /opt/nagios-docker/

# Start Nagios
./manage-nagios.sh start
```

### Restore Process
```bash
# Stop Nagios
./manage-nagios.sh stop

# Restore configuration
tar -xzf nagios-backup.tar.gz -C /opt/nagios-docker/

# Fix permissions
chown -R 101:101 /opt/nagios-docker/nagios-etc
chown -R 101:101 /opt/nagios-docker/nagios-var

# Start Nagios
./manage-nagios.sh start
```

## 🚨 Troubleshooting

### Common Issues

**1. Nagios won't start**
```bash
# Check logs
./manage-nagios.sh logs

# Validate configuration
docker-compose exec nagios nagios -v /opt/nagios/etc/nagios.cfg
```

**2. Configuration errors**
```bash
# Check configuration syntax
./manage-nagios.sh reload-config

# View specific error details
docker-compose logs nagios | grep -i error
```

**3. Email notifications not working**
```bash
# Check mail configuration
docker-compose exec nagios tail -f /var/log/mail.log

# Test SMTP connectivity
docker-compose exec nagios telnet smtp-server 587
```

**4. Web interface issues**
```bash
# Check Nginx configuration
nginx -t

# Verify proxy settings
curl -I http://localhost:8080
```

### Log Locations
- **Nagios Core**: `docker logs nagios`
- **Nagios Debug**: `/opt/nagios-docker/nagios-var/nagios.debug`
- **Apache Logs**: `/opt/nagios-docker/apache-logs/`
- **Nginx**: `/var/log/nginx/`

## 🔄 Updates and Maintenance

### Update Nagios
```bash
cd /opt/nagios-docker
./manage-nagios.sh update
```

### Configuration Management
```bash
# Validate configuration before applying
docker-compose exec nagios nagios -v /opt/nagios/etc/nagios.cfg

# Reload configuration
./manage-nagios.sh reload-config
```

### Performance Optimization
```bash
# Adjust check intervals in nagios.cfg
service_inter_check_delay_method=s
max_service_check_spread=30
max_concurrent_checks=50
```

## 📊 Advanced Configuration

### Custom Plugin Development

Create custom plugins in `/opt/nagios-docker/custom-plugins/`:

```bash
#!/bin/bash
# Custom monitoring plugin example

# Check application status
if curl -f http://localhost:8080/health > /dev/null 2>&1; then
    echo "OK - Application is running"
    exit 0
else
    echo "CRITICAL - Application is down"
    exit 2
fi
```

### Distributed Monitoring

Configure NRPE for remote monitoring:

```cfg
define command {
    command_name    check_nrpe
    command_line    $USER1$/check_nrpe -H $HOSTADDRESS$ -c $ARG1$
}
```

### Integration with Other Tools

- **Grafana Integration**: Use Nagios data source plugin
- **PagerDuty**: Configure webhook notifications
- **Slack**: Set up Slack notification scripts

## 🆘 Support and Resources

### Project Resources
- **GitHub Repository**: [https://github.com/defendx1/Nagios](https://github.com/defendx1/Nagios)
- **Issues & Support**: [Report Issues](https://github.com/defendx1/Nagios/issues)
- **Latest Releases**: [View Releases](https://github.com/defendx1/Nagios/releases)

### Official Documentation
- [Nagios Core Documentation](https://www.nagios.org/documentation/)
- [Nagios Plugin Development](https://nagios-plugins.org/doc/guidelines.html)
- [Docker Documentation](https://docs.docker.com/)
- [Nginx Documentation](https://nginx.org/en/docs/)

### Community Support
- [Nagios Community Forum](https://support.nagios.com/forum/)
- [Nagios Exchange](https://exchange.nagios.org/)
- [DefendX1 Telegram](https://t.me/defendx1)

## 📄 License

This script is provided under the MIT License. See LICENSE file for details.

---

## 👨‍💻 Author & Contact

**Script Developer**: DefendX1 Team  
**Website**: [https://defendx1.com/](https://defendx1.com/)  
**Telegram**: [t.me/defendx1](https://t.me/defendx1)

### About DefendX1
DefendX1 specializes in cybersecurity solutions, infrastructure automation, and monitoring systems. Visit [defendx1.com](https://defendx1.com/) for more security tools and monitoring resources.

---

## 🔗 Resources & Links

### Project Resources
- **GitHub Repository**: [https://github.com/defendx1/Nagios](https://github.com/defendx1/Nagios)
- **Issues & Support**: [Report Issues](https://github.com/defendx1/Nagios/issues)
- **Latest Releases**: [View Releases](https://github.com/defendx1/Nagios/releases)

### Download & Installation
**GitHub Repository**: [https://github.com/defendx1/Nagios](https://github.com/defendx1/Nagios)

Clone or download the latest version:
```bash
git clone https://github.com/defendx1/Nagios.git
```

## 🤝 Contributing

Contributions are welcome! Please:
1. Fork the repository: [https://github.com/defendx1/Nagios](https://github.com/defendx1/Nagios)
2. Create a feature branch
3. Submit a pull request

## ⭐ Star This Project

If this script helped you, please consider starring the repository at [https://github.com/defendx1/Nagios](https://github.com/defendx1/Nagios)!

---

**Last Updated**: June 2025  
**Version**: 1.0.0
