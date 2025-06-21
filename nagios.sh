#!/bin/bash

# Nagios Standalone Installation Script
# Install Nagios with Docker and Nginx SSL

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m'

print_color() {
    local color=$1
    local message=$2
    echo -e "${color}${message}${NC}"
}

print_banner() {
    clear
    print_color $CYAN "======================================"
    print_color $CYAN "     🔍 Nagios Installation 🔍"
    print_color $CYAN "======================================"
    print_color $YELLOW "   Infrastructure Monitoring Platform"
    print_color $CYAN "======================================"
    echo
}

check_prerequisites() {
    print_color $BLUE "🔍 Checking prerequisites..."
    
    if [ "$EUID" -ne 0 ]; then
        print_color $RED "❌ Please run as root or with sudo"
        exit 1
    fi
    
    # Install Docker if not present
    if ! command -v docker &> /dev/null; then
        print_color $YELLOW "📦 Installing Docker..."
        curl -fsSL https://get.docker.com -o get-docker.sh
        sh get-docker.sh
        systemctl start docker
        systemctl enable docker
        rm get-docker.sh
    fi
    
    # Install Docker Compose if not present
    if ! command -v docker-compose &> /dev/null; then
        print_color $YELLOW "📦 Installing Docker Compose..."
        curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
        chmod +x /usr/local/bin/docker-compose
    fi
    
    # Install Nginx if not present
    if ! command -v nginx &> /dev/null; then
        print_color $YELLOW "📦 Installing Nginx..."
        apt update
        apt install -y nginx
        systemctl start nginx
        systemctl enable nginx
    fi
    
    # Install Certbot if not present
    if ! command -v certbot &> /dev/null; then
        print_color $YELLOW "📦 Installing Certbot..."
        apt update
        apt install -y certbot python3-certbot-nginx
    fi
    
    print_color $GREEN "✅ Prerequisites ready!"
}

get_configuration() {
    print_banner
    print_color $YELLOW "🌐 Configuration Setup"
    echo
    
    # Get domain
    read -p "Enter domain for Nagios (e.g., nagios.yourdomain.com): " NAGIOS_DOMAIN
    if [ -z "$NAGIOS_DOMAIN" ]; then
        print_color $RED "❌ Domain cannot be empty"
        get_configuration
    fi
    
    # Get email for SSL
    read -p "Enter email for SSL certificate: " SSL_EMAIL
    if [ -z "$SSL_EMAIL" ]; then
        print_color $RED "❌ Email cannot be empty"
        get_configuration
    fi
    
    # Get admin credentials
    read -p "Enter admin username (default: nagiosadmin): " NAGIOS_USER
    NAGIOS_USER=${NAGIOS_USER:-nagiosadmin}
    
    read -s -p "Enter admin password: " NAGIOS_PASSWORD
    echo
    if [ -z "$NAGIOS_PASSWORD" ]; then
        print_color $RED "❌ Password cannot be empty"
        get_configuration
    fi
    
    # Get alert email
    read -p "Enter email for alerts (default: admin@${NAGIOS_DOMAIN}): " ALERT_EMAIL
    ALERT_EMAIL=${ALERT_EMAIL:-admin@${NAGIOS_DOMAIN}}
    
    # Check port conflicts
    NAGIOS_PORT=8080
    while netstat -tlnp | grep ":$NAGIOS_PORT " > /dev/null 2>&1; do
        NAGIOS_PORT=$((NAGIOS_PORT + 1))
    done
    
    print_color $GREEN "✅ Configuration complete!"
    print_color $BLUE "   Domain: $NAGIOS_DOMAIN"
    print_color $BLUE "   Port: $NAGIOS_PORT"
    print_color $BLUE "   Username: $NAGIOS_USER"
    print_color $BLUE "   Alert Email: $ALERT_EMAIL"
    sleep 2
}

