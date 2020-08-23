FROM centos:6

ENV TZ Asia/Shanghai
ENV LANG en_US.UTF-8

####################
# 1. 初始化CentOS6
####################
RUN mkdir /root/.ssh
RUN touch /root/.ssh/authorized_keys
RUN chmod 600 /root/.ssh/authorized_keys

RUN rpm --import /etc/pki/rpm-gpg/RPM-GPG-KEY-CentOS-6
RUN sed -i 's/enabled=1/enabled=0/' /etc/yum/pluginconf.d/fastestmirror.conf
RUN echo "exclude=*.i386 *.i586 *.i686" >> /etc/yum.conf
COPY file/etc/yum.repos.d/CentOS-Base.repo /etc/yum.repos.d/CentOS-Base.repo

RUN yum install -y epel-release && rpm --import /etc/pki/rpm-gpg/RPM-GPG-KEY-EPEL-6
COPY file/etc/yum.repos.d/epel.repo /etc/yum.repos.d/epel.repo

RUN yum update -y

RUN yum -y install telnet openssl-devel iproute vim-enhanced chrony wget curl screen sudo rsync tcpdump strace openssh-server openssh-clients

RUN echo set fencs=utf-8,gbk >>/etc/vimrc

# 关闭SELINUX
RUN echo SELINUX=disabled>/etc/selinux/config
RUN echo SELINUXTYPE=targeted>>/etc/selinux/config

# 配置SSH服务
RUN echo "*               soft   nofile            65535" >> /etc/security/limits.conf
RUN echo "*               hard   nofile            65535" >> /etc/security/limits.conf
RUN sed -i "s/#UseDNS yes/UseDNS no/" /etc/ssh/sshd_config
RUN sed -i "s/GSSAPIAuthentication yes/GSSAPIAuthentication no/" /etc/ssh/sshd_config
RUN sed -i "s/GSSAPICleanupCredentials yes/GSSAPICleanupCredentials no/" /etc/ssh/sshd_config
RUN sed -i "s/#MaxAuthTries 6/MaxAuthTries 10/" /etc/ssh/sshd_config
RUN sed -i "s/#ClientAliveInterval 0/ClientAliveInterval 30/" /etc/ssh/sshd_config
RUN sed -i "s/#ClientAliveCountMax 3/ClientAliveCountMax 10/" /etc/ssh/sshd_config

####################
# 2. 安装PHP-5.2.17
####################
COPY pkg/bin/php-5.2.17_el6.x86_64.tar.gz /tmp
RUN tar xf /tmp/php-5.2.17_el6.x86_64.tar.gz -C /usr/local
RUN yum install -y libmcrypt freetype mhash mysql-libs libtool-ltdl libpng gd libjpeg-turbo
COPY file/etc/init.d/php-fpm /etc/init.d/php-fpm

# 创建用户
RUN useradd --home-dir /usr/local/php-5.2.17/var/lib/php --create-home --user-group --shell /sbin/nologin --comment "PHP-FPM User" php
RUN chown -R root:root /usr/local/php-5.2.17/
RUN chown -R php:php /usr/local/php-5.2.17/var/

