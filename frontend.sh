#!/bin/bash 

USERID=$(id -u)
R="\e[31m"
G="\e[32m"
Y="\e[33m"
N="\e[0m"

LOGS_FOLDER="/var/log/shell-roboshop"
SCRIPT_NAME=$( echo $0 | cut -d "." -f1 )
SCRIPT_DIR=$PWD
LOG_FILE="$LOGS_FOLDER/$SCRIPT_NAME.log"

mkdir -p $LOGS_FOLDER
echo "script execure time $(date)" | tee -a $LOG_FILE

if [ $USERID -ne 0 ]; then
    echo "Kindly run wih root user"
    exit 1
else 
    echo "sucess" 
fi

VALIDATE(){
    if [ $1 -ne 0 ]; then
        echo -e "$2 ..... $R Error $N" | tee -a $LOG_FILE
        exit 1
    else 
        echo -e "$2 ..... $G Success $N" | tee -a $LOG_FILE
    fi
}

dnf module disable nginx -y &>>$LOG_FILE
VALIDATE $? "Disable nginx"

dnf module enable nginx:1.24 -y &>>$LOG_FILE
VALIDATE $? "new version enable nginx"

dnf install nginx -y &>>$LOG_FILE
VALIDATE $? "finally installing nginx"

systemctl enable nginx &>>$LOG_FILE
VALIDATE $? "enable nginx"

systemctl start nginx &>>$LOG_FILE
VALIDATE $? "start nginx"

rm -rf /usr/share/nginx/html/* &>>$LOG_FILE
VALIDATE $? "remove old code nginx"

curl -o /tmp/frontend.zip https://roboshop-artifacts.s3.amazonaws.com/frontend-v3.zip &>>$LOG_FILE
VALIDATE $? "downloading code into temp"


cd /usr/share/nginx/html 
unzip /tmp/frontend.zip
VALIDATE $? "downloading front end code"

rm -rf /etc/nginx/nginx.conf

cp $SCRIPT_DIR/nginx.conf /etc/nginx/nginx.conf
VALIDATE $? "copy code from conf nginx service"

systemctl restart nginx &>>$LOG_FILE
VALIDATE $? "restart service"

systemctl enable firewalld &>>$LOG_FILE
systemctl start firewalld &>>$LOG_FILE

firewall-cmd --permanent --add-port=8080/tcp &>>$LOG_FILE
firewall-cmd --reload &>>$LOG_FILE
VALIDATE $? "Opening port 8080"

# ✅ Verify port
ss -lntp | grep 8080 &>>$LOG_FILE
VALIDATE $? "Port 8080 is listening"