install_nagios() {
    print_color $BLUE "📁 Creating directory structure..."
    mkdir -p /opt/nagios-docker/{nagios-etc,nagios-var,custom-plugins,apache-logs}
    mkdir -p /opt/nagios-docker/nagios-etc/{conf.d,objects}
    
    chown -R 101:101 /opt/nagios-docker/nagios-etc
    chown -R 101:101 /opt/nagios-docker/nagios-var
    chmod -R 755 /opt/nagios-docker
    
    cd /opt/nagios-docker
    
    print_color $BLUE "📝 Creating Nagios configuration files..."
    
    # Create main nagios.cfg
    cat > nagios-etc/nagios.cfg << EOF
log_file=/opt/nagios/var/nagios.log
cfg_file=/opt/nagios/etc/objects/commands.cfg
cfg_file=/opt/nagios/etc/objects/contacts.cfg
cfg_file=/opt/nagios/etc/objects/timeperiods.cfg
cfg_file=/opt/nagios/etc/objects/templates.cfg
cfg_dir=/opt/nagios/etc/conf.d

object_cache_file=/opt/nagios/var/objects.cache
precached_object_file=/opt/nagios/var/objects.precache
resource_file=/opt/nagios/etc/resource.cfg
status_file=/opt/nagios/var/status.dat
status_update_interval=10
nagios_user=nagios
nagios_group=nagios
check_external_commands=1
command_check_interval=-1
command_file=/opt/nagios/var/rw/nagios.cmd
external_command_buffer_slots=4096
lock_file=/opt/nagios/var/nagios.lock
temp_file=/opt/nagios/var/nagios.tmp
temp_path=/tmp
event_broker_options=-1
log_rotation_method=d
log_archive_path=/opt/nagios/var/archives
use_daemon_log=1
use_syslog=0
log_notifications=1
log_service_retries=1
log_host_retries=1
log_event_handlers=1
log_initial_states=0
log_external_commands=1
log_passive_checks=1
sleep_time=0.25
service_inter_check_delay_method=s
max_service_check_spread=30
service_interleave_factor=s
host_inter_check_delay_method=s
max_host_check_spread=30
max_concurrent_checks=0
check_result_reaper_frequency=10
max_check_result_reaper_time=30
check_result_path=/opt/nagios/var/spool/checkresults
max_check_result_file_age=3600
cached_host_check_horizon=15
cached_service_check_horizon=15
enable_predictive_host_dependency_checks=1
enable_predictive_service_dependency_checks=1
soft_state_dependencies=0
auto_reschedule_checks=0
auto_rescheduling_interval=30
auto_rescheduling_window=180
use_aggressive_host_checking=0
translate_passive_host_checks=0
passive_host_checks_are_soft=0
enable_environment_macros=1
additional_freshness_latency=15
enable_flap_detection=1
low_service_flap_threshold=5.0
high_service_flap_threshold=20.0
low_host_flap_threshold=5.0
high_host_flap_threshold=20.0
date_format=us
use_timezone=UTC
illegal_object_name_chars=\`~!$%^&*|'"<>?,()=
illegal_macro_output_chars=\`~$&|'"<>
use_regexp_matching=0
use_true_regexp_matching=0
admin_email=${ALERT_EMAIL}
admin_pager=${ALERT_EMAIL}
daemon_dumps_core=0
use_large_installation_tweaks=0
enable_embedded_perl=1
use_embedded_perl_implicitly=1
p1_file=/opt/nagios/bin/p1.pl
debug_level=0
debug_verbosity=1
debug_file=/opt/nagios/var/nagios.debug
max_debug_file_size=1000000
EOF

    # Create contacts configuration
    cat > nagios-etc/objects/contacts.cfg << EOF
define contact {
    contact_name                   nagiosadmin
    use                           generic-contact
    alias                         Nagios Admin
    email                         ${ALERT_EMAIL}
}

define contactgroup {
    contactgroup_name             admins
    alias                         Nagios Administrators
    members                       nagiosadmin
}
EOF

    # Create host definitions
    cat > nagios-etc/conf.d/hosts.cfg << EOF
define host {
    use                          linux-server
    host_name                    localhost
    alias                        localhost
    address                      127.0.0.1
    contact_groups               admins
    notification_interval        30
    notification_period          24x7
}
EOF

    # Create service definitions
    cat > nagios-etc/conf.d/services.cfg << EOF
define service {
    use                          generic-service
    host_name                    localhost
    service_description          Root Partition
    check_command                check_local_disk!20%!10%!/
    contact_groups               admins
    notification_interval        30
}

define service {
    use                          generic-service
    host_name                    localhost
    service_description          Current Users
    check_command                check_local_users!20!50
    contact_groups               admins
    notification_interval        30
}

define service {
    use                          generic-service
    host_name                    localhost
    service_description          Total Processes
    check_command                check_local_procs!250!400!RSZDT
    contact_groups               admins
    notification_interval        30
}

define service {
    use                          generic-service
    host_name                    localhost
    service_description          Current Load
    check_command                check_local_load!5.0,4.0,3.0!10.0,6.0,4.0
    contact_groups               admins
    notification_interval        30
}
EOF

    # Create commands configuration
    cat > nagios-etc/objects/commands.cfg << EOF
define command {
    command_name    notify-host-by-email
    command_line    /usr/bin/printf "%b" "***** Nagios *****\n\nNotification Type: \$NOTIFICATIONTYPE\$\nHost: \$HOSTNAME\$\nState: \$HOSTSTATE\$\nAddress: \$HOSTADDRESS\$\nInfo: \$HOSTOUTPUT\$\n\nDate/Time: \$LONGDATETIME\$\n" | /usr/bin/mail -s "** \$NOTIFICATIONTYPE\$ Host Alert: \$HOSTNAME\$ is \$HOSTSTATE\$ **" \$CONTACTEMAIL\$
}

define command {
    command_name    notify-service-by-email
    command_line    /usr/bin/printf "%b" "***** Nagios *****\n\nNotification Type: \$NOTIFICATIONTYPE\$\n\nService: \$SERVICEDESC\$\nHost: \$HOSTALIAS\$\nAddress: \$HOSTADDRESS\$\nState: \$SERVICESTATE\$\n\nDate/Time: \$LONGDATETIME\$\n\nAdditional Info:\n\n\$SERVICEOUTPUT\$\n" | /usr/bin/mail -s "** \$NOTIFICATIONTYPE\$ Service Alert: \$HOSTALIAS\$/\$SERVICEDESC\$ is \$SERVICESTATE\$ **" \$CONTACTEMAIL\$
}

define command {
    command_name    check_local_disk
    command_line    \$USER1\$/check_disk -w \$ARG1\$ -c \$ARG2\$ -p \$ARG3\$
}

define command {
    command_name    check_local_load
    command_line    \$USER1\$/check_load -w \$ARG1\$ -c \$ARG2\$
}

define command {
    command_name    check_local_procs
    command_line    \$USER1\$/check_procs -w \$ARG1\$ -c \$ARG2\$ -s \$ARG3\$
}

define command {
    command_name    check_local_users
    command_line    \$USER1\$/check_users -w \$ARG1\$ -c \$ARG2\$
}

define command {
    command_name    check_ping
    command_line    \$USER1\$/check_ping -H \$HOSTADDRESS\$ -w 3000.0,80% -c 5000.0,100% -p 5
}

define command {
    command_name    check_host_alive
    command_line    \$USER1\$/check_ping -H \$HOSTADDRESS\$ -w 3000.0,80% -c 5000.0,100% -p 1
}
EOF

    print_color $BLUE "🐳 Creating Docker Compose configuration..."
    cat > docker-compose.yml << EOF
version: '3.8'

services:
  nagios:
    image: jasonrivers/nagios:latest
    container_name: nagios
    restart: unless-stopped
    ports:
      - "127.0.0.1:${NAGIOS_PORT}:80"
    environment:
      - NAGIOS_FQDN=${NAGIOS_DOMAIN}
      - NAGIOS_USER=${NAGIOS_USER}
      - NAGIOS_PASS=${NAGIOS_PASSWORD}
      - APACHE_RUN_USER=nagios
      - APACHE_RUN_GROUP=nagios
      - MAIL_RELAY_HOST=localhost
      - MAIL_INET_PROTOCOLS=ipv4
      - NAGIOS_TIMEZONE=UTC
    volumes:
      - ./nagios-etc:/opt/nagios/etc
      - ./nagios-var:/opt/nagios/var
      - ./custom-plugins:/opt/Custom-Nagios-Plugins
      - ./apache-logs:/var/log/apache2
    networks:
      - nagios-network
    extra_hosts:
      - "host.docker.internal:host-gateway"

networks:
  nagios-network:
    driver: bridge
EOF

    cat > .env << EOF
NAGIOS_DOMAIN=${NAGIOS_DOMAIN}
NAGIOS_PORT=${NAGIOS_PORT}
NAGIOS_USER=${NAGIOS_USER}
NAGIOS_PASS=${NAGIOS_PASSWORD}
ALERT_EMAIL=${ALERT_EMAIL}
SSL_EMAIL=${SSL_EMAIL}
EOF

    print_color $BLUE "🚀 Starting Nagios..."
    docker-compose up -d
    
    sleep 45
    
    if docker-compose ps | grep -q "nagios.*Up"; then
        print_color $GREEN "✅ Nagios container is running"
        
        local_test=$(curl -s -o /dev/null -w "%{http_code}" http://127.0.0.1:${NAGIOS_PORT}/ 2>/dev/null || echo "000")
        if [ "$local_test" = "200" ] || [ "$local_test" = "401" ]; then
            print_color $GREEN "✅ Nagios is responding locally ($local_test)"
        else
            print_color $YELLOW "⚠️  Nagios local response: $local_test"
        fi
    else
        print_color $RED "❌ Nagios failed to start"
        docker-compose logs nagios | tail -20
        exit 1
    fi
}

configure_nginx() {
    print_color $BLUE "🌐 Configuring Nginx..."
    
    # Initial HTTP configuration
    cat > /etc/nginx/sites-available/${NAGIOS_DOMAIN} << EOF
server {
    listen 80;
    server_name ${NAGIOS_DOMAIN};
    
    location /.well-known/acme-challenge/ {
        root /var/www/html;
    }
    
    location / {
        return 301 https://\$server_name\$request_uri;
    }
}
EOF

    ln -sf /etc/nginx/sites-available/${NAGIOS_DOMAIN} /etc/nginx/sites-enabled/
    nginx -t && systemctl reload nginx
    
    print_color $BLUE "🔒 Obtaining SSL certificate..."
    certbot --nginx -d ${NAGIOS_DOMAIN} --email ${SSL_EMAIL} --agree-tos --non-interactive --redirect
    
    # Final HTTPS configuration
    cat > /etc/nginx/sites-available/${NAGIOS_DOMAIN} << EOF
server {
    listen 80;
    server_name ${NAGIOS_DOMAIN};
    return 301 https://\$server_name\$request_uri;
}

server {
    listen 443 ssl http2;
    server_name ${NAGIOS_DOMAIN};

    ssl_certificate /etc/letsencrypt/live/${NAGIOS_DOMAIN}/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/${NAGIOS_DOMAIN}/privkey.pem;
    
    ssl_protocols TLSv1.2 TLSv1.3;
    ssl_prefer_server_ciphers off;
    ssl_session_timeout 1d;

    add_header Strict-Transport-Security "max-age=31536000" always;
    add_header X-Content-Type-Options nosniff;
    add_header X-Frame-Options SAMEORIGIN;
    add_header X-XSS-Protection "1; mode=block";

    access_log /var/log/nginx/${NAGIOS_DOMAIN}_access.log;
    error_log /var/log/nginx/${NAGIOS_DOMAIN}_error.log;

    location / {
        proxy_pass http://127.0.0.1:${NAGIOS_PORT};
        proxy_set_header Host \$http_host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
        proxy_set_header X-Forwarded-Host \$server_name;
        proxy_redirect off;
        
        proxy_buffering off;
        proxy_request_buffering off;
        
        proxy_connect_timeout 60s;
        proxy_send_timeout 60s;
        proxy_read_timeout 60s;
        
        client_max_body_size 50M;
    }

    location ~ \.cgi\$ {
        proxy_pass http://127.0.0.1:${NAGIOS_PORT};
        proxy_set_header Host \$http_host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
        proxy_redirect off;
        
        proxy_read_timeout 300s;
        proxy_send_timeout 300s;
    }

    location ~* \.(css|js|png|jpg|jpeg|gif|ico|svg)\$ {
        proxy_pass http://127.0.0.1:${NAGIOS_PORT};
        proxy_set_header Host \$http_host;
        
        expires 1d;
        add_header Cache-Control "public";
    }
}
EOF

    nginx -t && systemctl reload nginx
    print_color $GREEN "✅ Nginx configured with SSL"
}

create_management_script() {
    print_color $BLUE "📝 Creating management script..."
    cat > /opt/nagios-docker/manage-nagios.sh << 'EOF'
#!/bin/bash

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

case "$1" in
    start)
        echo "Starting Nagios..."
        docker-compose up -d
        ;;
    stop)
        echo "Stopping Nagios..."
        docker-compose down
        ;;
    restart)
        echo "Restarting Nagios..."
        docker-compose restart
        ;;
    logs)
        echo "Showing Nagios logs..."
        docker-compose logs -f nagios
        ;;
    status)
        echo "Nagios status:"
        docker-compose ps
        echo
        echo "Nagios URL: https://$(grep NAGIOS_DOMAIN .env | cut -d= -f2)/"
        ;;
    backup)
        echo "Creating backup..."
        tar -czf "nagios-backup-$(date +%Y%m%d-%H%M%S).tar.gz" nagios-etc nagios-var
        echo "Backup created"
        ;;
    update)
        echo "Updating Nagios..."
        docker-compose pull
        docker-compose up -d
        ;;
    reload-config)
        echo "Reloading Nagios configuration..."
        docker-compose exec nagios nagios -v /opt/nagios/etc/nagios.cfg
        if [ $? -eq 0 ]; then
            docker-compose restart nagios
            echo "Configuration reloaded successfully"
        else
            echo "Configuration validation failed"
        fi
        ;;
    *)
        echo "Usage: $0 {start|stop|restart|logs|status|backup|update|reload-config}"
        exit 1
        ;;
esac
EOF

    chmod +x /opt/nagios-docker/manage-nagios.sh
}

# Main installation flow
main() {
    print_banner
    check_prerequisites
    get_configuration
    install_nagios
    configure_nginx
    create_management_script
    
    print_color $GREEN "✅ Nagios installation completed!"
    echo
    print_color $CYAN "======================================"
    print_color $CYAN "    Installation Complete!"
    print_color $CYAN "======================================"
    echo
    print_color $YELLOW "📍 Access Information:"
    print_color $BLUE "   URL: https://${NAGIOS_DOMAIN}"
    print_color $BLUE "   Username: ${NAGIOS_USER}"
    print_color $BLUE "   Password: [Your entered password]"
    print_color $BLUE "   Alert Email: ${ALERT_EMAIL}"
    echo
    print_color $YELLOW "🔧 Management Commands:"
    print_color $BLUE "   /opt/nagios-docker/manage-nagios.sh start"
    print_color $BLUE "   /opt/nagios-docker/manage-nagios.sh stop"
    print_color $BLUE "   /opt/nagios-docker/manage-nagios.sh restart"
    print_color $BLUE "   /opt/nagios-docker/manage-nagios.sh logs"
    print_color $BLUE "   /opt/nagios-docker/manage-nagios.sh status"
    print_color $BLUE "   /opt/nagios-docker/manage-nagios.sh backup"
    print_color $BLUE "   /opt/nagios-docker/manage-nagios.sh reload-config"
    echo
    print_color $YELLOW "📁 Configuration Location:"
    print_color $BLUE "   /opt/nagios-docker/"
    echo
    print_color $GREEN "🌐 Access Nagios at: https://${NAGIOS_DOMAIN}"
}

# Run main function
main "$@"
