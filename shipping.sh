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
MYSQL_HOST=mysql.devaws.icu

mkdir -p $LOGS_FOLDER
echo "script execution time $(date)" | tee -a $LOG_FILE

if [ $USERID -ne 0 ]; then
    echo "Kindly run with root user"
    exit 1
fi

VALIDATE(){
    if [ $1 -ne 0 ]; then
        echo -e "$2 ..... $R FAILED $N" | tee -a $LOG_FILE
        exit 1
    else 
        echo -e "$2 ..... $G SUCCESS $N" | tee -a $LOG_FILE
    fi
}

# ✅ Install Java (MANDATORY)
dnf install java-17-openjdk -y &>>$LOG_FILE
VALIDATE $? "Installing Java"

# ✅ Install Maven
dnf install maven -y &>>$LOG_FILE
VALIDATE $? "Installing Maven"

# ✅ Create user
if id roboshop &>/dev/null; then
    echo -e "User already exists ----- $Y Skipping $N"
else
    useradd --system --home /app --shell /sbin/nologin \
    --comment "roboshop system user" roboshop &>>$LOG_FILE
    VALIDATE $? "Creating user"
fi

# ✅ App setup
mkdir -p /app 
VALIDATE $? "Creating directory"

curl -o /tmp/shipping.zip https://roboshop-artifacts.s3.amazonaws.com/shipping-v3.zip &>>$LOG_FILE
VALIDATE $? "Downloading code"

cd /app 
rm -rf /app/*
VALIDATE $? "Cleaning old code"

unzip /tmp/shipping.zip &>>$LOG_FILE
VALIDATE $? "Unzipping code"

mvn clean package &>>$LOG_FILE
VALIDATE $? "Building application"

mv target/shipping-1.0.jar shipping.jar
VALIDATE $? "Renaming jar"

# ✅ Service setup
cp $SCRIPT_DIR/shipping.service /etc/systemd/system/shipping.service
VALIDATE $? "Copying service file"

systemctl daemon-reload
VALIDATE $? "Daemon reload"

systemctl enable shipping &>>$LOG_FILE
VALIDATE $? "Enabling service"

# ✅ Install MySQL client
dnf install mysql -y &>>$LOG_FILE
VALIDATE $? "Installing MySQL client"

# ✅ Load DB schema (only if needed)
mysql -h $MYSQL_HOST -uroot -pRoboShop@1 -e 'use mysql' &>>$LOG_FILE
if [ $? -ne 0 ]; then
    mysql -h $MYSQL_HOST -uroot -pRoboShop@1 < /app/db/schema.sql
    mysql -h $MYSQL_HOST -uroot -pRoboShop@1 < /app/db/app-user.sql 
    mysql -h $MYSQL_HOST -uroot -pRoboShop@1 < /app/db/master-data.sql
    VALIDATE $? "Loading DB schema"
else 
    echo -e "DB already exists ----- $Y Skipping $N"
fi

# ✅ Start service
systemctl restart shipping
sleep 5

systemctl is-active shipping &>>$LOG_FILE
VALIDATE $? "Shipping service running"

# ✅ Open port 8080 in firewall (if firewalld installed)
systemctl enable firewalld &>>$LOG_FILE
systemctl start firewalld &>>$LOG_FILE

firewall-cmd --permanent --add-port=8080/tcp &>>$LOG_FILE
firewall-cmd --reload &>>$LOG_FILE
VALIDATE $? "Opening port 8080"

# ✅ Verify port
ss -lntp | grep 8080 &>>$LOG_FILE
VALIDATE $? "Port 8080 is listening"