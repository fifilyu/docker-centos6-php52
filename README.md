# docker-centos6-php52

基于CentOS6 + PHP-5.2的Docker镜像。

## 0. 构建镜像

### 克隆Dockerfile项目

#### 方法一（国内）

    git clone https://gitee.com/fifilyu/docker-centos6-php52.git

#### 方法二（全球）

    git clone https://github.com/fifilyu/docker-centos6-php52.git

### 构建镜像

    cd docker-centos6-php52
    sudo docker build -t fifilyu/docker-centos6-php52:latest .

## 1. 环境组件列表

1. PHP-5.2.17（PHP-FPM）
2. Zend Optimizer
3. Nginx 1.8
4. MySQL 5.7.31
5. Redis 6.0.6

## 2. 开发相关

### 2.1 开放端口

容器类的服务，默认监听 `0.0.0.0`：

* SSH->22
* Nginx->80
* MySQL->3306
* Redis->6379

MySQL、Redis的客户端工具可以连接容器内的服务端口，这样可以直接导入、导出、管理数据。

也能通过SSH+私钥方式连接容器的22端口，方便查看日志等等。

### 2.2 使用Hosting数据目录启动一个容器

    docker run -d \
        -e MYSQL_ROOT_PASSWORD=wdtech \
        -v /some/content:/data/web/default:ro \
        --name some-centos6-php52 fifilyu/docker-centos6-php52:latest

将本地目录 `/some/content` 挂载到容器的 `/data/web/default` 目录。

本地用 Visual Studio Code 打开目录 `/some/content`，作为写PHP代码的工作空间。

挂载后，更新本地PHP代码，访问 http://容器IP 可以直接看到效果，不用再上传。

### 2.3 自定义设置

自定义配置参数，可以直接通过Docker命令进入bash编辑：

    docker exec -it 容器名称 bash

或者通过SSH+私钥方式连接容器的22端口：

    ssh 容器IP

## 3. 使用方法

### 3.1 启动一个容器很简单

    docker run -d \
        --env LANG=en_US.UTF-8 \
	    --env TZ=Asia/Shanghai \
        -e MYSQL_ROOT_PASSWORD=wdtech \
        --name some-centos6-php52 fifilyu/docker-centos6-php52:latest

此时访问 http://容器IP 能看到 PHP 版本信息。

另外，必须指定 `MYSQL_ROOT_PASSWORD` 参数，用于设置MySQL的root用户密码。

### 3.2 启动带公钥的容器

    docker run -d \
        --env LANG=en_US.UTF-8 \
	    --env TZ=Asia/Shanghai \
        -e MYSQL_ROOT_PASSWORD=wdtech \
        -e PUBLIC_STR="$(</home/fifilyu/.ssh/root@fifilyu.pub)" \
        --name some-centos6-php52 fifilyu/docker-centos6-php52:latest

效果同上。另外，可以通过SSH无密码登录容器。

`$(</home/fifilyu/.ssh/root@fifilyu.pub)` 表示在命令行读取文件内容到变量。

`PUBLIC_STR="$(</home/fifilyu/.ssh/root@fifilyu.pub)"` 也可以写作：

    PUBLIC_STR="ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQDLGJVJI1Cqr59VH1NVQgPs08n7e/HRc2Q8AUpOWGoJpVzIgjO+ipjqwnxh3eiBd806eXIIa5OFwRm0fYfMFxBOdo3l5qGtBe82PwTotdtpcacP5Dkrn+HZ1kG+cf0BNSF5oXbTCTrqY12/T8h4035BXyRw7+MuVPiCUhydYs3RgsODA47ZR3owgjvPsayUd5MrD8gidGqv1zdyW9nQXnXB7m9Sn9Mg8rk6qBxQUbtMN9ez0BFrUGhXCkW562zhJjP5j4RLVfvL2N1bWT9EoFTCjk55pv58j+PTNEGUmu8PrU8mtgf6zQO871whTD8/H6brzaMwuB5Rd5OYkVir0BXj fifilyu@archlinux"

### 3.3 启动容器时暴露端口

    docker run -d \
        --env LANG=en_US.UTF-8 \
	    --env TZ=Asia/Shanghai \
        -e MYSQL_ROOT_PASSWORD=wdtech \
        -p 8080:80 \
        --name some-centos6-php52 fifilyu/docker-centos6-php52:latest

此时访问 http://localhost:8080 能看到 PHP 版本信息。

更复杂的容器端口映射：

    docker run -d \
        --env LANG=en_US.UTF-8 \
	    --env TZ=Asia/Shanghai \
        -e MYSQL_ROOT_PASSWORD=wdtech \
        -p 8022:22 \
        -p 8080:80 \
        -p 8330:3306 \
        -p 8637:6379 \
        --name some-centos6-php52 fifilyu/docker-centos6-php52:latest

## 4. 环境配置

### 4.1 配置文件

#### 4.1.1 PHP

PHP安装目录:

    /usr/local/php-5.2.17/

PHP主配置文件:

    /usr/local/php-5.2.17/etc/php.ini

PHP模块配置文件:

    /usr/local/php-5.2.17/etc/php.d

[NOTE]
如果要启用或禁用模块，请直接修改 `php.d` 下的 `.ini` 文件。

PHP-FPM配置文件:

    /usr/local/php-5.2.17/etc/php-fpm.conf

#### 4.1.2 Nginx

Nginx主配置文件:

    /etc/nginx/nginx.conf

Nginx Host配置文件:

    /etc/nginx/conf.d

`/etc/nginx/conf.d/default.conf` 是默认创建的 Host ，监听 `80` 端口。

Web目录:

    /data/web

`/data/web/default` 目录是默认站点的文件目录。

#### 4.1.3 MySQL

MySQL主配置文件:

    /etc/my.cnf

#### 4.1.4 Redis

Redis主配置文件:

    /usr/local/redis/etc/redis.conf

### 4.2 运行目录

#### 4.2.1 PHP

日志目录:

    /usr/local/php-5.2.17/var/log

Session目录:

    /usr/local/php-5.2.17/var/lib/session

#### 4.2.2 Nginx

日志目录:

    /var/log/nginx

#### 4.2.3 MySQL

日志目录:

    /var/log/mysql

数据目录:

    /var/lib/mysql

#### 4.2.4 Redis

日志目录:

    /usr/local/redis/var/log

### 4.3 模块

#### 4.3.1 默认启用

* bcmath
* curl
* exif
* gd
* mbstring
* mcrypt
* mhash
* mysqli
* mysql
* pdo_mysql
* xmlrpc
* xml
* Zend Optimizer

#### 4.3.2 默认禁用
* calendar
* ftp
* gettext
* iconv
* openssl
* snmp
* sockets
* zip

除 `snmp` 模块外，其它模块可以随意启用，已经不再需要安装依赖。

启用 `snmp` 模块，需要安装依赖 `yum install -y net-snmp-libs`。
