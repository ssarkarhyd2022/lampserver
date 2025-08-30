#!/bin/bash

# Check if the script is run as root
if [ "$EUID" -ne 0 ]; then
  echo "Please run this script as root (e.g., sudo ./uninstall-lamp.sh)"
  exit 1
fi

# --- Get user input for web root directory ---
read -p "Enter the web root directory where your files are located (e.g., /var/www/html): " WEB_ROOT
WEB_ROOT=${WEB_ROOT:-"/var/www/html"} # Set default if input is empty

# --- STEP 1: Stop and Disable Services ---
echo "--- Stopping and disabling services... ---"

# Disable and stop Apache2 service
echo "Disabling and stopping Apache2..."
systemctl disable apache2
systemctl stop apache2

# Disable and stop MariaDB service
echo "Disabling and stopping MariaDB..."
systemctl disable mariadb
systemctl stop mariadb

# --- STEP 2: Remove Packages ---
echo "--- Removing packages... ---"

# Remove Apache2 and related packages
read -p "Do you want to remove Apache2? (y/n): " remove_apache
if [[ "$remove_apache" =~ ^[Yy]$ ]]; then
    echo "Removing Apache2..."
    apt purge -y apache2 apache2-utils
fi

# Remove MariaDB and related packages
read -p "Do you want to remove MariaDB? (y/n): " remove_mariadb
if [[ "$remove_mariadb" =~ ^[Yy]$ ]]; then
    echo "Removing MariaDB..."
    apt purge -y mariadb-server mariadb-client
fi

# Remove PHP and all modules
read -p "Do you want to remove PHP and its modules? (y/n): " remove_php
if [[ "$remove_php" =~ ^[Yy]$ ]]; then
    echo "Removing PHP and its modules..."
    apt purge -y php*
fi

# Remove phpMyAdmin
read -p "Do you want to remove phpMyAdmin? (y/n): " remove_phpmyadmin
if [[ "$remove_phpmyadmin" =~ ^[Yy]$ ]]; then
    echo "Removing phpMyAdmin..."
    apt purge -y phpmyadmin
    # Remove the Apache configuration link
    if [ -f /etc/apache2/conf-available/phpmyadmin.conf ]; then
        a2disconf phpmyadmin.conf
        rm /etc/apache2/conf-available/phpmyadmin.conf
        echo "Removed phpMyAdmin Apache configuration."
        systemctl restart apache2
    fi
fi

# Remove any unused dependencies
echo "Cleaning up unused dependencies..."
apt autoremove -y

# --- STEP 3: Remove Test Files and Directories ---
echo "--- Removing test files and directories... ---"

# Remove the PHP test file
if [ -f "$WEB_ROOT/info.php" ]; then
  rm "$WEB_ROOT/info.php"
  echo "Removed $WEB_ROOT/info.php"
else
  echo "PHP test file not found at $WEB_ROOT/info.php, skipping."
fi

echo "--- Uninstallation complete! ---"
echo "Your system has been cleaned of the LAMP stack components."