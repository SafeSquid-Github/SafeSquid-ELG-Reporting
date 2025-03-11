#!/bin/bash

# Exit on error
set -e

UPDATE_PACKAGES () 
{
    echo "Updating system packages..."
    sudo apt update && sudo apt upgrade -y
}

GET_DEPENDENCIES () 
{
    echo "Installing dependencies..."
    sudo apt install -y apt-transport-https wget curl gnupg
}

ADD_REPO () 
{
    # Add Elasticsearch repository
    echo "Adding Elasticsearch repository..."
    wget -qO - https://artifacts.elastic.co/GPG-KEY-elasticsearch | sudo apt-key add -
    echo "deb https://artifacts.elastic.co/packages/8.x/apt stable main" | sudo tee /etc/apt/sources.list.d/elastic-8.x.list

    # Add Grafana repository
    echo "Adding Grafana repository..."
    wget -qO - https://packages.grafana.com/gpg.key | sudo apt-key add -
    echo "deb https://packages.grafana.com/oss/deb stable main" | sudo tee /etc/apt/sources.list.d/grafana.list
}

INSTALL () 
{
    # Install Elasticsearch
    echo "Installing Elasticsearch"
    sudo apt update
    sudo apt install -y elasticsearch logstash grafana
    sudo systemctl enable --now elasticsearch logstash grafana-server
    echo "Elasticsearch installed."
}

SETUP_LOGSTASH () 
{
    rsync -azvf logstash/* /etc/logstash/
    sudo systemctl restart logstash
}

IMPORT_GRAFANA_DASHBOARD () 
{
    echo "Importing Grafana dashboard..."
    curl -X POST -H "Content-Type: application/json" -d @grafana_dashboard/configuration_portal_reports.json http://admin:admin@localhost:3000/api/dashboards/db
    curl -X POST -H "Content-Type: application/json" -d @grafana_dashboard/content_security_policy_reports.json http://admin:admin@localhost:3000/api/dashboards/db
    curl -X POST -H "Content-Type: application/json" -d @grafana_dashboard/performance_plots.json http://admin:admin@localhost:3000/api/dashboards/db
    curl -X POST -H "Content-Type: application/json" -d @grafana_dashboard/user_reports.json http://admin:admin@localhost:3000/api/dashboards/db
}

CONFIGURE_GRAFANA_DATASOURCES () 
{
    echo "Configuring Grafana data sources..."
    curl -X POST -H "Content-Type: application/json" -d '{
        "name": "SafeSquid-Config",
        "type": "elasticsearch",
        "url": "http://localhost:9200",
        "access": "proxy",
        "basicAuth": false,
        "database": "safesquid-conf_YYYY_MM",
        "jsonData": {
            "esVersion": 70,
            "timeField": "@timestamp"
        }
    }' http://admin:admin@localhost:3000/api/datasources

    curl -X POST -H "Content-Type: application/json" -d '{
        "name": "SafeSquid-CSP",
        "type": "elasticsearch",
        "url": "http://localhost:9200",
        "access": "proxy",
        "basicAuth": false,
        "database": "safesquid-csp_YYYY_MM",
        "jsonData": {
            "esVersion": 70,
            "timeField": "@timestamp"
        }
    }' http://admin:admin@localhost:3000/api/datasources

    curl -X POST -H "Content-Type: application/json" -d '{
        "name": "safesquid-extended",
        "type": "elasticsearch",
        "url": "http://localhost:9200",
        "access": "proxy",
        "basicAuth": false,
        "database": "safesquid-ext_YYYY_MM",
        "jsonData": {
            "esVersion": 70,
            "timeField": "@timestamp"
        }
    }' http://admin:admin@localhost:3000/api/datasources

    curl -X POST -H "Content-Type: application/json" -d '{
        "name": "safesquid-performance",
        "type": "elasticsearch",
        "url": "http://localhost:9200",
        "access": "proxy",
        "basicAuth": false,
        "database": "safesquid-perf_YYYY_MM",
        "jsonData": {
            "esVersion": 70,
            "timeField": "@timestamp"
        }
    }' http://admin:admin@localhost:3000/api/datasources
}

MAIN () 
{
    UPDATE_PACKAGES
    GET_DEPENDENCIES
    ADD_REPO
    INSTALL && echo "Installation complete! Elasticsearch, Logstash, and Grafana are running."
    SETUP_LOGSTASH
    CONFIGURE_GRAFANA_DATASOURCES
    IMPORT_GRAFANA_DASHBOARD
}

MAIN