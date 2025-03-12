#!/bin/bash

# Exit on error
set -e

# Create the directory to store the downloaded files
[ ! -d "/tmp/reporting/"] && mkdir -p /tmp/reporting/ || rm -rf /tmp/reporting/*

GET_CONF () 
{
    # URLs of the files to download
    URLS=(
        "https://raw.githubusercontent.com/SafeSquid-Github/SafeSquid-ELG-Reporting/refs/heads/main/safesquid/etc/rsyslog.conf"
        "https://raw.githubusercontent.com/SafeSquid-Github/SafeSquid-ELG-Reporting/refs/heads/main/safesquid/etc/rsyslog.d/50-default.conf"
        "https://raw.githubusercontent.com/SafeSquid-Github/SafeSquid-ELG-Reporting/refs/heads/main/safesquid/etc/rsyslog.d/99-safesquid.conf"
    )

    # Download the files
    for URL in "${URLS[@]}"; do
        wget -P /tmp/reporting/ "$URL"
    done
}

GET_REPORTING_IP () 
{
    # Get the data source IP and port from the user
    read -p "Enter the data source IP: " DATASTORE_NODE_IP
    read -p "Enter the data source port: " DATASTORE_NODE_PORT

    # Update the 99-safesquid.conf file with the provided IP and port
    sed -i "s|action(type=\"omfwd\" target=\"<datastore_node_ip>\" port=\"<datastore_node_port>\" protocol=\"udp\")|action(type=\"omfwd\" target=\"$DATASTORE_NODE_IP\" port=\"$DATASTORE_NODE_PORT\" protocol=\"udp\")|g" /tmp/reporting/99-safesquid.conf
}

UPDATE_CONF ()
{
    # Rename existing configuration files if present
    [ -f /etc/rsyslog.conf ] && [ ! -f /etc/rsyslog.conf.bak ]  && sudo mv /etc/rsyslog.conf /etc/rsyslog.conf.bak
    [ -f /etc/rsyslog.d/50-default.conf ] && [ ! -f /etc/rsyslog.d/50-default.conf.bak ] && sudo mv /etc/rsyslog.d/50-default.conf /etc/rsyslog.d/50-default.conf.bak
    [ -f /etc/rsyslog.d/99-safesquid.conf ] && [ ! -f /etc/rsyslog.d/99-safesquid.conf.bak ] && sudo mv /etc/rsyslog.d/99-safesquid.conf /etc/rsyslog.d/99-safesquid.conf.bak

    # Sync the files to the appropriate directory
    sudo rsync -av /tmp/reporting/rsyslog.conf /etc/
    sudo rsync -av /tmp/reporting/rsyslog.d/ /etc/rsyslog.d/
}

RESTRT_SERVICE () 
{
    # Restart the rsyslog service
    sudo systemctl restart rsyslog.service
}

MAIN () 
{
    GET_CONF
    GET_REPORTING_IP
    UPDATE_CONF
    RESTRT_SERVICE
}

MAIN