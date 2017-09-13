#!/bin/sh

eval `dbus export frps_`
source /koolshare/scripts/base.sh
NAME=frps
BIN=/koolshare/bin/${NAME}
INI_FILE=/koolshare/configs/${NAME}.ini
PID_FILE=/var/run/${NAME}.pid
en=${frps_enable}

onstart() {
killall ${NAME} || true >/dev/null 2>&1
dbus set ${NAME}_client_version=`${BIN} --version`

cat > ${INI_FILE}<<-EOF
# [common] is integral section
[common]
# A literal address or host name for IPv6 must be enclosed
# in square brackets, as in "[::1]:80", "[ipv6-host]:http" or "[ipv6-host%zone]:80"
bind_addr = 0.0.0.0
bind_port = ${frps_common_bind_port}
# udp port used for kcp protocol, it can be same with 'bind_port'
# if not set, kcp is disabled in frps
kcp_bind_port = ${frps_common_bind_port}
# if you want to configure or reload frps by dashboard, dashboard_port must be set
dashboard_port = ${frps_common_dashboard_port}
# dashboard user and pwd for basic auth protect, if not set, both default value is admin
dashboard_user = ${frps_common_dashboard_user}
dashboard_pwd = ${frps_common_dashboard_pwd}

vhost_http_port = ${frps_common_vhost_http_port}
vhost_https_port = ${frps_common_vhost_https_port}
# console or real logFile path like ./frps.log
log_file = ${frps_common_log_file}
# debug, info, warn, error
log_level = ${frps_common_log_level}
log_max_days = ${frps_common_log_max_days}
# if you enable privilege mode, frpc can create a proxy without pre-configure in frps when privilege_token is correct
privilege_mode = true
privilege_token = ${frps_common_privilege_token}
# only allow frpc to bind ports you list, if you set nothing, there won't be any limit
#privilege_allow_ports = 1-65535
# pool_count in each proxy will change to max_pool_count if they exceed the maximum value
max_pool_count = ${frps_common_max_pool_count}
tcp_mux = ${frps_common_tcp_mux}

EOF

echo -n "setting ${NAME} crontab..."
if [ "${frps_common_cron_time}" == "0" ]; then
	cru d frps_monitor
else
	if [ "${frps_common_cron_hour_min}" == "min" ]; then
		cru a frps_monitor "*/"${frps_common_cron_time}" * * * * /bin/sh /koolshare/scripts/config-frps.sh"
	elif [ "${frps_common_cron_hour_min}" == "hour" ]; then
		cru a frps_monitor "0 */"${frps_common_cron_time}" * * * /bin/sh /koolshare/scripts/config-frps.sh"
	fi
fi
echo " done"
if [ "$en" == "1" ]; then
echo -n "starting ${NAME}..."
export GOGC=40
start-stop-daemon -S -q -b -m -p ${PID_FILE} -x ${BIN} -- -c ${INI_FILE}
echo " done"
else
	stop
fi
}
stop() {
	echo -n "stop ${NAME}..."
	killall frps || true
	cru d frps_monitor
	echo " done"
}

case $ACTION in
start)
    if [[ "$en" == "1" ]]; then
        logger "[软件中心]: 启动frps！"
        onstart
    else
        logger "[软件中心]: frps未设置开机启动，跳过！"
    fi
    ;;
stop)
	stop
	;;
*)
	onstart
	;;
esac  
