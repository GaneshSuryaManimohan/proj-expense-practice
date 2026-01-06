#!/bin/bash

USERID=$(id -u)
TIME_STAMP=$(date +%F-%H-%M-%S)
SCRIPT_NAME=$(echo $0 | cut -d "." -f1)
LOGFILE=/tmp/$SCRIPT_NAME-$TIME_STAMP.log
R="\e[31m"
G="\e[32m"
Y="\e[33m"
N="\e[0m"

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
    echo "Please run this script as super user"
    exit 1
else
    echo "Running the script as super user"
fi

dnf list installed nginx &>>$LOGFILE
if [ $? -ne 0 ]
then
    dnf install nginx -y &>>$LOGFILE
    VALIDATE $? "Installing NginX"
else
    echo -e "NginX is already installed....$Y SKIPPING $N"
fi

systemctl enable nginx &>>$LOGFILE
VALIDATE $? "Enabling NginX"

systemctl start nginx &>>$LOGFILE
VALIDATE $? "Starting NginX"

rm -rf /usr/share/nginx/html/* &>>$LOGFILE
VALIDATE $? "Removing default html file"

curl -o /tmp/frontend.zip https://expense-builds.s3.us-east-1.amazonaws.com/expense-frontend-v2.zip &>>$LOGFILE
VALIDATE $? "Downloading Frontend Code"

cd /usr/share/nginx/html 
unzip /tmp/frontend.zip &>>$LOGFILE
VALIDATE $? "Extracting Frontend Code"

cp /home/ec2-user/proj-expense-practice/expense.conf /etc/nginx/default.d/expense.conf &>>$LOGFILE
VALIDATE $? "Copying expense.conf"

systemctl restart nginx &>>$LOGFILE
VALIDATE $? "Restarting NginX"