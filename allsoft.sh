yum install -y wget && wget -O install.sh http://download.bt.cn/install/install_6.0.sh && wget -O nginxinstall.sh https://github.com/lucktime/vuesoft/blob/master/nginxinstall.sh && wget -O npminstall.sh https://github.com/lucktime/vuesoft/blob/master/npminstall.sh && sh install.sh && sh nginxinstall.sh && sh npminstall.sh && npm install pm2 -g