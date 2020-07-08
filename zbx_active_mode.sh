#!/bin/bash
# Date: 2019.08.28

UBUNTU_CHRONY_CONFIG="/etc/chrony/chrony.conf"
CENTOS_CHRONY_CONFIG="/etc/chrony.conf"
ZBX_CONFIG="/etc/zabbix/zabbix_agentd.conf"
ZBX_SERVER="X.Y.Z.W:20051"
AGENT_NAME=`ip addr | grep inet | egrep -v '(127.0.0.1|inet6|docker)' | awk '{print $2}' | tr -d "addr:" | head -n 1 | cut -d / -f1`
TIMEOUT=30
START_AGENT=0


DISTROS=$(awk -F "\"| " 'NR==1 {print $2}' /etc/os-release)
DISTROS_VERSION=$(awk -F "\"| " 'NR==2 {print $2}' /etc/os-release)


IP_LIST=$(ip addr | grep inet | egrep -v '(127.0.0.1|inet6|docker)' | awk '{print $2}' | tr -d "addr:" | cut -d / -f1)
IP_COUNT=$(ip addr | grep inet | egrep -v '(127.0.0.1|inet6|docker)' | awk '{print $2}' | tr -d "addr:" | cut -d / -f1 | wc -l)
let COUNT=1
if [ ${IP_COUNT} -gt 1 ]; then
    for i in ${IP_LIST}; do
        printf "$COUNT: $i\n"
        let COUNT+=1
    done
    read -p "Please choose a number: " NUMBER
    AGENT_NAME=`ip addr | grep inet | egrep -v '(127.0.0.1|inet6|docker)' | awk '{print $2}' | tr -d "addr:" | cut -d / -f1 | awk "NR==$NUMBER {print $1}"`
else
    AGENT_NAME=`ip addr | grep inet | egrep -v '(127.0.0.1|inet6|docker)' | awk '{print $2}' | tr -d "addr:" | head -n 1 | cut -d / -f1`
fi

command_exists() {
        command -v "$@" > /dev/null 2>&1
}

yum_install_pkgs() {
    local PKG_NAME=$1
    local BIN_NAME=$2

    if ! command_exists ${BIN_NAME} &> /dev/null; then
        yum -y install ${PKG_NAME}
        if ! command_exists ${BIN_NAME} &> /dev/null; then
            echo "${PKG_NAME} service install failed, please install it manually."
            exit 1
        fi
    else
        echo "${PKG_NAME} service already exist."
    fi
}

apt_install_pkgs() {
    local PKG_NAME=$1
    local BIN_NAME=$2

    if ! command_exists ${BIN_NAME} &> /dev/null; then
        apt-get -y install ${PKG_NAME} &> /dev/null
        if ! command_exists ${BIN_NAME} &> /dev/null; then
            echo "${PKG_NAME} service install failed, please install it manually."
            exit 1
        fi
    else
        echo "${PKG_NAME} service already exist."
    fi
}

update_ubuntu_chrony_config() {
    sed -i 's/^\(pool .*\)/#\1/g' ${UBUNTU_CHRONY_CONFIG}
    echo "pool ntp1.aliyun.com online iburst" >> ${UBUNTU_CHRONY_CONFIG}
    echo "pool ntp2.aliyun.com online iburst" >> ${UBUNTU_CHRONY_CONFIG}
    echo "pool ntp3.aliyun.com online iburst" >> ${UBUNTU_CHRONY_CONFIG}
}

update_centos_chrony_config() {
    sed -i 's/^\(server .*\)/#\1/g' ${CENTOS_CHRONY_CONFIG}
    echo "server ntp1.aliyun.com iburst" >> ${CENTOS_CHRONY_CONFIG}
    echo "server ntp2.aliyun.com iburst" >> ${CENTOS_CHRONY_CONFIG}
    echo "server ntp3.aliyun.com iburst" >> ${CENTOS_CHRONY_CONFIG}

}

