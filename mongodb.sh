#!/bin/bash

USERID=$(id -u)
R="\e[31m"
G="\e[32m"
y="\e[33m"
N="\e[0m"

LOGS_FOLDER="/var/log/shell-roboshop"
SCRIPT_NAME=$( echo $0 | cut -d "." -f1 )
LOG_FILE="$LOGS_FOLDER/$SCRIPT_NAME.log"

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
        echo "$2 .... $G success $N"  | tee -a $LOG_FILE
    fi

}

cp mongo.repo /etc/yum.repos.d/mongo.repo
VALIDATE $? "Adding mongo repo"

dnf install mongodb -y &>>$LOG_FILE
VALIDATE $? "Installing Mongo DB"

systemctl enable mongod &>>$LOG_FILE
VALIDATE $? "Enable Mongo DB"

systemctl start mongod &>>$LOG_FILE
VALIDATE $? "Start Mongo DB"

