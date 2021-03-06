#!/bin/bash
set -e

logger() {
  DT=$(date '+%Y/%m/%d %H:%M:%S')
  echo "$DT utility.sh: $1"
  echo "$DT utility.sh: $1" | sudo tee -a /var/log/user_data.log > /dev/null
}

logger "Begin script"

NODE_NAME="$(hostname)"
logger "Node name: $NODE_NAME"

METADATA_LOCAL_IP=`curl ${local_ip_url}`
logger "Local IP: $METADATA_LOCAL_IP"

logger "Configuring Consul"
CONSUL_DEFAULT_CONFIG=/etc/consul.d/default.json
CONSUL_DATA_DIR=${data_dir}/consul/data

sudo mkdir -p $CONSUL_DATA_DIR
sudo chmod 0755 $CONSUL_DATA_DIR

sudo sed -i -- "s/{{ data_dir }}/$${CONSUL_DATA_DIR//\//\\\/}/g" $CONSUL_DEFAULT_CONFIG
sudo sed -i -- "s/{{ datacenter }}/${datacenter}/g" $CONSUL_DEFAULT_CONFIG
sudo sed -i -- "s/{{ node_name }}/$NODE_NAME/g" $CONSUL_DEFAULT_CONFIG
sudo sed -i -- "s/{{ local_ip }}/$METADATA_LOCAL_IP/g" $CONSUL_DEFAULT_CONFIG
sudo sed -i -- "s/{{ log_level }}/${consul_log_level}/g" $CONSUL_DEFAULT_CONFIG
sudo sed -i -- "s/{{ consul_server_encrypt_key }}/${consul_server_encrypt_key}/g" $CONSUL_DEFAULT_CONFIG

logger "Configuring Consul Utility"
CONSUL_UTILITY_CONFIG=/etc/consul.d/utility.json

sudo sed -i -- "s/\"{{ tags }}\"/\"${provider}\", \"${region}\", \"${zone}\", \"${machine_type}\"/g" $CONSUL_UTILITY_CONFIG

logger "Configuring Consul Redis and Statsite"
sudo sed -i -- "s/{{ local_ip }}/$METADATA_LOCAL_IP/g" /etc/consul.d/redis.json
sudo sed -i -- "s/{{ local_ip }}/$METADATA_LOCAL_IP/g" /etc/consul.d/statsite.json

echo $(date '+%s') | sudo tee -a /etc/consul.d/configured > /dev/null
sudo service consul start || sudo service consul restart

STATSITE_DATA_DIR=${data_dir}/statsite/data

sudo mkdir -p $STATSITE_DATA_DIR
sudo chmod 0755 $STATSITE_DATA_DIR

sudo sed -i -- "s/{{ data_dir }}/$${STATSITE_DATA_DIR//\//\\\/}/g" /etc/statsite.d/default.conf

echo $(date '+%s') | sudo tee -a /etc/statsite.d/configured > /dev/null
sudo service statsite start || sudo service statsite restart

logger "Done"