# 链接
RUN ln -s /usr/local/php-5.2.17 /usr/local/php
RUN ln -s /usr/local/php/bin/* /usr/local/bin

# 复制配置文件
COPY file/usr/local/php/etc/php.ini /usr/local/php/etc/php.ini
COPY file/usr/local/php/etc/php-fpm.conf /usr/local/php/etc/php-fpm.conf

####################
# 3. 安装Nginx
####################
COPY pkg/rpm/nginx-1.18.0-1.el6.ngx.x86_64.rpm /tmp/
RUN yum install -y /tmp/nginx-1.18.0-1.el6.ngx.x86_64.rpm
COPY file/etc/nginx/nginx.conf /etc/nginx/nginx.conf

# 配置PHP-FPM默认站点
COPY file/etc/nginx/conf.d/default.conf /etc/nginx/conf.d/default.conf
RUN mkdir -p /data/web/default
RUN echo '<?php phpinfo(); ?>' > /data/web/default/index.php
RUN chown -R php:nginx /data/web/default
RUN chmod 755 /etc/init.d/php-fpm

####################
# 4. 安装MySQL 5.7
####################
#COPY pkg/rpm/mysql-* /tmp/

WORKDIR /tmp/
RUN wget -c https://mirrors.163.com/mysql/Downloads/MySQL-5.7/mysql-community-common-5.7.31-1.el6.x86_64.rpm
RUN wget -c https://mirrors.163.com/mysql/Downloads/MySQL-5.7/mysql-community-libs-5.7.31-1.el6.x86_64.rpm
RUN wget -c https://mirrors.163.com/mysql/Downloads/MySQL-5.7/mysql-community-libs-compat-5.7.31-1.el6.x86_64.rpm
RUN wget -c https://mirrors.163.com/mysql/Downloads/MySQL-5.7/mysql-community-client-5.7.31-1.el6.x86_64.rpm
RUN wget -c https://mirrors.163.com/mysql/Downloads/MySQL-5.7/mysql-community-devel-5.7.31-1.el6.x86_64.rpm
RUN wget -c https://mirrors.163.com/mysql/Downloads/MySQL-5.7/mysql-community-server-5.7.31-1.el6.x86_64.rpm

# 卸载已经安装的MySQL组件
WORKDIR /root/
RUN yum remove -y mysql-*

# 安装MySQL
RUN yum install -y /tmp/mysql-community-common-5.7.31-1.el6.x86_64.rpm
RUN yum install -y /tmp/mysql-community-libs-5.7.31-1.el6.x86_64.rpm
RUN yum install -y /tmp/mysql-community-libs-compat-5.7.31-1.el6.x86_64.rpm
RUN yum install -y /tmp/mysql-community-client-5.7.31-1.el6.x86_64.rpm
RUN yum install -y /tmp/mysql-community-devel-5.7.31-1.el6.x86_64.rpm
RUN yum install -y /tmp/mysql-community-server-5.7.31-1.el6.x86_64.rpm

# 设置配置文件
RUN rm -f /etc/my.cnf
COPY file/etc/my.cnf /etc/my.cnf

# 初始化MySQL
RUN mkdir /var/log/mysql/
RUN mysqld --initialize
RUN chown -R mysql:mysql /var/lib/mysql /var/log/mysql
RUN rm -f /var/log/mysqld.log

####################
# 5. 安装Redis6-解压安装
# ####################
COPY pkg/bin/redis-6.0.6_el6.x86_64.tar.gz /tmp/
RUN tar xf /tmp/redis-6.0.6_el6.x86_64.tar.gz -C /usr/local

# 创建用户
RUN useradd --home-dir /usr/local/redis-6.0.6/var/lib --no-create-home --user-group --shell /bin/bash --comment "Redis Database Server" redis
RUN chown -R root:root /usr/local/redis-6.0.6/
RUN chown -R redis:redis /usr/local/redis-6.0.6/var/

# 链接
RUN ln -s /usr/local/redis-6.0.6 /usr/local/redis
RUN ln -s /usr/local/redis/bin/* /usr/local/bin

# 复制配置文件
COPY file/usr/local/redis/etc/redis.conf /usr/local/redis/etc/redis.conf

####################
# 清理
####################
RUN rm -f /tmp/*.rpm /tmp/*.tar.gz
RUN yum clean all

####################
# 设置开机启动
####################
COPY file/usr/local/bin/docker-entrypoint.sh /usr/local/bin/docker-entrypoint.sh
RUN chmod 755 /usr/local/bin/docker-entrypoint.sh

ENTRYPOINT ["/usr/local/bin/docker-entrypoint.sh"]

WORKDIR /root

EXPOSE 80 3306 6379
