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
    echo "Please run this script as root user"
    exit 1
else
    echo "Running the script as root user"
fi

dnf install mysql-server -y &>>$LOGFILE
VALIDATE $? "Installing mysql-server"

systemctl enable mysqld &>>$LOGFILE
VALIDATE $? "enabling mysqld"

systemctl start mysqld &>>$LOGFILE
VALIDATE $? "starting mysqld"

mysql_secure_installation --set-root-pass ExpenseApp@1 &>>$LOGFILE
VALIDATE $? "Setting up root password"