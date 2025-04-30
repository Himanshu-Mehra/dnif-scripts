if [ -r /etc/os-release ]; then
        os="$(. /etc/os-release && echo "$ID")"
fi

if [[ "$os" == "rhel" ]]; then
    service="podman"
else
    service="docker"
fi

if [[ -e /DNIF/CO/ ]]; then
    cd /DNIF/DL
    $service-compose down
    cd /DNIF/
    $service-compose down
    rm -rf /DNIF/*
fi

if [[ -e /DNIF/DL/ ]]; then
    cd /DNIF/DL
    $service-compose down
    rm -rf /DNIF/*
fi

if [[ -e /DNIF/LC/ ]]; then
    cd /DNIF/LC
    $service-compose down
    rm -rf /DNIF/*
fi

if [[ -e /DNIF/AD/ ]]; then
    cd /DNIF/AD
    $service-compose down
    rm -rf /DNIF/*
fi

if [[ -e /DNIF/PICO/ ]]; then
    cd /DNIF/PICO
    $service-compose down
    rm -rf /DNIF/*
fi

rm -rf /opt/hadoop*

rm -rf /opt/spark*

rm -rf /opt/gohdfs

rm -rf /opt/containerd

if [[ -e /etc/systemd/system/hadoop-namenode.service ]]; then
    cd /etc/systemd/system/
    systemctl stop hadoop-namenode.service
    rm -rf hadoop-namenode.service
fi

if [[ -e /etc/systemd/system/hadoop-datanode.service ]]; then
    cd /etc/systemd/system/
    systemctl stop hadoop-datanode.service
    rm -rf hadoop-datanode.service
fi

if [[ -e /etc/systemd/system/spark-master.service ]]; then
    cd /etc/systemd/system/
    systemctl stop spark-master.service
    rm -rf spark-master.service
fi

if [[ -e /etc/systemd/system/spark-slave.service ]]; then
    cd /etc/systemd/system/
    systemctl stop spark-slave.service
    rm -rf spark-slave.service
fi

systemctl daemon-reload
systemctl reset-failed


echo "-----------------------------------------------------------------------------------------"
echo -e "$service ps -a"
$service ps -a
echo "-----------------------------------------------------------------------------------------"
echo "ls /DNIF/"
ls /DNIF/
echo "-----------------------------------------------------------------------------------------"
echo "ls /opt/"
ls /opt/
echo "-----------------------------------------------------------------------------------------"
echo "ls /etc/systemd/system/"
ls /etc/systemd/system/
echo "-----------------------------------------------------------------------------------------"
echo "Cleaning Completed"