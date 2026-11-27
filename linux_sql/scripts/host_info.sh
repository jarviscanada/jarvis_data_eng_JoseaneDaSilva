#! bin/bash

# Setup arguments
psql_host=$1
psql_port=$2
db_name=$3
psql_user=$4
psql_password=$5

# Validate arguments
if [ "$#" -ne 5 ]; then
  echo "Illegal number of parameters"
  exit 1
fi

# Save host info and current machine hostname to variables
lscpu_info=$(lscpu)
hostname=$(hostname -f)

get_information() {
  filter="$1"
  echo "$lscpu_info" | egrep "$filter" | awk -F: '{print $2}' | xargs
}

# Hardware information
cpu_number=$(get_information "^CPU\(s\):")
cpu_architecture=$(get_information "^Architecture:")
cpu_model=$(get_information "^Model\sname:")
cpu_ghz=$(get_information "^Model\sname:" | awk -F '@' '{print $2}' | tr -d 'GHz' | xargs)
l2_cache=$(get_information "^L2\scache:" | awk '{print $1}')
total_mem=$(vmstat | awk '{print $4}' | tail -n1 | xargs)
timestamp=$(date -u '+%F %H:%M:%S')

# Inserts server usage data into host_info table
insert_stmt="INSERT INTO host_info(hostname, cpu_number, cpu_architecture, cpu_model, cpu_mhz, l2_cache, timestamp, total_mem)
VALUES('$hostname', $cpu_number, '$cpu_architecture', '$cpu_model', 1000*$cpu_ghz, $l2_cache, '$timestamp', $total_mem);"

# Setup env var for psql cmd
export PGPASSWORD=$psql_password

#Insert date into a database
psql -h $psql_host -p $psql_port -d $db_name -U $psql_user -c "$insert_stmt"
exit $?
