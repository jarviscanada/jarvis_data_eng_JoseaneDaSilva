#!/bin/sh

# Capture CLI arguments
cmd=$1
db_username=$2
db_password=$3
container_name="jrvs-psql"

# Start docker
sudo systemctl status docker > /dev/null || sudo systemctl start docker

# Check container status and redirect output and error message to /dev/null
docker container inspect $container_name > /dev/null 2> /dev/null
container_status=$?

# User switch case to handle ceate|start|stop operations
case $cmd in
    create)
    # Check if the container is already created
    if [ $container_status -eq 0 ]; then
        echo 'Container already exist!'
        exit 1
    fi

    # Check if an argument is missing
    if [ $# -ne 3 ]; then
        echo 'Create requires username and password'
       exit 1
    fi

    # Create container
    docker volume create pgdata
    # Start the container
    docker run  --name $container_name -e POSTGRES_USER=$db_username -e POSTGRES_PASSWORD=$db_password -d -v pgdata:/var/lib/postgresql/data -p 5432:5432 postgres:9.6-alpine
    exit $?
    ;;

    start|stop)
    # Check instance status; exit 1 if container has not been created
    if [ $container_status -ne 0 ]; then
	echo 'Container has not  being created!'
	exit 1
    fi

    # Start or stop the container
    docker container $cmd $container_name
    exit $?
    ;;

    *)
    echo 'Illegal command'
    echo 'Commands: start|stop|create'
    exit 1
    ;;
esac
