#!/bin/bash

# Exit on error
set -e

ELASTIC_REPO_URL="https://artifacts.elastic.co/packages/8.x/apt"
GRAFANA_REPO_URL="https://apt.grafana.com"


UPDATE_PACKAGES_GET_DEPENDENCIES () 
{
    sudo apt update && sudo apt upgrade -y
    sudo apt install -y apt-transport-https wget curl gnupg
}

ADD_REP_ELASTIC () 
{
    wget -qO - https://artifacts.elastic.co/GPG-KEY-elasticsearch | gpg --dearmor | tee /etc/apt/keyrings/elasticsearch-keyring.gpg > /dev/null
    sudo echo "deb [signed-by=/etc/apt/keyrings/elasticsearch-keyring.gpg] ${ELASTIC_REPO_URL} stable main" > /etc/apt/sources.list.d/elastic-8.x.list
}

APP_REPO_GRAFANA ()
{
    wget -qO - https://apt.grafana.com/gpg.key | gpg --dearmor | tee /etc/apt/keyrings/grafana.gpg > /dev/null
    sudo echo "deb [signed-by=/etc/apt/keyrings/grafana.gpg] ${GRAFANA_REPO_URL} stable main" > /etc/apt/sources.list.d/grafana.list
}

ADD_REPO () 
{
    sudo mkdir -p /etc/apt/keyrings/
    apt-cache policy | awk '/http.*amd64/{print$2}' | sort -u | while read -r REPO_URL; do
        # Add Elasticsearch repository
        [[ $REPO_URL != ${ELASTIC_REPO_URL} ]] && ADD_REP_ELASTIC
        # Add Grafana repository
        [[ $REPO_URL != ${GRAFANA_REPO_URL} ]] && APP_REPO_GRAFANA
    done 
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
        "name": "safesquid-config",
        "type": "elasticsearch",
        "url": "http://localhost:9200",
        "access": "proxy",
        "basicAuth": false,
        "database": "safesquid-conf_*",
        "jsonData": {
            "esVersion": 70,
            "timeField": "@timestamp"
        }
    }' http://admin:sarva1234@localhost:3000/api/datasources

    curl -X POST -H "Content-Type: application/json" -d '{
        "name": "safesquid-csp",
        "type": "elasticsearch",
        "url": "http://localhost:9200",
        "access": "proxy",
        "basicAuth": false,
        "database": "safesquid-csp_*",
        "jsonData": {
            "esVersion": 70,
            "timeField": "@timestamp"
        }
    }' http://admin:sarva1234@localhost:3000/api/datasources

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
    }' http://admin:sarva1234@localhost:3000/api/datasources

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
    }' http://admin:sarva1234@localhost:3000/api/datasources
}

UPDATE_CONF () 
{
    declare -A UID_MAP
    for JSON_FILE in grafana_dashboard/*; 
    do   
        LABELS=$(jq -r '.dashboard.__inputs[] | .label' "$JSON_FILE")
        if [ "$LABELS" != "safesquid-performance" ]; 
        then
            RELATIVE_UID=$(jq -r '.dashboard.templating.list[0].datasource.uid' "$JSON_FILE")
            ABSOLUTE_UID=$(curl -s http://admin:sarva1234@localhost:3000/api/datasources/name/$LABELS | jq -r '.uid')
            [[ ${RELATIVE_UID} == ${ABSOLUTE_UID} ]] && continue
            sed -i "s/\"uid\": \"$RELATIVE_UID\"/\"uid\": \"$ABSOLUTE_UID\"/g" "$JSON_FILE"
        else 
            RELATIVE_UID=$(jq -r '.dashboard.panels[1] | .datasource.uid' "$JSON_FILE")
            ABSOLUTE_UID=$(curl -s http://admin:sarva1234@localhost:3000/api/datasources/name/$LABELS | jq -r '.uid')
            [[ ${RELATIVE_UID} == ${ABSOLUTE_UID} ]] && continue
            sed -i "s/\"uid\": \"$RELATIVE_UID\"/\"uid\": \"$ABSOLUTE_UID\"/g" "$JSON_FILE"
        fi
    done 
}

IMPORT_GRAFANA_DASHBOARD () 
{
    #Import dasboard to grafana
    curl -X POST -H "Content-Type: application/json" -d @grafana_dashboard/performance_plots.json http://admin:sarva1234@localhost:3000/api/dashboards/db
    curl -X POST -H "Content-Type: application/json" -d @grafana_dashboard/user_reports.json http://admin:sarva1234@localhost:3000/api/dashboards/db
    curl -X POST -H "Content-Type: application/json" -d @grafana_dashboard/content_security_policy_reports.json http://admin:sarva1234@localhost:3000/api/dashboards/db
    curl -X POST -H "Content-Type: application/json" -d @grafana_dashboard/configuration_portal_reports.json http://admin:sarva1234@localhost:3000/api/dashboards/import
}

MAIN () 
{
    UPDATE_PACKAGES_GET_DEPENDENCIES
    ADD_REPO
    INSTALL && echo "Installation complete! Elasticsearch, Logstash, and Grafana are running."
    SETUP_CONF
    CONFIGURE_GRAFANA_DATASOURCES
    UPDATE_CONF
    IMPORT_GRAFANA_DASHBOARD
    systemctl restart grafana-server.service
}

MAIN