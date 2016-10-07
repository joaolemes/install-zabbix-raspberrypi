#!/bin/bash
#Script de instalação do Zabbix Proxy e Zabbix Agent
#Versão 1.0 - 06 Out 2016
#Autor: João Lemes - sendtojoao@gmail.com
#Testado em 2016-09-23-raspbian-jessie-lite.img
#Este Script instala Zabbix Proxy e Agent, com SQLite3, IPv6, SNMP, SSH2 e OPENSSL, porém não coloca o Agent para iniciar automaticamente
#Pasta de instalação -> /etc/zabbix
#Localização dos arquivos de configuração -> /etc/zabbix/etc/

echo '@@@ TODO O PROCESSO PODERÁ DEMORAR QUASE UMA HORA, DEPENDENTO DO CARTAO SD DO RASPBERRY E DA INTERNET, APROVEITE E TOME UM CAFÉ @@@'
read -p "APERTE ENTER PARA CONTINUAR"

wget http://sourceforge.net/projects/zabbix/files/ZABBIX%20Latest%20Stable/3.0.5/zabbix-3.0.5.tar.gz

#Atualizando Raspbian
apt-get update -y && apt-get upgrade -y

echo '@@@ Instalando dependências (make, automake, gcc, sqlite3, libsqlite3-dev, snmp, libsnmp-dev, libssh2-1-dev, fping, openssl) @@@'

#install all prerequsites
apt-get install make automake -y	#instalar pacote make
apt-get install gcc -y	#instalar complicador gcc
apt-get install sqlite3 -y	#instalar BD engine sqlite3
apt-get install libsqlite3-dev -y	#instalar biblioteca SQLite3 -> error: SQLite3 library not found
apt-get install snmp -y	#instalar SNMP -> erro após instalação ‘Cannot adopt OID in UCD-SNMP-MIB’
apt-get install libsnmp-dev -y	#instalar biblioteca SNMP -> error: Invalid Net-SNMP directory - unable to find net-snmp-config
apt-get install libssh2-1-dev -y	#instalar biblioteca SSH2 -> error: SSH2 library not found
apt-get install fping -y	#instalar FPING -> diretório /usr/sbin/fping: [2] No such file or directory
apt-get install openssl -y	#segurança e criptografia

echo '@@@ Criando usuário e grupo zabbix @@@'

#Configurando usuário e grupo zabbix
groupadd zabbix
useradd -g zabbix zabbix

echo '@@@ Extraindo Zabbix @@@'

#Extraindo zabbix
tar -vzxf zabbix-*.tar.gz -C ~

echo '@@@ Criando diretório de log e database SQLite3 @@@'

#Criando database SQLite3
mkdir -p /var/lib/sqlite
cd ~/zabbix-*/database/sqlite3
sqlite3 /var/lib/sqlite/zabbix.db < schema.sql

#Criando pastas de log
mkdir -p /var/log/zabbix/proxy
mkdir -p /var/log/zabbix/agent

echo '@@@ Configurando Zabbix e instalando @@@'

cd ~/zabbix-*/
./configure --prefix=/etc/zabbix --enable-proxy --enable-agent --with-net-snmp --with-sqlite3 --with-ssh2 --enable-ipv6 --with-openssl
automake
make install
echo
#Configurando zabbix proxy
echo
echo '@@@ Configurando inicialização automática @@@'
echo
#Configurando arquivo de inicialização automática

#Início do arquivo de inicialização ZABBIX_PROXY
cat > /etc/init.d/zabbix_proxy << EOF
#!/bin/sh
# Zabbix daemon start/stop script.
# Copyright (C) 2001-2016 Zabbix SIA

### BEGIN INIT INFO
# Provides:          zabbix_proxy
# Required-Start:    $local_fs $remote_fs $network $syslog $named
# Required-Stop:     $local_fs $remote_fs $network $syslog $named
# Default-Start:     2 3 4 5
# Default-Stop:      0 1 6
# X-Interactive:     true
# Short-Description: Zabbix Proxy
# Description:       Start the Zabbix Proxy
### END INIT INFO

