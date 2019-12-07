#!/bin/bash
# Date: 2019.08.12

# $1: 收件人
# $2: 标题
# $3: 内容

echo "`date "+%F %T"` 开始发送邮件" >> /var/log/zbx_mail.log
messages=`echo $3 | tr '\r\n' '\n'`
subject=`echo $2 | tr '\r\n' '\n'`
echo "${messages}" | mail -s "${subject}" $1
echo "`date "+%F %T"` 发送完成" >> /var/log/zbx_mail.log
