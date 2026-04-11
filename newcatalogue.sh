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
dnf module disable nodejs -y &>>$LOG_FILE
VALIDATE $? "Disable nodejs"

dnf module enable nodejs:20 -y &>>$LOG_FILE
VALIDATE $? "enable nodejs:20"

dnf install nodejs -y &>>$LOG_FILE
VALIDATE $? "finally installing nodejs"


if id roboshop &>/dev/null; then
    echo -e "User already exists ----- $Y Skipping $N"
else
    useradd --system --home /app --shell /sbin/nologin \
    --comment "roboshop system user" roboshop &>>$LOG_FILE

    VALIDATE $? "Creating user"
fi

mkdir -p /app 
VALIDATE $? "creating directory"

curl -o /tmp/catalogue.zip https://roboshop-artifacts.s3.amazonaws.com/catalogue-v3.zip &>>$LOG_FILE
VALIDATE $? "downloading code into temp"

cd /app 
VALIDATE $? "changing to app directory"

rm -rf /app/* 
VALIDATE $? "removing old code"

unzip /tmp/catalogue.zip &>>$LOG_FILE
VALIDATE $? "file unzipping from temp to app directory"

npm install &>>$LOG_FILE
VALIDATE $? "installing dependencys"

cp $SCRIPT_DIR/catalogue.service /etc/systemd/system/catalogue.service
VALIDATE $? "servicre code from service"

systemctl daemon-reload
VALIDATE $? "system reload"

systemctl enable catalogue &>>$LOG_FILE
VALIDATE $? "service enable"

systemctl start catalogue
VALIDATE $? "service start"

cp $SCRIPT_DIR/mongo.repo /etc/yum.repos.d/mongo.repo
VALIDATE $? "Copy mongo repo"

dnf install mongodb-mongosh -y &>>$LOG_FILE
VALIDATE $? "install mongdb client"

INDEX=$(mongosh mongodb.devaws.icu --quiet --eval "db.getMongo().getDBNames().indexOf('catalogue')")
if [ $INDEX -le 0 ]; then 
    mongosh --host mongodb.devaws.icu </app/db/master-data.js &>>$LOG_FILE   
    VALIDATE $? "loading products"
else echo -e "products alredy loaded -----$Y Skipping $N"
fi

systemctl restart catalogue
VALIDATE $? "restart service"