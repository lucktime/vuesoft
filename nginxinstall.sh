#!/bin/sh
############################################################################################
# 说明：nginx一键部署
# 作者：shuwoom
# Email：shuwoom.wgc@gmail.com
#############################################################################################



############################################################################################
# Nginx参数配置
#############################################################################################
# NGINX安装包下载地址
F_NGINX_PKG="http://nginx.org/download/nginx-1.15.9.tar.gz"
# nginx安装路径
D_NGINX_SERVICE="/user/share/nginx"
# nginx日志保存路径
D_NGINX_LOG="/var/log/nginx"
# nginx web路径
D_NGINX_WEB_ROOT="/user/share/nginx/html"
# nginx进程用户属性
V_NGINX_USER="nginx"
# nginx监听端口
V_NGINX_PORT=80


[ -d ${D_NGINX_SERVICE} ] || mkdir -p ${D_NGINX_SERVICE}
[ -d ${D_NGINX_LOG} ] || mkdir -p ${D_NGINX_LOG}



############################################################################################
# Nginx安装 
# 版本：1.15.9
#############################################################################################
function install_nginx()
{
	local v_start_ts=$(date +%s)
	local v_nginx_flag=$(nginx -v 2>&1 | awk 'NR==1{print substr($0,0,5)}')
	if [[ "${v_nginx_flag}" == "nginx" ]]; then
		echo "[INFO] nginx installed, ignore!"
		return
	else
		echo "[INFO] Nginx not installed, begin to install Nginx!"
	fi

	echo "[INFO]============Start Nginx Installation=================="
	if [[ ! -d "${D_TMP}" ]]; then
		echo "[INFO] Create tmp dir"
		mkdir -p ${D_TMP}
	fi

	wget ${F_NGINX_PKG}

	tar -xf nginx-1.15.9.tar.gz

	local d_nginx_pkg="${D_TMP}/nginx-1.15.9"

	cd ${d_nginx_pkg}

	# 安装编译环境
	yum -y install gcc pcre pcre-devel zlib zlib-devel openssl openssl-devel

	# 添加用户和组
	local v_nginx_group=$(cat /etc/group|grep ${V_NGINX_USER})
	if [[ -z "${v_nginx_group}" ]]; then
		echo "[INFO] ${V_NGINX_USER}:${V_NGINX_USER} not exist, create it!"
		groupadd ${V_NGINX_USER}
		useradd -g ${V_NGINX_USER} ${V_NGINX_USER}
	fi

	# 配置
	./configure \
	--user=${V_NGINX_USER} \
	--group=${V_NGINX_USER} \
	--prefix=${D_NGINX_SERVICE} \
	--with-http_ssl_module \
	--with-http_stub_status_module \
	--with-http_realip_module \
	--with-threads

	# 编译安装
	make && make install

	local v_nginx_flag=$(${D_NGINX_SERVICE}/sbin/nginx -v 2>&1 | awk 'NR==1{print substr($0,0,5)}')
	if [[ "${v_nginx_flag}" == "nginx" ]]; then
		echo "[INFO] Nginx installed successfully!"
	else
		echo "[ERROR] Nginx installed failed!"
		exit 0
	fi

	if [[ ! -e "/usr/bin/nginx" ]]; then
		ln -s ${D_NGINX_SERVICE}/sbin/nginx /usr/bin/nginx
	fi

	if [[ -e " ${D_NGINX_SERVICE}/conf/nginx.conf" ]]; then
		mv  ${D_NGINX_SERVICE}/conf/nginx.conf ${D_NGINX_SERVICE}/conf/nginx.conf.bak
	fi
	cp nginx.conf  ${D_NGINX_SERVICE}/conf/nginx.conf
	sed -i "s#user  nginx;#user  ${V_NGINX_USER};#"
	sed -i "s#error_log  logs\/error.log  error;#error_log  ${D_NGINX_LOG}\/error.log  error;#" ${D_NGINX_SERVICE}/conf/nginx.conf
	sed -i "s#root         \/user\/share\/nginx\/html;#root         ${D_NGINX_WEB_ROOT};#" ${D_NGINX_SERVICE}/conf/nginx.conf
	sed -i "s#listen       80;#listen       ${V_NGINX_PORT};#" ${D_NGINX_SERVICE}/conf/nginx.conf
	
	# 添加开机启动
	cp nginx /etc/init.d/nginx
	sed -i "s#nginx=\"\/usr\/local\/nginx\/sbin\/nginx\"#nginx=\"${D_NGINX_SERVICE}\/sbin/nginx\"#" /etc/init.d/nginx
	sed -i "s#NGINX_CONF_FILE=\"\/usr\/local\/nginx\/conf\/nginx.conf\"#NGINX_CONF_FILE=\"${D_NGINX_SERVICE}\/conf\/nginx.conf\"#"  /etc/init.d/nginx
	
	chmod +x /etc/init.d/nginx
	chkconfig --add /etc/init.d/nginx
	chkconfig nginx on
	service nginx start

	# 创建web访问目录
	if [[ ! -d "${D_NGINX_WEB_ROOT}" ]]; then
		mkdir -p ${D_NGINX_WEB_ROOT}
	fi

	chown -R ${V_NGINX_USER}:${V_NGINX_USER} ${D_NGINX_WEB_ROOT}

	# 检测是否启动成功
	local v_nginx_cnt=$(ps -ef|grep nginx|grep -v grep|wc -l)
	if [[ ${v_nginx_cnt} -gt 0 ]]; then
		echo "[INFO] Nginx start successfully!"
	else
		echo "[ERROR] Nginx start failed!"
		exit 0
	fi

	local v_end_ts=$(date +%s)
	local v_cost_ts=`expr ${v_end_ts} - ${v_start_ts}`
	echo "[INFO] Nginx Total cost: ${v_cost_ts}"
	echo "[INFO]============End of Nginx Installation=================="
}

install_nginx
