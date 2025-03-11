# SafeSquid-ELG-Reporting Setup Script

This repository contains a setup script to install and configure Elasticsearch, Logstash, and Grafana for SafeSquid-ELG-Reporting.

## Prerequisites

Before running the setup script, ensure you have the following:

- Ubuntu 24.04 LTS
- System Requirements: 8 CPUs & 12GB
- Minimum storage size: 250 GB  
- Ensure that you are a root user.
- Internet connection

## Usage

1. Clone the repository:

    ```sh
    git clone https://github.com/yourusername/SafeSquid-ELG-Reporting.git
    cd SafeSquid-ELG-Reporting
    ```

2. Run the setup script:

    ```sh
    bash ./setup.sh
    ```

## What the Script Does

- Updates the system packages.
- Installs necessary dependencies.
- Adds the Elasticsearch and Grafana repositories.
- Installs Elasticsearch, Logstash, and Grafana.
- Sets up Logstash configuration.
- Imports predefined Grafana dashboards.

## Default Credentials

- **Grafana**: 
  - Username: `admin`
  - Password: `admin`

It is recommended to change the default password after the first login for security reasons.
