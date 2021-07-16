#!/bin/bash
#描述:Nginx安装脚本
#Nginx版本：1.9.5
echo    -e "\033[31m 搭建yum源 \033[0m"
echo    -e "1.网络yum源"
echo    -e "2.本地yum源"
    read -p "请输入你的操作(1-2):" yum

case $yum in
1)
yum install -y wget &> /dev/null
rm -rf /etc/yum.repos.d/*
wget -P /etc/yum.repos.d/ http://mirrors.aliyun.com/repo/Centos-7.repo &>/dev/null
if [ $? -eq 0 ];then
    echo    "yum源文件下载成功！！"
else
    echo    "yum源文件下载失败，请检查网络配置！！"
    exit 1
fi
yum clean all &>/dev/null
yum makecache &>/dev/null
echo    "阿里yum源搭建完成！！！"
;;
2)
rm -rf /etc/yum.repos.d/*
cat >> /etc/yum.repos.d/yum.repo << eof
[yum]
name=yum
baseurl=file:///mnt
gpgcheck=0
enabled=1
eof
yum clean all &>/dev/null
yum makecache &>/dev/null
echo    "本地yum源搭建完成！！"
mount /dev/cdrom /mnt/
cd /mnt/Packages/
if [ $? -eq 0 ]; then
    echo    "已将镜像挂载到系统！！"
    cd /root/
else
    echo    "镜像挂载失败，请查看是否将镜像导入系统！！"
    exit 2
fi
;;
*)
    echo    "请输入1或者2操作，输入错误，正在退出..."
    exit    3
esac


echo    -e "\033[34m 安装Nginx \033[0m"
sleep 3
echo    "安装Nginx依赖包"
nginx_gz=nginx-1.9.5.tar.gz
nginx=nginx-1.9.5
cd /root
yum install -y gcc gcc-c++ autoconf automake zlib zlib-devel openssl openssl-devel  pcre pcre-devel make automake   &>/dev/null
echo    "创建Nginx运行用户"
groupadd www
useradd -g www www -s /sbin/nologin
tar xf $nginx_gz
cd $nginx
./configure --prefix=/usr/local/nginx --with-http_dav_module --with-http_stub_status_module --with-http_addition_module --with-http_sub_module --with-http_flv_module --with-http_mp4_module --with-pcre --with-http_ssl_module --with-http_gzip_static_module --user=www --group=www &>/dev/null
if [ $? -eq 0 ];then
    echo    "Nginx预编译完成，开始安装"
else
    echo    "Nginx预编译失败，请检查相关依赖包是否安装"
    exit 4
fi
make &>/dev/null
make install &>/dev/null
if [ $? -eq 0 ];then
    echo    "Nginx安装成功"
else
    echo    "Nginx安装失败"
    exit 5
fi
ln -s /usr/local/nginx/sbin/nginx /usr/local/bin
/usr/local/nginx/sbin/nginx
netstat -anput | grep nginx &>/dev/null
if [ $? -eq 0 ];then
    echo    "Nginx启动成功"
else
    echo    "Nginx启动失败"
    exit 6
fi
