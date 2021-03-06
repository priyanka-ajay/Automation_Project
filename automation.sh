#!/bin/bash
#automation script for upgrad project
myname='Priyanka'
timestamp=$(date '+%d%m%Y-%H%M%S')
s3_bucket='upgrad-priyanka-1'
html_file=/var/www/html/inventory.html
cron_file=/etc/cron.d/automation

#updates the package information
apt update -y

#ensures that the HTTP Apache server is installed
if ! command -v apache2 &> /dev/null
then
	apt install apache2 -y
fi

#ensures that HTTP Apache server is running
if systemctl status apache2 | grep dead &> /dev/null
then
        systemctl start apache2
fi

#ensures that HTTP Apache service is enabled
if systemctl status apache2 | grep disabled &> /dev/null
then
        systemctl enable apache2
fi

#Create a tar archive of apache2 log files in the /var/log/apache2/ directory and place the tar into the /tmp/ directory
tar -cvf /tmp/${myname}-httpd-logs-${timestamp}.tar /var/log/apache2/*.log

#copy the archive to the s3 bucket
aws s3 \
cp /tmp/${myname}-httpd-logs-${timestamp}.tar \
s3://${s3_bucket}/${myname}-httpd-logs-${timestamp}.tar

file_size=`du -kh /tmp/${myname}-httpd-logs-${timestamp}.tar|awk -F' ' '{print $1}'`
#check if inventory.html is present or not
if test -f "$html_file"
then
        echo "httpd-logs         ${timestamp}         tar        ${file_size}" >> $html_file
else
        echo "Log Type         Time Created         Type        Size" > $html_file
        echo "httpd-logs         ${timestamp}         tar        ${file_size}" >> $html_file
fi
#check if cron job is scheduled or not
if ! test -f "$cron_file"
then
        echo "0 0 * * * root /root/Automation_Project/automation.sh" > $cron_file
fi

