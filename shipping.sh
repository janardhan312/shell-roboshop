#!/bin/bash 

USERID=$(id -u)
R="\e[31m"
G="\e[32m"
Y="\e[33m"
N="\e[0m"

LOGS_FOLDER="/var/log/shell-roboshop"
SCRIPT_NAME=$( echo $0 | cut -d "." -f1 )
SCRIPT_DIR=$PWD
MONGODB_HOST=mongodb.devaws.icu
LOG_FILE="$LOGS_FOLDER/$SCRIPT_NAME.log"
MYSQL_HOST=mysql.devaws.icu

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

dnf install maven -y &>>$LOG_FILE
VALIDATE $? "Disable nodejs"


if id roboshop &>/dev/null; then
    echo -e "User already exists ----- $Y Skipping $N"
else
    useradd --system --home /app --shell /sbin/nologin \
    --comment "roboshop system user" roboshop &>>$LOG_FILE

    VALIDATE $? "Creating user"
fi

mkdir -p /app 
VALIDATE $? "creating directory"

curl -o /tmp/shipping.zip https://roboshop-artifacts.s3.amazonaws.com/shipping-v3.zip &>>$LOG_FILE
VALIDATE $? "downloading code into temp"

cd /app 
VALIDATE $? "changing to app directory"

rm -rf /app/* 
VALIDATE $? "removing old code"

unzip /tmp/shipping.zip &>>$LOG_FILE
VALIDATE $? "file unzipping from temp to app directory"

mvn clean package &>>$LOG_FILE
VALIDATE $? "installing dependencys"

mv target/shipping-1.0.jar shipping.jar
VALIDATE $? "Target file"

cp $SCRIPT_DIR/shipping.service /etc/systemd/system/shipping.service
VALIDATE $? "servicre code from service"

systemctl daemon-reload
VALIDATE $? "system reload"

systemctl enable shipping &>>$LOG_FILE
VALIDATE $? "service enable"

dnf install mysql -y 


mysql -h $MYSQL_HOST -uroot -pRoboShop@1 -e 'use mysql'
if [ $? -ne 0 ]; then
    mysql -h $MYSQL_HOST -uroot -pRoboShop@1 < /app/db/schema.sql
    mysql -h $MYSQL_HOST -uroot -pRoboShop@1 < /app/db/app-user.sql 
    mysql -h $MYSQL_HOST -uroot -pRoboShop@1 < /app/db/master-data.sql
else 
    echo -e "Skipping data is alredy installed.... $Y Skipping $N"
fi


systemctl restart shipping
VALIDATE $? "service start"
