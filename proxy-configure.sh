#!/bin/bash
#Script de configuração do Zabbix Proxy e Zabbix Agent
#Versão 1.0 - 06 Out 2016
#Autor: João Lemes - sendtojoao@gmail.com
#https://github.com/joaolemes/zabbix-raspberrypi/
#Sistema operacional testado 2016-09-23-raspbian-jessie-lite.img
#Versão do Zabbix utilizada 3.0.5
#Este Script insere configuração básica nos arquivos zabbix-proxy.conf e zabbix-agentd.conf
#Pasta de instalação -> /etc/zabbix
#Localização dos arquivos de configuração -> /etc/zabbix/etc/
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
