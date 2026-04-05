#!/bin/bash 

USERID=$(id -u)
R="\e[31m"
G="\e[32m"
Y="\e[33m"
N="\e[0m"

LOGS_FOLDER="/var/log/shell-roboshop"
SCRIPT_NAME=$( echo $0 | cut -d "." -f1 )
SCRIPT_DIR=$PWD
MONGODB_HOST=mongodb.devsaws.icu
SCRIPT_DIR=$pwd
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

dnf module disable nodejs -y &>>$LOG_FILE
VALIDATE $? "Disable nodejs"

dnf module enable nodejs:20 -y &>>$LOG_FILE
VALIDATE $? "enable nodejs:20"

dnf install nodejs -y &>>$LOG_FILE
VALIDATE $? "finally installing nodejs"

useradd --system --home /app --shell /sbin/nologin --comment "roboshop system user" roboshop &>>$LOG_FILE
VALIDATE $? "creating user"

mkdir /app 
VALIDATE $? "creating directory"

curl -o /tmp/catalogue.zip https://roboshop-artifacts.s3.amazonaws.com/catalogue-v3.zip &>>$LOG_FILE
VALIDATE $? "downloading code into temp"

cd /app 
VALIDATE $? "changing to app directory"

unzip /tmp/catalogue.zip &>>$LOG_FILE
VALIDATE $? "file unzipping from temp to app directory"

##cd /app 
npm install &>>$LOG_FILE
VALIDATE $? "installing dependencys"

cp $SCRIPT_DIR/catalogue.service /etc/systemd/system/catalogue.service ### call SCRIPT_DIR before catalogue.service .........................
VALIDATE $? "servicre code from service.sh"

systemctl daemon-reload
VALIDATE $? "system reload"

systemctl enable catalogue &>>$LOG_FILE
VALIDATE $? "service enable"

systemctl start catalogue
VALIDATE $? "service start"


cp $SCRIPT_DIR/mongo.repo /etc/yum.repos.d/mongo.repo  ### call SCRIPT_DIR before mongo.repo ........................................
VALIDATE $? "copy mongo repo"

dnf install mongodb-mongosh -y &>>$LOG_FILE
VALIDATE $? "install mongdb client"

mongosh --host $MONGODB_HOST </app/db/master-data.js &>>$LOG_FILE   
VALIDATE $? "loading products"
##mongosh --host $MONGODB_HOST

systemctl restart catalogue
VALIDATE $? "restart service"