NAME=zabbix_proxy
DAEMON=/etc/zabbix/sbin/\${NAME}
DESC="Zabbix proxy daemon"
PID=/var/log/zabbix/\$NAME.pid

test -f \$DAEMON || exit 0

case "\$1" in
  start)
	echo "Starting \$DESC: \$NAME"
	start-stop-daemon --start --oknodo --pidfile \$PID --exec \$DAEMON
	;;
  stop)
	echo "Stopping \$DESC: \$NAME"
	start-stop-daemon --stop --quiet --pidfile \$PID --retry=TERM/10/KILL/5 && exit 0
	start-stop-daemon --stop --oknodo --exec \$DAEMON --name \$NAME --retry=TERM/10/KILL/5
	;;
  restart|force-reload)
	\$0 stop
	\$0 start
	;;
  *)
	N=/etc/init.d/\$NAME
	echo "Usage: \$N {start|stop|restart|force-reload}" >&2
	exit 1
	;;
esac

exit 0
EOF
#Fim do arquivo de inicialização ZABBIX_PROXY

#Início do arquivo de inicialização ZABBIX_AGENT
cat > /etc/init.d/zabbix_agent << EOF
#!/bin/sh
# Zabbix daemon start/stop script.
# Copyright (C) 2001-2016 Zabbix SIA

### BEGIN INIT INFO
# Provides:          zabbix_agentd
# Required-Start:    $local_fs $remote_fs $network $syslog $named
# Required-Stop:     $local_fs $remote_fs $network $syslog $named
# Default-Start:     2 3 4 5
# Default-Stop:      0 1 6
# X-Interactive:     true
# Short-Description: Zabbix Agent
# Description:       Start the Zabbix Agent
### END INIT INFO

NAME=zabbix_agentd
DAEMON=/etc/zabbix/sbin/\${NAME}
DESC="Zabbix agent daemon"
PID=/var/log/zabbix/\$NAME.pid

test -f \$DAEMON || exit 0

case "\$1" in
  start)
	echo "Starting \$DESC: \$NAME"
	start-stop-daemon --start --oknodo --pidfile \$PID --exec \$DAEMON
	;;
  stop)
	echo "Stopping \$DESC: \$NAME"
	start-stop-daemon --stop --quiet --pidfile \$PID --retry=TERM/10/KILL/5 && exit 0
	start-stop-daemon --stop --oknodo --exec \$DAEMON --name \$NAME --retry=TERM/10/KILL/5
	;;
  restart|force-reload)
	\$0 stop
	\$0 start
	;;
  *)
	N=/etc/init.d/\$NAME
	echo "Usage: \$N {start|stop|restart|force-reload}" >&2
	exit 1
	;;
esac

exit 0
EOF
#Fim do arquivo de inicialização ZABBIX_AGENT

#Permissão de execução para arquivo de inicialização
chmod 755 /etc/init.d/zabbix_proxy
chmod 755 /etc/init.d/zabbix_agent

#Configurando a aplicação para iniciar automaticamente
update-rc.d zabbix_proxy defaults #zabbix_proxy auto startup
echo
echo '@@@ Configurando arquivos .conf @@@'
#Arquivos de configuração
echo
echo 'Arquivo de configuração default - zabbix_proxy.conf: '
grep -v "^#\|^$" /etc/zabbix/etc/zabbix_proxy.conf
echo

sed -i "s/^DBName=.*$/DBName=\/var\/lib\/sqlite\/zabbix.db/" /etc/zabbix/etc/zabbix_proxy.conf	#set location to database
sed -i "s/^LogFile=.*$/LogFile=\/var\/log\/zabbix\/proxy\/zabbix_proxy.log/" /etc/zabbix/etc/zabbix_proxy.conf	#local de gravação do log
sed -i "s/^# LogFileSize=.*$/LogFileSize=1/" /etc/zabbix/etc/zabbix_proxy.conf	#tamanho do log em 1MB
sed -i "s/^# PidFile=.*$/PidFile=\/var\/log\/zabbix\/zabbix_proxy.pid/" /etc/zabbix/etc/zabbix_proxy.conf	#PID file junto ao log
sed -i "s/^# ProxyOfflineBuffer=.*$/ProxyOfflineBuffer=168/" /etc/zabbix/etc/zabbix_proxy.conf	#buffer offline de 7 dias
sed -i "s/^# FpingLocation=.*$/FpingLocation=\/usr\/bin\/fping/" /etc/zabbix/etc/zabbix_proxy.conf	#local de fping
sed -i "s/^# Fping6Location=.*$/Fping6Location=\/usr\/bin\/fping6/" /etc/zabbix/etc/zabbix_proxy.conf	#local de fping6