modify_zbx_config() {
    sed -i 's/^\(Server=.*\)/#\1/g' ${ZBX_CONFIG}

    sed -i "s/^\(ServerActive=\).*/\1${ZBX_SERVER}/g" ${ZBX_CONFIG}
    sed -i "s/^\(Hostname=\).*/\1${AGENT_NAME}/g" ${ZBX_CONFIG}
    sed -i 's/^# \(HostMetadataItem=\).*/\1system.uname/g' ${ZBX_CONFIG}
    sed -i "s/^# \(Timeout=\).*/\1${TIMEOUT}/g" ${ZBX_CONFIG}

    if ! egrep "^StartAgents" ${ZBX_CONFIG} &> /dev/null; then
        echo "StartAgents=0" >> ${ZBX_CONFIG}
    else
        sed -i "s/^\(StartAgents=\).*/\1${START_AGENT}/g" ${ZBX_CONFIG}
    fi
}

start_service() {
    local SRV_NMAE=$1

    systemctl restart ${SRV_NMAE} &> /dev/null
    systemctl enable ${SRV_NMAE} &> /dev/null

    if systemctl status ${SRV_NMAE} &> /dev/null; then
        echo "${SRV_NMAE} started successfully."
    else
        echo "${SRV_NMAE} start failed."
    fi
}

#start_zbx_agent() {
#    systemctl restart zabbix-agent &> /dev/null
#    systemctl enable zabbix-agent &> /dev/null
#
#    if systemctl status zabbix-agent &> /dev/null; then
#        echo "zabbix agent started successfully."
#    else
#        echo "zabbix agent start failed."
#    fi
#}

add_centos_zbx_repo() {
    rpm -Uvh https://repo.zabbix.com/zabbix/4.0/rhel/7/x86_64/zabbix-release-4.0-2.el7.noarch.rpm
    yum makecache fast
}

add_ubuntu16_zbx_repo() {
    wget -q -t 0 -c https://repo.zabbix.com/zabbix/4.0/ubuntu/pool/main/z/zabbix-release/zabbix-release_4.0-3+xenial_all.deb && dpkg -i zabbix-release_4.0-3+xenial_all.deb && apt update
}

add_ubuntu18_zbx_repo() {
    wget -q -t 0 -c https://repo.zabbix.com/zabbix/4.0/ubuntu/pool/main/z/zabbix-release/zabbix-release_4.0-3+bionic_all.deb && dpkg -i zabbix-release_4.0-3+bionic_all.deb && apt update
}

install_centos_zbx_agent () {
    yum -y install wget
    add_centos_zbx_repo
    yum_install_pkgs zabbix-agent zabbix_agentd
    modify_zbx_config
    #start_zbx_agent
    start_service zabbix-agent
}

install_ubuntu16_zbx_agent() {
    apt -y install wget
    add_ubuntu16_zbx_repo
    apt_install_pkgs zabbix-agent zabbix_agentd
    modify_zbx_config
    #start_zbx_agent
    start_service zabbix-agent
}

install_ubuntu18_zbx_agent() {
    apt -y install wget
    add_ubuntu18_zbx_repo
    apt_install_pkgs zabbix-agent zabbix_agentd
    modify_zbx_config
    #start_zbx_agent
    start_service zabbix-agent
}


# ########## main ##########
if [ ${DISTROS} == "CentOS" -a ${DISTROS_VERSION} == "7" ]; then
    install_centos_zbx_agent
    yum_install_pkgs chrony chronyd
    update_centos_chrony_config
    start_service chronyd
elif [[ ${DISTROS} == "Ubuntu" ]] && [[ ${DISTROS_VERSION} =~ 16* ]]; then
    install_ubuntu16_zbx_agent
    apt_install_pkgs chrony chronyd
    update_ubuntu16_chrony_config
    start_service chrony
elif [[ ${DISTROS} == "Ubuntu" ]] && [[ ${DISTROS_VERSION} =~ 18* ]]; then
    install_ubuntu18_zbx_agent
    apt_install_pkgs chrony chronyd
    update_ubuntu18_chrony_config
    start_service chrony
else
    echo "Unknown distros"
    exit 1
fi
