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

dnf install python3 gcc python3-devel -y &>>$LOG_FILE

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

curl -o /tmp/payment.zip https://roboshop-artifacts.s3.amazonaws.com/payment-v3.zip &>>$LOG_FILE
VALIDATE $? "Downloading code"

cd /app 
rm -rf /app/*
VALIDATE $? "Cleaning old code"

unzip /tmp/payment.zip &>>$LOG_FILE
VALIDATE $? "Unzipping code"

pip3 install -r requirements.txt &>>$LOG_FILE
VALIDATE $? "python dependencys"

# ✅ Service setup
cp $SCRIPT_DIR/payment.service /etc/systemd/system/payment.service
VALIDATE $? "Copying service file"

systemctl daemon-reload
VALIDATE $? "Daemon reload"

systemctl enable payment &>>$LOG_FILE
VALIDATE $? "Enabling service"

# ✅ Start service
systemctl restart payment
sleep 5

systemctl is-active payment &>>$LOG_FILE
VALIDATE $? "payment service running"

# ✅ Open port 8080 in firewall (if firewalld installed)
systemctl enable firewalld &>>$LOG_FILE
systemctl start firewalld &>>$LOG_FILE

firewall-cmd --permanent --add-port=8080/tcp &>>$LOG_FILE
firewall-cmd --reload &>>$LOG_FILE
VALIDATE $? "Opening port 8080"

# ✅ Verify port
ss -lntp | grep 8080 &>>$LOG_FILE
VALIDATE $? "Port 8080 is listening"