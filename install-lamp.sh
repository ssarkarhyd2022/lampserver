#!/bin/bash

# Check if the script is run as root
if [ "$EUID" -ne 0 ]; then
  echo "Please run this script as root (e.g., sudo ./install-lamp.sh)"
  exit 1
fi

# --- Get user input ---

# Prompt for the web root directory
read -p "Enter the web root directory (e.g., /var/www/html): " WEB_ROOT
WEB_ROOT=${WEB_ROOT:-"/var/www/html"} # Set default if input is empty

# Prompt for the MariaDB root password
read -s -p "Enter a strong password for MariaDB root user: " DB_ROOT_PASSWORD
echo "" # Add a new line after the password input

# --- STEP 1: Update the system ---
echo "--- Updating system packages ---"
apt update && apt -y upgrade

# --- STEP 2: Install Apache2 (with confirmation) ---
read -p "Do you want to install Apache2? (y/n): " install_apache
if [[ "$install_apache" =~ ^[Yy]$ ]]; then
  echo "--- Installing Apache2 ---"
  apt install -y apache2 apache2-utils
  systemctl start apache2
  systemctl enable apache2

  # Check if Apache is running
  systemctl is-active --quiet apache2 && echo "Apache2 installed and running." || echo "Apache2 failed to install."
else
  echo "Skipping Apache2 installation."
fi

# --- STEP 3: Install MariaDB (with confirmation) ---
read -p "Do you want to install MariaDB? (y/n): " install_mariadb
if [[ "$install_mariadb" =~ ^[Yy]$ ]]; then
  echo "--- Installing MariaDB ---"
  apt install -y mariadb-server mariadb-client
  systemctl start mariadb
  systemctl enable mariadb

  # Secure the MariaDB installation
  echo "--- Securing MariaDB installation... ---"
  mysql_secure_installation <<EOF

y
$DB_ROOT_PASSWORD
$DB_ROOT_PASSWORD
y
y
y
y
EOF
else
  echo "Skipping MariaDB installation."
fi

# --- STEP 4: Install PHP and essential modules (with confirmation) ---
read -p "Do you want to install PHP and its modules? (y/n): " install_php
if [[ "$install_php" =~ ^[Yy]$ ]]; then
  echo "--- Installing PHP and modules ---"
  apt install -y php libapache2-mod-php php-cli php-fpm php-json php-pdo php-mysql php-zip php-gd php-mbstring php-curl php-xml php-pear php-bcmath
  
  # --- Create a test PHP file ---
  echo "--- Creating PHP test file in $WEB_ROOT ---"
  echo "<?php phpinfo(); ?>" > "$WEB_ROOT/info.php"
  
  # Restart Apache to apply PHP module changes
  systemctl restart apache2
else
  echo "Skipping PHP installation."
fi

# --- STEP 5: Install phpMyAdmin (with confirmation) ---
read -p "Do you want to install phpMyAdmin? (y/n): " install_phpmyadmin
if [[ "$install_phpmyadmin" =~ ^[Yy]$ ]]; then
    if [[ "$install_mariadb" =~ ^[Yy]$ && "$install_php" =~ ^[Yy]$ && "$install_apache" =~ ^[Yy]$ ]]; then
        echo "--- Installing phpMyAdmin ---"
        apt install -y phpmyadmin
        # Auto-configure phpMyAdmin with Apache
        ln -s /etc/phpmyadmin/apache.conf /etc/apache2/conf-available/phpmyadmin.conf
        a2enconf phpmyadmin.conf
        systemctl restart apache2
        echo "phpMyAdmin has been installed. Access it at http://your_server_ip_address/phpmyadmin"
    else
        echo "Skipping phpMyAdmin installation. Requires Apache, MariaDB, and PHP to be installed."
    fi
else
    echo "Skipping phpMyAdmin installation."
fi

# --- Final message ---
echo "--- Installation process finished. ---"
echo "To check if your installation was successful, open a web browser and go to:"
echo "  http://your_server_ip_address/info.php"
echo "Remember to delete the info.php file after you're done testing."