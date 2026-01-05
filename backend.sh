#!/bin/bash

USERID=$(id -u)
TIME_STAMP=$(date +%F-%H-%M-%S)
SCRIPT_NAME=$(echo $0 | cut -d "." -f1)
LOGFILE=/tmp/$SCRIPT_NAME-$TIME_STAMP.log
R="\e[31m"
G="\e[32m"
Y="\e[33m"
N="\e[0m"
echo "Please enter root password for MySQL::"
read -s mysql_root_password

VALIDATE(){
    if [ $1 -ne 0 ]
    then
        echo -e "$2....$R FAILURE $N"
        exit 1
    else
        echo -e "$2....$G SUCCESS $N"
    fi
}

if [ $USERID -ne 0 ]
then
    echo "Please run this script as root user"
    exit 1
else
    echo "Running the script as root user"
fi

dnf module disable nodejs -y &>>$LOGFILE
VALIDATE $? "Disabling default nodejs"

dnf module enable nodejs:20 -y &>>$LOGFILE
VALIDATE $? "Enabling nodejs:20"

dnf list installed nodejs &>>$LOGFILE
if [ $? -ne 0 ]
then
    dnf install nodejs &>>$LOGFILE
    VALIDATE $? "Installing nodejs"
else
    echo "nodejs is already installed....$Y SKIPPING $N"
fi

id expense &>>$LOGFILE
if [ $? -ne 0 ]
then
    useradd expense &>>$LOGFILE
    VALIDATE $? "Adding user expense"
else
    echo -e "expense user is already present....$Y SKIPPING $N"
fi

mkdir -p /app &>>$LOGFILE

curl -o /tmp/backend.zip https://expense-builds.s3.us-east-1.amazonaws.com/expense-backend-v2.zip &>>$LOGFILE
VALIDATE $? "Downloading Backend Code"

cd /app &>>$LOGFILE
unzip /tmp/backend.zip &>>$LOGFILE
VALIDATE $? "Extracting Backend Code"

npm install &>>$LOGFILE
VALIDATE $? "Installing nodejs dependencies"

cp /home/ec2-user/proj-expense-practice/backend.service /etc/systemd/system/backend.service &>>$LOGFILE
VALIDATE $? "Copy Backend Service"

systemctl daemon-reload &>>$LOGFILE
VALIDATE $? "daemon reload"

systemctl start backend &>>$LOGFILE
VALIDATE $? "starting backend"

systemctl enable backend &>>$LOGFILE
VALIDATE $? "enable backend"


dnf list installed mysql &>>$LOGFILE
if [ $? -ne 0 ]
then
    dnf install mysql -y &>>$LOGFILE
    VALIDATE $? "Installing mysql"
else
    echo "mysql is already installed....$Y SKIPPING $N"
fi

mysql -h db.surya-devops.site -uroot -p${mysql_root_password} < /app/schema/backend.sql &>>$LOGFILE
VALIDATE $? "Loading DB schema"

systemctl restart backend &>>$LOGFILE
VALIDATE $? "Restarting Backend Service"