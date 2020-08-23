#!/bin/sh

service sshd start

rm -f /usr/local/redis/var/run/redis_6379.pid
/sbin/runuser -l redis -c "/usr/local/redis/bin/redis-server /usr/local/redis/etc/redis.conf"

rm -f /var/lib/mysql/mysql.sock /var/lib/mysql/mysql.sock.lock
chown -R mysql:mysql /var/lib/mysql /var/log/mysql && service mysqld start

rm -f /usr/local/php-5.2.17/var/run/php-fpm.pid
/sbin/service php-fpm start

rm -f /var/run/nginx.pid
/usr/sbin/nginx

sleep 1

auth_lock_file=/var/log/docker_init_auth.lock

if [ ! -z "${PUBLIC_STR}" ]; then
    if [ -f ${auth_lock_file} ]; then
        echo "`date "+%Y-%m-%d %H:%M:%S"` [信息] 跳过添加公钥"
    else
        echo "${PUBLIC_STR}" >> /root/.ssh/authorized_keys

        if [ $? -eq 0 ]; then
            echo "`date "+%Y-%m-%d %H:%M:%S"` [信息] 公钥添加成功"
            echo `date "+%Y-%m-%d %H:%M:%S"` > ${auth_lock_file}
        else
            echo "`date "+%Y-%m-%d %H:%M:%S"` [错误] 公钥添加失败"
            exit 1
        fi
    fi
fi

mysql_lock_file=/var/log/docker_init_mysql.lock

if [ -z "${MYSQL_ROOT_PASSWORD}" ]; then
    echo "`date "+%Y-%m-%d %H:%M:%S"` [错误] 必须指定MySQL新密码"
    exit 1
else
    if [ -f ${mysql_lock_file} ]; then
        echo "`date "+%Y-%m-%d %H:%M:%S"` [信息] 跳过修改MySQL密码"
    else
        echo "`date "+%Y-%m-%d %H:%M:%S"` [信息] MySQL新密码："${MYSQL_ROOT_PASSWORD}

        init_password=`grep 'A temporary password is generated for' /var/log/mysql/mysqld.log|awk '{print $NF}'|tail -n 1`
        echo "`date "+%Y-%m-%d %H:%M:%S"` [信息] MySQL初始密码："${init_password}
        
        mysqladmin -uroot -p${init_password} password "${MYSQL_ROOT_PASSWORD}"

        if [ $? -eq 0 ]; then
            echo "`date "+%Y-%m-%d %H:%M:%S"` [信息] MySQL密码修改成功"
        else
            echo "`date "+%Y-%m-%d %H:%M:%S"` [错误] MySQL密码修改失败"
            exit 1
        fi

        mysql -uroot -p"${MYSQL_ROOT_PASSWORD}" -e \
            "CREATE USER 'root'@'%' IDENTIFIED BY '${MYSQL_ROOT_PASSWORD}';GRANT ALL ON *.* TO 'root'@'%' WITH GRANT OPTION;"

        if [ $? -eq 0 ]; then
            echo "`date "+%Y-%m-%d %H:%M:%S"` [信息] 设置MySQL远程登录成功"
        else
            echo "`date "+%Y-%m-%d %H:%M:%S"` [错误] 设置MySQL远程登录失败"
            exit 1
        fi

        # 密码和远程登录设置成功后锁定
        echo `date "+%Y-%m-%d %H:%M:%S"` > ${mysql_lock_file}
    fi
fi

# 保持前台运行，不退出
while true
do
    sleep 3600
done
