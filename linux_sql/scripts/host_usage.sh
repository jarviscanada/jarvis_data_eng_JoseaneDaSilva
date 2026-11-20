#! bin/bash

#Setup arguments
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

# Save vm stats in MB and current machine hostname to variables
vmstat_mb=$(vmstat --unit M)
hostname=$(hostname -f)

get_stats() {
  column="$1"
  echo "$vmstat_mb" | awk "{print $column}" | tail -n1 | xargs
}

# Retrieve hardware specification variables
memory_free=$(get_stats '$4')
cpu_idle=$(get_stats '$15')
cpu_kernel=$(get_stats '$14')
disk_io=$(vmstat --unit M -d | awk '{print $10}' | tail -n1 | xargs)
disk_available=$(df -BM / | awk '{print $4}' | tail -n1 | tr -d 'M' | xargs)
timestamp=$(date -u '+%F %H:%M:%S')

# Subquery to find matching id in host_info table
host_id="(SELECT id FROM host_info WHERE hostname='$hostname')";

# Inserts server usage data into host_usage table
insert_stmt="INSERT INTO host_usage (timestamp, host_id, memory_free, cpu_idle, cpu_kernel, disk_io, disk_available)
VALUES('$timestamp', $host_id, $memory_free, $cpu_idle, $cpu_kernel, $disk_io, $disk_available);"

#set up env var for psql cmd
export PGPASSWORD=$psql_password

#Insert date into a database
psql -h $psql_host -p $psql_port -d $db_name -U $psql_user -c "$insert_stmt"
exit $?
