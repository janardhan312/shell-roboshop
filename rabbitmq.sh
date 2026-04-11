#!/bin/bash

USERID=$(id -u)
R="\e[31m"
G="\e[32m"
y="\e[33m"
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

dnf install rabbitmq-server -y
VALIDATE $? "Installing rabbitmq"

systemctl enable rabbitmq-server
VALIDATE $? "enable rabbitmq"

systemctl start rabbitmq-server
VALIDATE $? "enable rabbitmq"

rabbitmqctl add_user roboshop roboshop123
VALIDATE $? "user adding rabbitmq"

rabbitmqctl set_permissions -p / roboshop ".*" ".*" ".*"
VALIDATE $? "setting permissions "