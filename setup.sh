#!/bin/bash

# Exit on error
set -e

UPDATE_PACKAGES_GET_DEPENDENCIES () 
{
    sudo apt update && sudo apt upgrade -y
    sudo apt install -y apt-transport-https wget curl gnupg
}

ADD_REPO () 
{
    # Add Elasticsearch repository
    wget -qO - https://artifacts.elastic.co/GPG-KEY-elasticsearch | sudo gpg --dearmor -o /usr/share/keyrings/elasticsearch-keyring.gpg
    echo "deb [signed-by=/usr/share/keyrings/elasticsearch-keyring.gpg] https://artifacts.elastic.co/packages/8.x/apt stable main" | sudo tee /etc/apt/sources.list.d/elastic-8.x.list
    
    # Add Grafana repository
    sudo mkdir -p /etc/apt/keyrings/
    wget -q -O - https://apt.grafana.com/gpg.key | gpg --dearmor | tee /etc/apt/keyrings/grafana.gpg > /dev/null
    sudo echo "deb [signed-by=/etc/apt/keyrings/grafana.gpg] https://apt.grafana.com stable main" | sudo tee -a /etc/apt/sources.list.d/grafana.list
}

INSTALL () 
{
    # Install Elasticsearch, logstash and grafana
    sudo apt-get update && sudo apt-get install -y  elasticsearch logstash grafana
    sudo systemctl enable --now elasticsearch logstash grafana-server
}

SETUP_CONF () 
{
    rsync -azv elasticsearch/elasticsearch.yml /etc/elasticsearch/
    rsync -azv logstash/conf.d /etc/logstash/
	rsync -azv logstash/templates /etc/logstash/
    sudo systemctl restart logstash elasticsearch
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
        "database": "safesquid-conf_*",
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
        "database": "safesquid-csp_*",
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
        "database": "safesquid-ext_*",
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
        "database": "safesquid-perf_*",
        "jsonData": {
            "esVersion": 70,
            "timeField": "@timestamp"
        }
    }' http://admin:admin@localhost:3000/api/datasources
}

IMPORT_GRAFANA_DASHBOARD () 
{
    #Import dasboard to grafana
    curl -X POST -H "Content-Type: application/json" -d @grafana_dashboard/configuration_portal_reports.json http://admin:admin@localhost:3000/api/dashboards/import
    curl -X POST -H "Content-Type: application/json" -d @grafana_dashboard/content_security_policy_reports.json http://admin:admin@localhost:3000/api/dashboards/db
    curl -X POST -H "Content-Type: application/json" -d @grafana_dashboard/performance_plots.json http://admin:admin@localhost:3000/api/dashboards/db
    curl -X POST -H "Content-Type: application/json" -d @grafana_dashboard/user_reports.json http://admin:admin@localhost:3000/api/dashboards/db
}

MAIN () 
{
    UPDATE_PACKAGES_GET_DEPENDENCIES
    ADD_REPO
    INSTALL && echo "Installation complete! Elasticsearch, Logstash, and Grafana are running."
    SETUP_CONF
    CONFIGURE_GRAFANA_DATASOURCES
    IMPORT_GRAFANA_DASHBOARD
}

MAIN