echo
echo 'Arquivo pós-configuração: '
grep -v "^#\|^$" /etc/zabbix/etc/zabbix_proxy.conf
echo

#Configurando zabbix agent

echo
echo 'Arquivo de configuração default - zabbix_agentd.conf: '
grep -v "^#\|^$" /etc/zabbix/etc/zabbix_agentd.conf
echo

sed -i "s/^LogFile=.*$/LogFile=\/var\/log\/zabbix\/agent\/zabbix_agent.log/" /etc/zabbix/etc/zabbix_agentd.conf #localizacao arquivo log
sed -i "s/^# LogFileSize=.*$/LogFileSize=1/" /etc/zabbix/etc/zabbix_proxy.conf	#tamanho do log em 1MB #tamanho de arquivo de log
sed -i "s/^# PidFile=.*$/PidFile=\/var\/log\/zabbix\/zabbix_proxy.pid/" /etc/zabbix/etc/zabbix_proxy.conf	#PID file junto ao log

echo
echo 'Arquivo pós-configuração: '
grep -v "^#\|^$" /etc/zabbix/etc/zabbix_agentd.conf
echo

echo '@@@ Configurando permissões @@@'

#Configurando permissões para database e pastas de log
chown -R zabbix:zabbix /var/lib/sqlite/
chown -R zabbix:zabbix /var/log/zabbix
chmod 774 -R /var/lib/sqlite
chmod 664 /var/lib/sqlite/zabbix.db

echo '@@@ Personalizando zabbix-proxy.conf @@@'
echo 
echo 'Informe IP/hostname do ZABBIX SERVER: '
read server

#Alteração de arquivo
sed -i "s/^Server=.*$/"Server="$server""/" /etc/zabbix/etc/zabbix_proxy.conf    #write ip address of real zabbix server

echo
echo 'Informe o hostname para este Zabbix Proxy (ex. local/cliente): '
read hostname

#Alteração de arquivo
sed -i "s/^Hostname=.*$/"Hostname="$hostname""/" /etc/zabbix/etc/zabbix_proxy.conf      #write a name for this proxy server

echo
echo '@@@ Configurando zabbix-agentd.conf @@@'
echo 
echo 'Informe o endereço IP/hostname do ZABBIX PROXY (IP da interface que fará a coleta na rede local): '
read server
#Alteração de arquivo
sed -i "s/^Server=.*$/"Server="$server""/" /etc/zabbix/etc/zabbix_agentd.conf   #write ip address of zabbix proxy

echo 'Informe o hostname do servidor, deve ser o mesmo configurado no Zabbix Server'
read hostname
#Alteração de arquivo
sed -i "s/^Hostname=.*$/"Hostname="$hostname""/" /etc/zabbix/etc/zabbix_agentd.conf     #write a name for this Zabbix Server Hostname

echo
echo 'Você deseja que o ZABBIX_AGENT inicie automaticamente? (Y/N)'
read op; 
echo

case $op in
Y|y)
  update-rc.d zabbix_agent defaults #zabbix_agent auto startup
  echo 'O zabbix_agent irá iniciar automaticamente';;
N|n)
  echo 'O zabbix_agent não iniciará automaticamente';;
*)
  echo 'A opção digitada é inválida';;
esac

echo
echo '@@@ CONFIGURAÇÃO FINALIZADA! @@@'
echo
#Informações gerais
echo 
echo '@@@ Localização dos arquivos de configuração: zabbix_proxy.conf | zabbix_agentd.conf -> /etc/zabbix/etc/ @@@'
echo '@@@ Localização dos arquivos de log: zabbix_agentd.log | zabbix_proxy.log e arquivos de PID -> /var/log/zabbix @@@'
echo 
