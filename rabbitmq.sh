#!/bin/bash

USERID=$(id -u)
R="\e[31m"
G="\e[32m"
Y="\e[33m"
N="\e[0m"

LOGS_FOLDER="/var/log/shell-roboshop"
SCRIPT_NAME=$( echo $0 | cut -d "." -f1 )
LOG_FILE="$LOGS_FOLDER/$SCRIPT_NAME.log"
SCRIPT_DIR=$PWD

mkdir -p $LOGS_FOLDER
echo "Script execute at: $(date)" | tee -a $LOG_FILE

if [ $USERID -ne 0 ]; then
    echo "Error:: kindly run with the root user"
    exit 1
fi

VALIDATE(){
    if [ $1 -ne 0 ]; then
        echo -e "$2 ... $R Error $N" | tee -a $LOG_FILE
        exit 1
    else
        echo -e "$2 .... $G success $N"  | tee -a $LOG_FILE
    fi
}

cp $SCRIPT_DIR/rabbitmq.repo /etc/yum.repos.d/rabbitmq.repo
VALIDATE $? "Adding rabbitmq Repo"

dnf install rabbitmq-server -y
VALIDATE $? "Installing rabbitmq"

systemctl enable rabbitmq-server
VALIDATE $? "Enabling rabbitmq"

systemctl start rabbitmq-server
VALIDATE $? "Starting rabbitmq"

# ✅ Correct check for RabbitMQ user
rabbitmqctl list_users | grep -w roboshop &>/dev/null
if [ $? -ne 0 ]; then
    rabbitmqctl add_user roboshop roboshop123
    VALIDATE $? "Adding RabbitMQ user"
else
    echo -e "RabbitMQ user already exists ----- $Y Skipping $N" | tee -a $LOG_FILE
fi

rabbitmqctl set_permissions -p / roboshop ".*" ".*" ".*"
VALIDATE $? "Setting permissions"