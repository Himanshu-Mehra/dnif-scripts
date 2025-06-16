#!/bin/bash
set -e

function compose_check() {
	if [ -x "$(command -v docker-compose)" ]; then
		version=$(docker-compose --version |cut -d ' ' -f3 | cut -d ',' -f1)
		if [[ "$version" != "1.23.1" ]]; then
			echo -n "[-] Finding docker-compose installation - found incompatible version"
			echo -e "... \e[0;31m[ERROR] \e[0m\n"
			echo -e "[-] Updating docker-compose\n"
			sudo curl -L "https://github.com/docker/compose/releases/download/1.23.1/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose &>> /DNIF/install.log
			sudo chmod +x /usr/local/bin/docker-compose &>> /DNIF/install.log
			echo -e "[-] Installing docker-compose - ... \e[1;32m[DONE] \e[0m\n"
		else
			echo -e "[-] docker-compose up-to-date\n"
			echo -e "[-] Installing docker-compose - ... \e[1;32m[DONE] \e[0m\n"
		fi
	else
		echo -e "[-] Finding docker-compose installation - ... \e[1;31m[NEGATIVE] \e[0m\n"
		echo -e "[-] Installing docker-compose\n"
		sudo curl -L "https://github.com/docker/compose/releases/download/1.23.1/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose &>> /DNIF/install.log
		sudo chmod +x /usr/local/bin/docker-compose&>> /DNIF/install.log
        echo -e "[-] Installing docker-compose - ... \e[1;32m[DONE] \e[0m\n"
	fi
}

function compose_check_centos() {
	if [ -x "$(command -v docker-compose)" ]; then
		version=$(docker-compose --version |cut -d ' ' -f3 | cut -d ',' -f1)
		if [[ "$version" != "1.23.1" ]]; then
			echo -n "[-] Finding docker-compose installation - found incompatible version"
			echo -e "... \e[0;31m[ERROR] \e[0m\n"
			echo -e "[-] Updating docker-compose\n"
			sudo curl -k -L "https://github.com/docker/compose/releases/download/1.23.1/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose &>> /DNIF/install.log
			sudo chmod +x /usr/local/bin/docker-compose &>> /DNIF/install.log
			echo -e "[-] Installing docker-compose - ... \e[1;32m[DONE] \e[0m\n"
		else
			echo -e "[-] docker-compose up-to-date\n"
			echo -e "[-] Installing docker-compose - ... \e[1;32m[DONE] \e[0m\n"
		fi
	else
		echo -e "[-] Finding docker-compose installation - ... \e[1;31m[NEGATIVE] \e[0m\n"
		echo -e "[-] Installing docker-compose\n"
		sudo curl -k -L "https://github.com/docker/compose/releases/download/1.23.1/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose &>> /DNIF/install.log
		sudo chmod +x /usr/local/bin/docker-compose &>> /DNIF/install.log
		filedc="/usr/bin/docker-compose"
		if [ ! -f "$filedc " ]; then
			sudo ln -s /usr/local/bin/docker-compose /usr/bin/docker-compose &>> /DNIF/install.log
		fi
    echo -e "[-] Installing docker-compose - ... \e[1;32m[DONE] \e[0m\n"
	fi

}

function docker_check() {
	echo -e "[-] Finding docker installation\n"
	if [ -x "$(command -v docker)" ]; then
		currentver="$(docker --version |cut -d ' ' -f3 | cut -d ',' -f1)"
		requiredver="20.10.3"
		if [ "$(printf '%s\n' "$requiredver" "$currentver" | sort -V | head -n1)" = "$requiredver" ]; then
			echo -e "[-] docker up-to-date\n"
			echo -e "[-] Finding docker installation ... \e[1;32m[DONE] \e[0m\n"
		else
			echo -n "[-] Finding docker installation - found incompatible version"
			echo -e "... \e[0;31m[ERROR] \e[0m\n"
			echo -e "[-] Uninstalling docker\n"
			sudo apt-get remove docker docker-engine docker.io containerd runc&>> /DNIF/install.log
			docker_install
		fi
	else
		echo -e "[-] Finding docker installation - ... \e[1;31m[NEGATIVE] \e[0m\n"
		echo -e "[-] Installing docker\n"
		docker_install
		echo -e "[-] Finding docker installation - ... \e[1;32m[DONE] \e[0m\n"
	fi

}

function docker_check_centos() {
	echo -e "[-] Finding docker installation\n"
	if [ -x "$(command -v docker)" ]; then
		currentver="$(docker --version |cut -d ' ' -f3 | cut -d ',' -f1)"
		requiredver="20.10.3"
		if [ "$(printf '%s\n' "$requiredver" "$currentver" | sort -V | head -n1)" = "$requiredver" ]; then
			echo -e "[-] docker up-to-date\n"
			echo -e "[-] Finding docker installation ... \e[1;32m[DONE] \e[0m\n"
		else
			echo -n "[-] Finding docker installation - found incompatible version"
			echo -e "... \e[0;31m[ERROR] \e[0m\n"
			echo -e "[-] Uninstalling docker\n"
			sudo yum remove docker \
			docker-client \
			docker-client-latest \
			docker-common \
			docker-latest \
			docker-latest-logrotate \
			docker-logrotate \
			docker-engine&>> /DNIF/install.log
			docker_install_centos
		fi
	else
        	echo -e "[-] Finding docker installation - ... \e[1;31m[NEGATIVE] \e[0m\n"
        	echo -e "[-] Installing docker\n"
        	docker_install_centos
        	echo -e "[-] Finding docker installation - ... \e[1;32m[DONE] \e[0m\n"
	fi

}

function docker_install() {
	sudo apt-get -y update&>> /DNIF/install.log
	echo -e "[-] Setting up docker-ce repositories\n"
	sudo apt-get -y install \
    apt-transport-https \
    ca-certificates \
    curl \
    gnupg-agent \
    software-properties-common&>> /DNIF/install.log
	curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -&>> /DNIF/install.log
	sudo apt-key fingerprint 0EBFCD88&>> /DNIF/install.log
	sudo add-apt-repository \
   "deb [arch=amd64] https://download.docker.com/linux/ubuntu \
   $(lsb_release -cs) \
   stable"&>> /DNIF/install.log
	sudo apt-get -y update&>> /DNIF/install.log
	echo -e "[-] Installing docker-ce\n"
	sudo apt-get -y install docker-ce docker-ce-cli containerd.io&>> /DNIF/install.log
}

function docker_install_centos() {
	sudo yum install -y yum-utils&>> /DNIF/install.log
	echo -e "[-] Setting up docker-ce repositories\n"
	sudo yum-config-manager \
    --add-repo \
    https://download.docker.com/linux/centos/docker-ce.repo&>> /DNIF/install.log
	echo -e "[centos-extras]
	name=Centos extras - $"basearch"
	baseurl=http://mirror.centos.org/centos/7/extras/x86_64
	enabled=1
	gpgcheck=1
	gpgkey=http://centos.org/keys/RPM-GPG-KEY-CentOS-7">>/etc/yum.repos.d/docker-ce.repo

	file1="/usr/bin/slirp4netns"
	if [ ! -f "$file1 " ]; then
		yum install -y slirp4netns&>> /DNIF/install.log
	fi
	file2="/usr/bin/fuse-overlayfs"
	if [ ! -f "$file2 " ]; then
		yum install -y fuse-overlayfs&>> /DNIF/install.log
	fi
	file3="/usr/bin/container-selinux"
	if [ ! -f "$file3 " ]; then
		yum install -y container-selinux&>> /DNIF/install.log
	fi
	sudo yum install -y docker-ce docker-ce-cli containerd.io&>> /DNIF/install.log
	sudo systemctl start docker&>> /DNIF/install.log
	sudo systemctl enable docker.service&>> /DNIF/install.log
}

function docker_image () {
    if [[ "$1" == "core-v9" ]]; then
        echo -e "\n[-] Checking Docker Image for CORE & DATANODE $tag\n"
        coimage=$(echo "$(docker images | grep 'dnif/core' | grep "$tag")")
        if [ -n "$coimage" ]; then
            echo -e "[-] Docker Image core:$tag already exists."
            echo -e "$coimage"
        else
            echo -e "[-] Docker Image core:$tag does not exist. Pulling the image..."
            docker pull docker.io/dnif/core:$tag
            echo -e "[-] Image pull completed..!"
            echo -e "$coimage"
        fi
        dnimage=$(echo "$(docker images | grep 'dnif/datanode' | grep "$tag")")
        if [ -n "$dnimage" ]; then
            echo -e "\n[-] Docker Image datanode:$tag already exists."
            echo -e "$dnimage"
        else
            echo -e "[-] Docker Image datanode:$tag does not exist. Pulling the image..."
            docker pull docker.io/dnif/datanode:$tag
            echo -e "[-] Image pull completed..!"
            echo -e "$dnimage"
        fi
    elif [[ "$1" == "console-v9" ]]; then
        echo -e "\n[-] Checking Docker Image for CONSOLE $tag\n"
        lcimage=$(echo "$(docker images | grep 'dnif/console' | grep "$tag")")
        if [ -n "$lcimage" ]; then
            echo -e "[-] Docker Image console:$tag already exists."
            echo -e "$lcimage"
        else
            echo -e "[-] Docker Image console:$tag does not exist. Pulling the image..."
            docker pull docker.io/dnif/console:$tag
            echo -e "[-] Image pull completed..!"
            echo -e "$lcimage"
        fi
    elif [[ "$1" == "datanode-v9" ]]; then
        echo -e "\n[-] Checking Docker Image for DATANODE $tag\n"
        dnimage=$(echo "$(docker images | grep 'dnif/datanode' | grep "$tag")")
        if [ -n "$dnimage" ]; then
            echo -e "[-] Docker Image datanode:$tag already exists."
            echo -e "$dnimage"
        else
            echo -e "[-] Docker Image datanode:$tag does not exist. Pulling the image..."
            docker pull docker.io/dnif/datanode:$tag
            echo -e "[-] Image pull completed..!"
            echo -e "$dnimage"
        fi
    elif [[ "$1" == "adapter-v9" ]]; then
        echo -e "\n[-] Checking Docker Image for ADAPTER $tag\n"
        adimage=$(echo "$(docker images | grep 'dnif/adapter' | grep "$tag")")
        if [ -n "$adimage" ]; then
            echo -e "[-] Docker Image adapter:$tag already exists."
            echo -e "$adimage"
        else
            echo -e "[-] Docker Image adapter:$tag does not exist. Pulling the image..."
            docker pull docker.io/dnif/adapter:$tag
            echo -e "[-] Image pull completed..!"
            echo -e "$adimage"
        fi
	elif [[ "$1" == "prom/pushgateway" ]]; then
        echo -e "\n[-] Checking Docker Image for prom/pushgateway\n"
        raimage=$(echo "$(docker images | grep 'prom/pushgateway')")
        if [ -n "$raimage" ]; then
            echo -e "[-] Docker Image prom/pushgateway already exists."
            echo -e "$raimage"
        else
            echo -e "[-] Docker Image prom/pushgateway does not exist. Pulling the image..."
            docker pull prom/pushgateway
            echo -e "[-] Image pull completed..!"
            echo -e "$raimage"
        fi
    fi
}

function podman_image () {
	if [[ "$1" == "core-v9" ]]; then
		echo -e "\n[-] Checking Docker Image for CORE & DATANODE $tag\n"
		coimage=$(echo "$(podman images | grep 'dnif/core' | grep "$tag")")
		if [ -n "$coimage" ]; then
			echo -e "[-] Docker Image core:$tag already exists."
			echo -e "$coimage"
		else
			echo -e "[-] Docker Image core:$tag does not exist. Pulling the image..."
			podman pull docker.io/dnif/core:$tag
			echo -e "[-] Image pull completed..!"
			echo -e "$coimage"
		fi
		dnimage=$(echo "$(podman images | grep 'dnif/datanode' | grep "$tag")")
		if [ -n "$dnimage" ]; then
			echo -e "\n[-] Docker Image datanode:$tag already exists."
			echo -e "$dnimage"
		else
			echo -e "[-] Docker Image datanode:$tag does not exist. Pulling the image..."
			podman pull docker.io/dnif/datanode:$tag
			echo -e "[-] Image pull completed..!"
			echo -e "$dnimage"
		fi
	elif [[ "$1" == "console-v9" ]]; then
		echo -e "\n[-] Checking Docker Image for CONSOLE $tag\n"
		lcimage=$(echo "$(podman images | grep 'dnif/console' | grep "$tag")")
		if [ -n "$lcimage" ]; then
			echo -e "[-] Docker Image console:$tag already exists."
			echo -e "$lcimage"
		else
			echo -e "[-] Docker Image console:$tag does not exist. Pulling the image..."
			podman pull docker.io/dnif/console:$tag
			echo -e "[-] Image pull completed..!"
			echo -e "$lcimage"
		fi
	elif [[ "$1" == "datanode-v9" ]]; then
		echo -e "\n[-] Checking Docker Image for DATANODE $tag\n"
		dnimage=$(echo "$(podman images | grep 'dnif/datanode' | grep "$tag")")
		if [ -n "$dnimage" ]; then
			echo -e "[-] Docker Image datanode:$tag already exists."
			echo -e "$dnimage"
		else
			echo -e "[-] Docker Image datanode:$tag does not exist. Pulling the image..."
			podman pull docker.io/dnif/datanode:$tag
			echo -e "[-] Image pull completed..!"
			echo -e "$dnimage"
		fi
	elif [[ "$1" == "adapter-v9" ]]; then
		echo -e "\n[-] Checking Docker Image for ADAPTER $tag\n"
		adimage=$(echo "$(podman images | grep 'dnif/adapter' | grep "$tag")")
		if [ -n "$adimage" ]; then
			echo -e "[-] Docker Image adapter:$tag already exists."
			echo -e "$adimage"
		else
			echo -e "[-] Docker Image adapter:$tag does not exist. Pulling the image..."
			podman pull docker.io/dnif/adapter:$tag
			echo -e "[-] Image pull completed..!"
			echo -e "$adimage"
		fi
	elif [[ "$1" == "prom/pushgateway" ]]; then
        echo -e "\n[-] Checking Docker Image for prom/pushgateway\n"
        raimage=$(echo "$(podman images | grep 'prom/pushgateway')")
        if [ -n "$raimage" ]; then
            echo -e "[-] Docker Image prom/pushgateway already exists."
            echo -e "$raimage"
        else
            echo -e "[-] Docker Image prom/pushgateway does not exist. Pulling the image..."
            podman pull prom/pushgateway
            echo -e "[-] Image pull completed..!"
            echo -e "$raimage"
        fi
	fi	
}

function install_jdk(){
	echo -e "[-] Checking for OpenJDK \n"
	source /etc/profile
	if type -p java; then
		_java=java
	elif [[ -n "$JAVA_HOME" ]] && [[ -x "$JAVA_HOME/bin/java" ]]; then
		echo -e "[-] Found java executable in $JAVA_HOME \n"
		_java="$JAVA_HOME/bin/java"
	else
		default="Y"
		echo -e "[-] To proceed further you have to install openjdk 20.0.2 before installation\n"
		read -p "[-] To install OpenJdk 20.0.2 type [Y/n] " var
		#read -r var
		input=${var:-$default}
		temp=${input^^}
		if [ "$temp" == "Y" ]; then
			mkdir -p /usr/lib/jvm/&>> /DNIF/install.log
			jdk_url="https://download.java.net/java/GA/jdk20.0.2/6e380f22cbe7469fa75fb448bd903d8e/9/GPL/openjdk-20.0.2_linux-x64_bin.tar.gz"
			jdk_tarball="/var/tmp/openjdk-20.0.2_linux-x64_bin.tar.gz"
			# Check if the tarball already exists
			if [[ -f "$jdk_tarball" ]]; then
				echo "JDK tarball already exists at $jdk_tarball. Skipping download."
			else
				echo "Downloading OpenJDK tarball..."
				wget "$jdk_url" -O "$jdk_tarball"&>> /DNIF/install.log
				if [[ $? -ne 0 ]]; then
					echo "Download failed. Exiting."
					exit 1
				fi
			fi
			tar -xvf /var/tmp/openjdk-20.0.2_linux-x64_bin.tar.gz -C /usr/lib/jvm/ &>> /DNIF/install.log
			echo "export JAVA_HOME=/usr/lib/jvm/jdk-20.0.2" > /etc/profile.d/jdk.sh
			echo "export PATH=\$PATH:\$JAVA_HOME/bin" >> /etc/profile.d/jdk.sh
			mkdir -p /usr/lib/jvm/java-20.0.2-openjdk-amd64&>> /DNIF/install.log
			cp -r /usr/lib/jvm/jdk-20.0.2/* /usr/lib/jvm/java-20.0.2-openjdk-amd64/&>> /DNIF/install.log
			echo "export JAVA_HOME=/usr/lib/jvm/java-20.0.2-openjdk-amd64" >> /etc/profile
			source /etc/profile.d/jdk.sh&>> /DNIF/install.log
			source /etc/profile
		else
			echo "[-] Aborted"
			exit 0
		fi
	fi
	if [[ "$_java" ]]; then
		version=$("$_java" -version 2>&1 | awk -F '"' '/version/ {print $2}')
		if [[ "$version" == "20.0.2" ]]; then
			echo -e "\n[-] OpenJdk $version version is running\n"
		else
			echo -e "\n[-] Found Current OpenJdk version $version, required version is OpenJdk 20.0.2"
			exit 0
		fi
	fi
}

function sysctl_check() {
	count=$(sysctl -n vm.max_map_count)
	if [ "$count" = "262144" ]; then
		echo -e "[-] Fine tuning the operating system\n"
		#ufw -f reset&>> /DNIF/install.log
	else
		echo -e "#memory & file settings
		fs.file-max=1000000
		vm.overcommit_memory=1
		vm.max_map_count=262144
		#n/w receive buffer
		net.core.rmem_default=33554432
		net.core.rmem_max=33554432" >>/etc/sysctl.conf
		sysctl -p&>> /DNIF/install.log
		#ufw -f reset&>> /DNIF/install.log
	fi
}

function set_proxy() {
	echo "HTTP_PROXY="\"$ProxyUrl"\"" >> /etc/environment
	echo "HTTPS_PROXY="\"$ProxyUrl"\"" >> /etc/environment
	echo "https_proxy="\"$ProxyUrl"\"" >> /etc/environment
	echo "http_proxy="\"$ProxyUrl"\"" >> /etc/environment
	export HTTP_PROXY=$ProxyUrl 
	export HTTPS_PROXY=$ProxyUrl 
	export https_proxy=$ProxyUrl 
	export http_proxy=$ProxyUrl
}

#----------------------------------------------------------------------------------------------------------------------------------

function python_install() {
	echo -e "[-] Checking for python3\n"
	if [ -x "$(command -v python3)" ]; then
		echo -e "[-] $(python3 --version) version is present\n"
	else
		echo -e "[-] Installing python3\n"
		sudo dnf update -y &>> /DNIF/install.log
		sudo dnf install -y python3 &>> /DNIF/install.log
		echo -e "\n[-] Installed $(python3 --version) version\n"
	fi
	echo -e "[-] Checking for pip3\n"
	if [ -x "$(command -v pip3)" ]; then
		echo -e "[-] $(pip3 --version) version is present\n"
	else
		echo -e "[-] Installing pip3\n"
		#sudo dnf update -y &>> /DNIF/install.log
		sudo dnf install -y python3-pip &>> /DNIF/install.log
		echo -e "[-] Installed $(pip3 --version) version\n"
	fi
}

function podman_compose_check() {
	file="/usr/bin/podman-compose"
	if [ -f "$file" ]; then
		version=$(podman-compose version | grep 'podman version' | awk '{print $3}' | cut -d "-" -f1)
		if [[ "$version" != "1.0.4" ]]; then
			echo -n "[-] Finding podman-compose installation - found incompatible version"
			echo -e "... \e[0;31m[ERROR] \e[0m\n"
			echo -e "[-] Updating podman-compose\n"
			rm -rf /usr/bin/podman-compose&>> /DNIF/install.log
            pip3 install --upgrade setuptools&>> /DNIF/install.log
			pip3 install https://github.com/containers/podman-compose/archive/devel.tar.gz&>> /DNIF/install.log
			sudo ln -s /usr/local/bin/podman-compose /usr/bin/podman-compose&>> /DNIF/install.log
			echo -e "[-] Installing podman-compose - ... \e[1;32m[DONE] \e[0m\n"
		else
			echo -e "[-] podman-compose up-to-date\n"
			echo -e "[-] Installing podman-compose - ... \e[1;32m[DONE] \e[0m\n"
		fi
	else
		echo -e "[-] Finding podman-compose installation - ... \e[1;31m[NEGATIVE] \e[0m\n"
		echo -e "[-] Installing podman-compose\n"
		pip3 install --upgrade setuptools&>> /DNIF/install.log
		pip3 install https://github.com/containers/podman-compose/archive/devel.tar.gz&>> /DNIF/install.log
		sudo ln -s /usr/local/bin/podman-compose /usr/bin/podman-compose&>> /DNIF/install.log
        echo -e "[-] Installing podman-compose - ... \e[1;32m[DONE] \e[0m\n"
	fi
}

function podman_check() {
	echo -e "[-] Finding podman installation\n"
	if [ -x "$(command -v podman)" ]; then
		currentver="$(podman --version|cut -d ' ' -f3)"
		requiredver="2.2.1"
		if [ "$(printf '%s\n' "$requiredver" "$currentver" | sort -V | head -n1)" = "$requiredver" ]; then
			echo -e "[-] podman up-to-date\n"
			echo -e "[-] Finding podman installation ...\e[1;32m[DONE] \e[0m\n"
		else
			echo -n "[-] Finding podman installation - found incompatible version"
			echo -e "... \e[0;31m[ERROR] \e[0m\n"
			echo -e "[-] Uninstalling podman\n"
			podman_install
		fi
	else
		echo -e "[-] Finding podman installation - ... \e[1;31m[NEGATIVE] \e[0m\n"
		echo -e "[-] Installing podman\n"
		podman_install
		echo -e "[-] Finding podman installation - ... \e[1;32m[DONE] \e[0m\n"
	fi
}

function podman_install() {
	sudo dnf install -y @container-tools&>> /DNIF/install.log
}

function install_zerotier() {
    # Check if zerotier-one is already installed
    if command -v zerotier-cli >/dev/null 2>&1; then
        echo "ZeroTier is already installed. Skipping installation."
        return 0
    fi
    
    echo "Installing ZeroTier using the default script..."

    # Try the basic SSL-based installation
    if curl -s https://install.zerotier.com | sudo bash; then
        if command -v zerotier-cli >/dev/null 2>&1; then
            echo "ZeroTier installed successfully using default method."

            NETWORK_ID=""
            while [[ ! "$NETWORK_ID" =~ ^[0-9a-f]{16}$ ]]; do
                echo -e "\nEnter your 16-digit ZeroTier Network ID: \c"
                read -r NETWORK_ID
                if [[ ! "$NETWORK_ID" =~ ^[0-9a-f]{16}$ ]]; then
                    echo "[ERROR] Invalid Network ID. It should be a 16-character hexadecimal string."
                fi
            done
            echo "You entered ZeroTier Network ID: $NETWORK_ID"

            # Join the ZeroTier network
            echo "Joining ZeroTier network: $NETWORK_ID"
            sudo zerotier-cli join "$NETWORK_ID" || { echo "[ERROR] Failed to join ZeroTier network."; }
            return 0
        else
            echo "[ERROR] Installation script ran but ZeroTier is still not found."
        fi
    else
        echo "Default installation method failed. Trying GPG-verified installation..."
    fi

    # Check if gpg is installed
    if ! command -v gpg >/dev/null 2>&1; then
        echo "'gpg' not found. ZeroTier installation Failed!"
    else
        # Try the GPG-verified method
        curl -s 'https://raw.githubusercontent.com/zerotier/ZeroTierOne/main/doc/contact%40zerotier.com.gpg' | gpg --import
        if z=$(curl -s 'https://install.zerotier.com/' | gpg); then
            echo "$z" | sudo bash
            if command -v zerotier-cli >/dev/null 2>&1; then
                echo "ZeroTier installed successfully using GPG-verified method."
		
                NETWORK_ID=""
		while [[ ! "$NETWORK_ID" =~ ^[0-9a-f]{16}$ ]]; do
		    echo -e "\nEnter your 16-digit ZeroTier Network ID: \c"
		    read -r NETWORK_ID
		    if [[ ! "$NETWORK_ID" =~ ^[0-9a-f]{16}$ ]]; then
		        echo "[ERROR] Invalid Network ID. It should be a 16-character hexadecimal string."
		    fi
		done
                echo "You entered ZeroTier Network ID: $NETWORK_ID"

                # Join the ZeroTier network
                echo "Joining ZeroTier network: $NETWORK_ID"
                sudo zerotier-cli join "$NETWORK_ID" || { echo "[ERROR] Failed to join ZeroTier network."; }
                return 0
            else
                echo "[ERROR] GPG-verified script ran but ZeroTier is not detected."
            fi
        else
            echo "[ERROR] GPG verification of the install script failed. ZeroTier not installed."
            return 1
        fi
    fi
}

function ra_install() {
	
 	CRON_JOB="* * * * * . /etc/profile; /usr/bin/python3 /DNIF/RA/bloo-ra/system_telemetry/collect_telemetry.py >> /DNIF/RA/log/system_health_telemetry.log 2>&1"
	UNIQUE_IDENTIFIER="/DNIF/RA/bloo-ra/system_telemetry/collect_telemetry.py"

	# Check if the cron job already exists
 	if ! crontab -l 2>/dev/null | grep -qF "$UNIQUE_IDENTIFIER"; then
  		mkdir -p /DNIF/RA
    		mkdir -p /DNIF/RA/log
		mkdir -p /DNIF/RA/config
		ra_url="https://raw.githubusercontent.com/bloo-team/dnif-installer/main/system_telemetry_collector.tar.gz"
		ra_tarball="/var/tmp/system_telemetry_collector.tar.gz"
		if [[ -f "$ra_tarball" ]]; then
			echo "RA tarball already exists at $ra_tarball. Skipping download."
		else
			echo "Downloading RA tarball..."
			wget "$ra_url" -O "$ra_tarball"&>> /DNIF/install.log
			if [[ $? -ne 0 ]]; then
				echo "Download failed. Exiting."
				exit 1
			fi
		fi
		tar -xvf /var/tmp/system_telemetry_collector.tar.gz -C /DNIF/RA/ &>> /DNIF/install.log
		
		if [[ $os == "ubuntu" ]]; then
			apt-get update && apt-get install -y \
				python3 \
				python3-pip \
				smartmontools \
				sysstat \
				lm-sensors \
				iproute2 \
				net-tools \
				sudo \
				auditd \
				iptables \
				&& rm -rf /var/lib/apt/lists/*
	
		elif [[ $os == "centos" || $os == "rhel" ]]; then
			dnf update -y && dnf install -y \
				python3 \
				python3-pip \
				smartmontools \
				sysstat \
				lm_sensors \
				iproute \
				net-tools \
				sudo \
				audit \
				iptables \
				&& dnf clean all
		fi

		cd /DNIF/RA/bloo-ra/system_telemetry/
		pip3 install -r requirements.txt

       		DEFAULT_PORT=9200
		PORT=""
		echo -e "\nEnter Prometheus port number [Press Enter to use default: $DEFAULT_PORT]: \c"
		read -r PORT
		# If input is empty, use default
		if [[ -z "$PORT" ]]; then
			PORT=$DEFAULT_PORT
		fi
		# validate it's a valid port number (1–65535)
		while ! [[ "$PORT" =~ ^[0-9]+$ ]] || [ "$PORT" -lt 1 ] || [ "$PORT" -gt 65535 ]; do
			echo -e "Invalid port. Please enter a number between 1 and 65535 [Press Enter to use default: $DEFAULT_PORT]: \c"
			read -r PORT
			if [[ -z "$PORT" ]]; then
		        	PORT=$DEFAULT_PORT
		    	fi
		done
		echo "Using port: $PORT"
  		python3 /DNIF/RA/bloo-ra/system_telemetry/config_loader.py --prometheus-host $REMOTE_ADMIN_IP --prometheus-port $PORT

		# Add the new cron job
		(crontab -l 2>/dev/null; echo "$CRON_JOB") | crontab -
		echo "RA cron job added."
  
  		install_zerotier
	else
	    echo "RA Cron job already exists. Skipping..."
	fi
}

tag="v9.4.1"

if [ -r /etc/os-release ]; then
	os="$(. /etc/os-release && echo "$ID")"
fi

case "${os}" in
	ubuntu|centos)
		if [[ $EUID -ne 0 ]]; then
			echo -e "This script must be run as root ... \e[1;31m[ERROR] \e[0m\n"
			exit 1
		else

			ARCH=$(uname -m)
			if [[ $os == "ubuntu" ]]; then
				VER=$(lsb_release -rs)
				release=$(lsb_release -ds)
			elif [[ $os == "centos" ]]; then
				VER=$(cat /etc/redhat-release | sed s/.*release\ // | sed s/\ .*//)
				release="$(. /etc/os-release && echo "$PRETTY_NAME")"
			fi
			mkdir -p /DNIF
			echo -e "\nDNIF Installer for $tag\n"
			echo -e "for more information and code visit https://github.com/dnif/installer\n"

			echo -e "++ Checking operating system for compatibility...\n"

			echo -n "Operating system compatibility"
			sleep 2
			if { [[ "$VER" = "20.04" ]] || [[ "$VER" = "22.04" ]] || [[ "$VER" = "7.9.2009" ]]; } && [[ "$ARCH" = "x86_64" ]]; then
				echo -e " ... \e[1;32m[OK] \e[0m"
				echo -n "Architecture compatibility "
				echo -e " ... \e[1;32m[OK] \e[0m\n"
				echo -e "** found $release $ARCH\n"
				echo -e "[-] Checking operating system for compatibility - ... \e[1;32m[DONE] \e[0m\n"
				echo -e "** Please report issues to https://github.com/dnif/installer/issues"
				echo -e "** for more information visit https://docs.dnif.it/v9/docs/high-level-dnif-architecture\n"
				echo -e "* Select a DNIF component you would like to install"
				echo -e "    [1] Core (CO)"
				echo -e "    [2] Console (LC)"
				echo -e "    [3] Datanode (DN)"
				echo -e "    [4] Adapter (AD)"
				echo -e "    [5] RA-Gateway (RA)\n"
				COMP=""
				while [[ ! $COMP =~ ^[1-5] ]]; do
					echo -e "Pick the number corresponding to the component (1 - 4):  \c"
					read -r COMP
				done
				echo -e "-----------------------------------------------------------------------------------------"
				case "${COMP^^}" in
					1)
						echo -e "[-] Installing the CORE \n"
						sleep 2
						if [[ "$1" == "proxy" ]]; then
							ProxyUrl=""
							while [[ ! "$ProxyUrl" ]]; do
								echo -e "ENTER Proxy url: \c"
								read -r ProxyUrl
							done
							set_proxy $ProxyUrl
						fi
						if [[ $os == "ubuntu" ]]; then
							docker_check
							compose_check
							sysctl_check
							ufw -f reset&>> /DNIF/install.log
						elif [[ $os == "centos" ]]; then
							docker_check_centos
							compose_check_centos
							sysctl_check
							setenforce 0 &>> /DNIF/install.log || true
						fi
						if [[ $ProxyUrl ]]; then
							mkdir -p /etc/systemd/system/docker.service.d
							echo -e "[Service]
							Environment=\"HTTPS_PROXY=$ProxyUrl\"">/etc/systemd/system/docker.service.d/http-proxy.conf

							sudo systemctl daemon-reload
							sudo systemctl restart docker
						fi
						#Installing JDK
						install_jdk
						#Pulling the latest Docker image after verifying against the existing Docker images.
						docker_image "core-v9"
						
						cd /
						sudo mkdir -p DNIF
						COREIP=""
						while [[ ! $COREIP =~ ^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$ ]]; do
							echo -e "\nENTER CORE IP: \c"
							read -r COREIP
						done
						UI_IP=""
						while [[ ! $UI_IP =~ ^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$ ]]; do
							echo -e "ENTER CONSOLE IP: \c"
							read -r UI_IP
						done
						
						REMOTE_ADMIN=""
						REMOTE_ADMIN_IP=""
						# Prompt for REMOTE_ADMIN (true/false)
						while [[ "$REMOTE_ADMIN" != "true" && "$REMOTE_ADMIN" != "false" ]]; do
							echo -n "Enable REMOTE_ADMIN? (true/false): "
							read -r REMOTE_ADMIN
						done
						# If REMOTE_ADMIN is true, ask for REMOTE_ADMIN_IP
						if [[ "$REMOTE_ADMIN" == "true" ]]; then
							while [[ ! $REMOTE_ADMIN_IP =~ ^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$ ]]; do
								echo -e "\nENTER IP of Prometheus gateway: \c"
								read -r REMOTE_ADMIN_IP
							done
							ra_install
						fi

						sudo echo -e "version: "\'2.1\'"
services:
  core:
    image: dnif/core:$tag
    network_mode: "\'host\'"
    restart: unless-stopped
    cap_add:
      - NET_ADMIN
    volumes:
      - /DNIF/CO:/dnif
      - /DNIF/common:/common
      - /DNIF/backup/core:/backup
    environment:
      - "\'CORE_IP="$COREIP"\'"
      - "\'UI_IP="$UI_IP"\'"
      - "\'PROXY="$ProxyUrl"\'"
      - "\'REMOTE_ADMIN_IP="$REMOTE_ADMIN_IP"\'"
      - "\'REMOTE_ADMIN="$REMOTE_ADMIN"\'"
      
    ulimits:
      memlock:
        soft: -1
        hard: -1
    container_name: core-v9
  datanode-master:
    privileged: true
    image: dnif/datanode:$tag
    network_mode: "\'host\'"
    restart: unless-stopped
    cap_add:
      - NET_ADMIN
    volumes:
      - /DNIF/DL:/dnif
      - /run:/run
      - /opt:/opt
      - /etc/systemd/system:/etc/systemd/system
      - /DNIF/common:/common
      - /DNIF/backup/dn:/backup
    environment:
      - "\'CORE_IP="$COREIP"\'"
      - "\'REMOTE_ADMIN_IP="$REMOTE_ADMIN_IP"\'"
      - "\'REMOTE_ADMIN="$REMOTE_ADMIN"\'"
    ulimits:
      memlock:
        soft: -1
        hard: -1
    container_name: datanode-master-v9">>/DNIF/docker-compose.yaml
						cd /DNIF || exit
						echo -e "\n[-] Starting container... \n"
						docker-compose up -d
						echo -e "\n[-] Starting container... \e[1;32m[DONE] \e[0m\n"
						docker ps
						echo -e "\n** Congratulations you have successfully installed the CORE \n"
						;;

					2)
						echo -e "[-] Installing the Console \n"
						sleep 5

						if [[ $os == "ubuntu" ]]; then
							docker_check
							compose_check
							sysctl_check
							ufw -f reset&>> /DNIF/install.log
						elif [[ $os == "centos" ]]; then
							docker_check_centos
							compose_check_centos
							sysctl_check
							setenforce 0 &>> /DNIF/install.log || true
						fi

						#Pulling the latest Docker image after verifying against the existing Docker images.
						docker_image "console-v9"
						
						cd /
						sudo mkdir -p /DNIF
						sudo mkdir -p /DNIF/LC
						UI_IP=""
						while [[ ! $UI_IP =~ ^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$ ]]; do
							echo -e "\nENTER CONSOLE IP: \c"
							read -r UI_IP
						done

						REMOTE_ADMIN=""
						REMOTE_ADMIN_IP=""
						# Prompt for REMOTE_ADMIN (true/false)
						while [[ "$REMOTE_ADMIN" != "true" && "$REMOTE_ADMIN" != "false" ]]; do
							echo -n "Enable REMOTE_ADMIN? (true/false): "
							read -r REMOTE_ADMIN
						done
						# If REMOTE_ADMIN is true, ask for REMOTE_ADMIN_IP
						if [[ "$REMOTE_ADMIN" == "true" ]]; then
							while [[ ! $REMOTE_ADMIN_IP =~ ^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$ ]]; do
								echo -e "\nENTER IP of Prometheus gateway: \c"
								read -r REMOTE_ADMIN_IP
							done
							ra_install
						fi
						sudo echo -e "version: "\'2.1\'"
services:
 console:
  image: dnif/console:$tag
  network_mode: "\'host\'"
  restart: unless-stopped
  environment:
   - "\'UI_IP="$UI_IP"\'"
   - "\'REMOTE_ADMIN_IP="$REMOTE_ADMIN_IP"\'"
   - "\'REMOTE_ADMIN="$REMOTE_ADMIN"\'"
   - "\'VERSION="$tag"\'"
  cap_add:
   - NET_ADMIN
  volumes:
   - /DNIF/LC:/dnif/lc
  container_name: console-v9">/DNIF/LC/docker-compose.yaml
						cd /DNIF/LC || exit
						echo -e "\n[-] Starting container... \n"
						docker-compose up -d
						echo -e "\n[-] Starting container... DONE\n"
						docker ps
						echo -e "\n** Congratulations you have successfully installed the Console\n"
						;;
					3)
						echo -e "[-] Installing the Datanode\n"

						sleep 5
						if [[ $os == "ubuntu" ]]; then
							docker_check
							compose_check
							sysctl_check
							ufw -f reset&>> /DNIF/install.log
						elif [[ $os == "centos" ]]; then
							docker_check_centos
							compose_check_centos
							sysctl_check
							setenforce 0 &>> /DNIF/install.log || true
						fi
						#Installing JDK
						install_jdk
						#Pulling the latest Docker image after verifying against the existing Docker images.
						docker_image "datanode-v9"

						COREIP=""
						while [[ ! $COREIP =~ ^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$ ]]; do
							echo -e "\nENTER CORE IP: \c"
							read -r COREIP
						done
						
						REMOTE_ADMIN=""
						REMOTE_ADMIN_IP=""
						# Prompt for REMOTE_ADMIN (true/false)
						while [[ "$REMOTE_ADMIN" != "true" && "$REMOTE_ADMIN" != "false" ]]; do
							echo -n "Enable REMOTE_ADMIN? (true/false): "
							read -r REMOTE_ADMIN
						done
						# If REMOTE_ADMIN is true, ask for REMOTE_ADMIN_IP
						if [[ "$REMOTE_ADMIN" == "true" ]]; then
							while [[ ! $REMOTE_ADMIN_IP =~ ^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$ ]]; do
								echo -e "\nENTER IP of Prometheus gateway: \c"
								read -r REMOTE_ADMIN_IP
							done
							ra_install
						fi
						sudo mkdir -p /DNIF
						sudo mkdir -p /DNIF/DL
						sudo echo -e "version: "\'2.1\'"
services:
  datanode:
    privileged: true
    image: dnif/datanode:$tag
    network_mode: "\'host\'"
    restart: unless-stopped
    cap_add:
      - NET_ADMIN
    volumes:
      - /DNIF/DL:/dnif
      - /run:/run
      - /opt:/opt
      - /etc/systemd/system:/etc/systemd/system
      - /DNIF/common:/common
      - /DNIF/backup:/backup
    environment:
      - "\'CORE_IP="$COREIP"\'"
      - "\'REMOTE_ADMIN_IP="$REMOTE_ADMIN_IP"\'"
      - "\'REMOTE_ADMIN="$REMOTE_ADMIN"\'"
    ulimits:
      memlock:
        soft: -1
        hard: -1
    container_name: datanode-v9">>/DNIF/DL/docker-compose.yaml
						cd /DNIF/DL || exit
						IP=$(ip addr | grep 'state UP' -A2 | tail -n1 | awk '{print $2}' | cut -f1  -d'/')
						echo -e "\n[-] Starting container... \n"
						docker-compose up -d
						echo -e "\n[-] Starting container ... \e[1;32m[DONE] \e[0m"
						docker ps
						echo -e "\n** Congratulations you have successfully installed the Datanode\n"
						echo -e "**   Activate the Datanode ($IP) from the components page\n"
						;;
					4)
						echo -e "[-] Installing the ADAPTER \n"
						if [[ "$1" == "proxy" ]]; then
							ProxyUrl=""
							while [[ ! "$ProxyUrl" ]]; do
								echo -e "ENTER Proxy url: \c"
								read -r ProxyUrl
							done
							set_proxy $ProxyUrl
						fi
						if [[ $os == "ubuntu" ]]; then
							docker_check
							compose_check
							sysctl_check
							ufw -f reset&>> /DNIF/install.log
						elif [[ $os == "centos" ]]; then
							docker_check_centos
							compose_check_centos
							sysctl_check
							setenforce 0 &>> /DNIF/install.log || true
						fi
						if [[ $ProxyUrl ]]; then
							mkdir -p /etc/systemd/system/docker.service.d
							echo -e "[Service]
							Environment=\"HTTPS_PROXY=$ProxyUrl\"">/etc/systemd/system/docker.service.d/http-proxy.conf

							sudo systemctl daemon-reload
							sudo systemctl restart docker
						fi
						#Pulling the latest Docker image after verifying against the existing Docker images.
						docker_image "adapter-v9"

						COREIP=""
						while [[ ! $COREIP =~ ^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$ ]]; do
							echo -e "\nENTER CORE IP: \c"
							read -r COREIP
						done
						HOSTIP=""
						while [[ ! $HOSTIP =~ ^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$ ]]; do
							echo -e "ENTER ADAPTER IP: \c"
							read -r HOSTIP
						done

						REMOTE_ADMIN=""
						REMOTE_ADMIN_IP=""
						# Prompt for REMOTE_ADMIN (true/false)
						while [[ "$REMOTE_ADMIN" != "true" && "$REMOTE_ADMIN" != "false" ]]; do
							echo -n "Enable REMOTE_ADMIN? (true/false): "
							read -r REMOTE_ADMIN
						done
						# If REMOTE_ADMIN is true, ask for REMOTE_ADMIN_IP
						if [[ "$REMOTE_ADMIN" == "true" ]]; then
							while [[ ! $REMOTE_ADMIN_IP =~ ^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$ ]]; do
								echo -e "\nENTER IP of Prometheus gateway: \c"
								read -r REMOTE_ADMIN_IP
							done
							ra_install
						fi
						cd /
						sudo mkdir -p /DNIF
						sudo mkdir -p /DNIF/AD
						sudo echo -e "version: "\'2.1\'"
services:
 adapter:
  image: dnif/adapter:$tag
  network_mode: "\'host\'"
  restart: unless-stopped
  cap_add:
   - NET_ADMIN
  environment:
   - "\'CORE_IP="$COREIP"\'"
   - "\'HOST_IP="$HOSTIP"\'"
   - "\'PROXY="$ProxyUrl"\'"
   - "\'REMOTE_ADMIN_IP="$REMOTE_ADMIN_IP"\'"
   - "\'REMOTE_ADMIN="$REMOTE_ADMIN"\'"
  tmpfs: /DNIF
  volumes:
   - /DNIF/AD:/dnif
   - /DNIF/backup/ad:/backup
  container_name: adapter-v9">/DNIF/AD/docker-compose.yaml
						cd /DNIF/AD || exit
						IP=$(ip addr | grep 'state UP' -A2 | tail -n1 | awk '{print $2}' | cut -f1  -d'/')
						echo -e "\n[-] Starting container...\n "
						docker-compose up -d
						echo -e "\n[-] Starting container ... \e[1;32m[DONE] \e[0m\n"
						docker ps
						echo -e "\n** Congratulations you have successfully installed the Adapter\n"
						echo -e "**   Activate the Adapter ($IP) from the components page\n"
						;;
					5)
						echo -e "[-] Installing the RA-Gateway\n"
						if [[ "$1" == "proxy" ]]; then
							ProxyUrl=""
							while [[ ! "$ProxyUrl" ]]; do
								echo -e "ENTER Proxy url: \c"
								read -r ProxyUrl
							done
							set_proxy $ProxyUrl
						fi
						if [[ $os == "ubuntu" ]]; then
							docker_check
							compose_check
							sysctl_check
							ufw -f reset&>> /DNIF/install.log
						elif [[ $os == "centos" ]]; then
							docker_check_centos
							compose_check_centos
							sysctl_check
							setenforce 0 &>> /DNIF/install.log || true
						fi
						if [[ $ProxyUrl ]]; then
							mkdir -p /etc/systemd/system/docker.service.d
							echo -e "[Service]
							Environment=\"HTTPS_PROXY=$ProxyUrl\"">/etc/systemd/system/docker.service.d/http-proxy.conf

							sudo systemctl daemon-reload
							sudo systemctl restart docker
						fi
						#Pulling the latest Docker image after verifying against the existing Docker images.
						docker_image "prom/pushgateway"
      						install_zerotier
						cd /
						sudo mkdir -p /DNIF
						sudo mkdir -p /DNIF/RA
						sudo echo -e "version: '2.1'
services:
  pushgateway:
      image: prom/pushgateway
      ports:
        - "9200:9091"
      restart: always">/DNIF/RA/docker-compose.yaml
						cd /DNIF/RA || exit
						echo -e "\n[-] Starting container...\n "
						docker-compose up -d
						echo -e "\n[-] Starting container ... \e[1;32m[DONE] \e[0m\n"
						docker ps
						echo -e "\n** Congratulations you have successfully installed the RA-Gateway\n"
						;;
					esac

			else
				echo -e "\e[0;31m[ERROR] \e[0m Operating system is incompatible"
			fi
		fi			
		;;
	rhel)
		if [[ $EUID -ne 0 ]]; then
			echo -e "This script must be run as root ... \e[1;31m[ERROR] \e[0m\n"
			exit 1
		else

			ARCH=$(uname -m)
			VER=$(cat /etc/redhat-release | sed s/.*release\ // | sed s/\ .*//)
			release="$(. /etc/os-release && echo "$PRETTY_NAME")"

			mkdir -p /DNIF
			echo -e "\nDNIF Installer for $tag\n"
			echo -e "for more information and code visit https://github.com/dnif/installer\n"

			echo -e "++ Checking operating system for compatibility...\n"

			echo -n "Operating system compatibility "
			sleep 2
			if [[ "$VER" = "8.4" ]] && [[ "$ARCH" = "x86_64" ]];  then # replace 8.4 by the number of release you want
				echo -e " ... \e[1;32m[OK] \e[0m"
				echo -n "Architecture compatibility "
				echo -e " ... \e[1;32m[OK] \e[0m\n"
				echo -e "** found $release $ARCH\n"
				echo -e "[-] Checking operating system for compatibility - ... \e[1;32m[DONE] \e[0m\n"
				echo -e "** Please report issues to https://github.com/dnif/installer/issues"
				echo -e "* Select a DNIF component you would like to install"
				echo -e "    [1] Core (CO)"
				echo -e "    [2] Console (LC)"
				echo -e "    [3] Datanode (DN)"
				echo -e "    [4] Adapter (AD)"
    				echo -e "    [5] RA-Gateway (RA)\n"
				COMP=""
				while [[ ! $COMP =~ ^[1-5] ]]; do
					echo -e "Pick the number corresponding to the component (1 - 4):  \c"
							read -r COMP
				done
				echo -e "-----------------------------------------------------------------------------------------"
				case "${COMP^^}" in
					1)
						echo -e "[-] Installing the CORE \n"
						if [[ "$1" == "proxy" ]]; then
							ProxyUrl=""
							while [[ ! "$ProxyUrl" ]]; do
								echo -e "ENTER Proxy url: \c"
								read -r ProxyUrl
							done
							set_proxy $ProxyUrl
						fi
						python_install
						podman_check
						podman_compose_check
						sysctl_check
						setenforce 0 &>> /DNIF/install.log || true
						if [[ $ProxyUrl ]]; then
							mkdir -p /etc/systemd/system/docker.service.d
							echo -e "[Service]
							Environment=\"HTTPS_PROXY=$ProxyUrl\"">/etc/systemd/system/docker.service.d/http-proxy.conf

							sudo systemctl daemon-reload
							sudo systemctl restart podman
						fi
						#Installing JDK
						install_jdk
						mkdir -p /DNIF/CO&>> /DNIF/install.log
						mkdir -p /DNIF/common&>> /DNIF/install.log
						mkdir -p /DNIF/backup/core&>> /DNIF/install.log
						#Pulling the latest Docker image after verifying against the existing Docker images.
						podman_image "core-v9"

						COREIP=""
						while [[ ! $COREIP =~ ^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$ ]]; do
							echo -e "\nENTER CORE IP: \c"
							read -r COREIP
						done
						UI_IP=""
						while [[ ! $UI_IP =~ ^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$ ]]; do
							echo -e "ENTER CONSOLE IP: \c"
							read -r UI_IP
						done

						REMOTE_ADMIN=""
						REMOTE_ADMIN_IP=""
						# Prompt for REMOTE_ADMIN (true/false)
						while [[ "$REMOTE_ADMIN" != "true" && "$REMOTE_ADMIN" != "false" ]]; do
							echo -n "Enable REMOTE_ADMIN? (true/false): "
							read -r REMOTE_ADMIN
						done
						# If REMOTE_ADMIN is true, ask for REMOTE_ADMIN_IP
						if [[ "$REMOTE_ADMIN" == "true" ]]; then
							while [[ ! $REMOTE_ADMIN_IP =~ ^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$ ]]; do
								echo -e "\nENTER IP of Prometheus gateway: \c"
								read -r REMOTE_ADMIN_IP
							done
							ra_install
						fi
						sudo echo -e "version: "\'2.0\'"
services:
  core:
    image: docker.io/dnif/core:$tag
    network_mode: "\'host\'"
    restart: unless-stopped
    cap_add:
      - NET_ADMIN
    volumes:
      - /DNIF/CO:/dnif
      - /DNIF/common:/common
      - /DNIF/backup/core:/backup
    environment:
      - "\'CORE_IP="$COREIP"\'"
      - "\'UI_IP="$UI_IP"\'"
      - "\'PROXY="$ProxyUrl"\'"
      - "\'REMOTE_ADMIN_IP="$REMOTE_ADMIN_IP"\'"
      - "\'REMOTE_ADMIN="$REMOTE_ADMIN"\'"
    ulimits:
      memlock:
        soft: -1
        hard: -1
    container_name: core-v9">>/DNIF/podman-compose.yaml
						cd /DNIF
						echo -e "\n[-] Starting container... \n"
						podman-compose up -d
						echo -e "\n[-] Starting container... \e[1;32m[DONE] \e[0m\n"
                        podman ps
						mkdir -p /DNIF/DL&>> /DNIF/install.log
						mkdir -p /DNIF/backup/dn&>> /DNIF/install.log
					
						echo -e "version: "\'2.0\'"
services:
  datanode-master:
    privileged: true
    image: docker.io/dnif/datanode:$tag
    network_mode: "\'host\'"
    restart: unless-stopped
    cap_add:
      - NET_ADMIN
    volumes:
      - /DNIF/DL:/dnif
      - /run:/run
      - /opt:/opt
      - /etc/systemd/system:/etc/systemd/system
      - /DNIF/common:/common
      - /DNIF/backup/dn:/backup
    environment:
      - "\'CORE_IP="$COREIP"\'"
      - "\'REMOTE_ADMIN_IP="$REMOTE_ADMIN_IP"\'"
      - "\'REMOTE_ADMIN="$REMOTE_ADMIN"\'"
    ulimits:
      memlock:
        soft: -1
        hard: -1
    container_name: datanode-master-v9">>/DNIF/DL/podman-compose.yaml
						cd /DNIF/DL
						echo -e "\n[-] Starting container... \n"
						podman-compose up -d
						echo -e "\n[-] Starting container ... \e[1;32m[DONE] \e[0m"
                        podman ps
						echo -e "\n** Congratulations you have successfully installed the CORE \n"
						;;
					2)
						echo -e "[-] Installing the Console \n"
						python_install
						podman_check
						podman_compose_check
						sysctl_check
						setenforce 0 &>> /DNIF/install.log || true
						file="/usr/bin/wget"
						if [ ! -f "$file " ]; then
							dnf install -y wget&>> /DNIF/install.log
							dnf install -y zip&>> /DNIF/install.log
						fi
						mkdir -p /DNIF/LC
						#Pulling the latest Docker image after verifying against the existing Docker images.
						podman_image "console-v9"
						UI_IP=""
						while [[ ! $UI_IP =~ ^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$ ]]; do
							echo -e "\nENTER CONSOLE IP: \c"
							read -r UI_IP
						done

						REMOTE_ADMIN=""
						REMOTE_ADMIN_IP=""
						# Prompt for REMOTE_ADMIN (true/false)
						while [[ "$REMOTE_ADMIN" != "true" && "$REMOTE_ADMIN" != "false" ]]; do
							echo -n "Enable REMOTE_ADMIN? (true/false): "
							read -r REMOTE_ADMIN
						done
						# If REMOTE_ADMIN is true, ask for REMOTE_ADMIN_IP
						if [[ "$REMOTE_ADMIN" == "true" ]]; then
							while [[ ! $REMOTE_ADMIN_IP =~ ^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$ ]]; do
								echo -e "\nENTER IP of Prometheus gateway: \c"
								read -r REMOTE_ADMIN_IP
							done
							ra_install
						fi
						sudo echo -e "version: "\'2.0\'"
services:
 console:
  image: docker.io/dnif/console:$tag
  network_mode: "\'host\'"
  restart: unless-stopped
  environment:
   - "\'UI_IP="$UI_IP"\'"
   - "\'REMOTE_ADMIN_IP="$REMOTE_ADMIN_IP"\'"
   - "\'REMOTE_ADMIN="$REMOTE_ADMIN"\'"
   - "\'VERSION="$tag"\'"
  cap_add:
   - NET_ADMIN
  volumes:
   - /DNIF/LC:/dnif/lc
  container_name: console-v9">/DNIF/LC/podman-compose.yaml
						echo -e "\n[-] Starting container... \n"
						cd /DNIF/LC
						podman-compose up -d
                        echo -e "\n[-] Starting container... DONE\n"
                        podman ps
						echo -e "\n** Congratulations you have successfully installed the Console\n"
						;;
					3)
						echo -e "[-] Installing the Datanode\n"
						python_install
						podman_check
						podman_compose_check
						sysctl_check
						setenforce 0 &>> /DNIF/install.log || true

						install_jdk

						mkdir -p /DNIF/DL&>> /DNIF/install.log
						mkdir -p /DNIF/common&>> /DNIF/install.log
						mkdir -p /DNIF/backup/dn&>> /DNIF/install.log
						
						podman_image "datanode-v9"

						COREIP=""
						while [[ ! $COREIP =~ ^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$ ]]; do
							echo -e "\nENTER CORE IP: \c"
							read -r COREIP
						done

						REMOTE_ADMIN=""
						REMOTE_ADMIN_IP=""
						# Prompt for REMOTE_ADMIN (true/false)
						while [[ "$REMOTE_ADMIN" != "true" && "$REMOTE_ADMIN" != "false" ]]; do
							echo -n "Enable REMOTE_ADMIN? (true/false): "
							read -r REMOTE_ADMIN
						done
						# If REMOTE_ADMIN is true, ask for REMOTE_ADMIN_IP
						if [[ "$REMOTE_ADMIN" == "true" ]]; then
							while [[ ! $REMOTE_ADMIN_IP =~ ^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$ ]]; do
								echo -e "\nENTER IP of Prometheus gateway: \c"
								read -r REMOTE_ADMIN_IP
							done
							ra_install
						fi

						echo -e "version: "\'2.0\'"
services:
  datanode:
    privileged: true
    image: docker.io/dnif/datanode:$tag
    network_mode: "\'host\'"
    restart: unless-stopped
    cap_add:
      - NET_ADMIN
    volumes:
      - /DNIF/DL:/dnif
      - /run:/run
      - /opt:/opt
      - /etc/systemd/system:/etc/systemd/system
      - /DNIF/common:/common
      - /DNIF/backup:/backup
    environment:
      - "\'CORE_IP="$COREIP"\'"
      - "\'REMOTE_ADMIN_IP="$REMOTE_ADMIN_IP"\'"
      - "\'REMOTE_ADMIN="$REMOTE_ADMIN"\'"
    ulimits:
      memlock:
        soft: -1
        hard: -1
    container_name: datanode-v9">>/DNIF/DL/podman-compose.yaml
						echo -e "\n[-] Starting container... \n"
						cd /DNIF/DL
                        IP=$(ip addr | grep 'state UP' -A2 | tail -n1 | awk '{print $2}' | cut -f1  -d'/')
						podman-compose up -d
                        echo -e "\n[-] Starting container ... \e[1;32m[DONE] \e[0m"
                        podman ps
						echo -e "\n** Congratulations you have successfully installed the Datanode\n"
						echo -e "**   Activate the Datanode ($IP) from the components page\n"
						;;
					4)
						echo -e "[-] Installing the ADAPTER \n"
						if [[ "$1" == "proxy" ]]; then
							ProxyUrl=""
							while [[ ! "$ProxyUrl" ]]; do
								echo -e "ENTER Proxy url: \c"
								read -r ProxyUrl
							done
							set_proxy $ProxyUrl
						fi
						python_install
						podman_check
						podman_compose_check
						sysctl_check
						setenforce 0 &>> /DNIF/install.log || true
						file="/usr/bin/wget"
						if [ ! -f "$file " ]; then
							dnf install -y wget&>> /DNIF/install.log
							dnf install -y zip&>> /DNIF/install.log
						fi

						if [[ $ProxyUrl ]]; then
							mkdir -p /etc/systemd/system/docker.service.d
							echo -e "[Service]
							Environment=\"HTTPS_PROXY=$ProxyUrl\"">/etc/systemd/system/docker.service.d/http-proxy.conf

							sudo systemctl daemon-reload
							sudo systemctl restart podman
						fi
						mkdir -p /DNIF/AD&>> /DNIF/install.log
						mkdir -p /DNIF/backup/ad&>> /DNIF/install.log
						
						podman_image "adapter-v9"

						COREIP=""
						while [[ ! $COREIP =~ ^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$ ]]; do
							echo -e "\nENTER CORE IP: \c"
							read -r COREIP
						done
						HOSTIP=""
						while [[ ! $HOSTIP =~ ^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$ ]]; do
							echo -e "ENTER ADAPTER IP: \c"
							read -r HOSTIP
						done

						REMOTE_ADMIN=""
						REMOTE_ADMIN_IP=""
						# Prompt for REMOTE_ADMIN (true/false)
						while [[ "$REMOTE_ADMIN" != "true" && "$REMOTE_ADMIN" != "false" ]]; do
							echo -n "Enable REMOTE_ADMIN? (true/false): "
							read -r REMOTE_ADMIN
						done
						# If REMOTE_ADMIN is true, ask for REMOTE_ADMIN_IP
						if [[ "$REMOTE_ADMIN" == "true" ]]; then
							while [[ ! $REMOTE_ADMIN_IP =~ ^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$ ]]; do
								echo -e "\nENTER IP of Prometheus gateway: \c"
								read -r REMOTE_ADMIN_IP
							done
							ra_install
						fi

						sudo echo -e "version: "\'2.0\'"
services:
 adapter:
  image: docker.io/dnif/adapter:$tag
  network_mode: "\'host\'"
  restart: unless-stopped
  cap_add:
   - NET_ADMIN
  environment:
   - "\'CORE_IP="$COREIP"\'"
   - "\'HOST_IP="$HOSTIP"\'"
   - "\'PROXY="$ProxyUrl"\'"
   - "\'REMOTE_ADMIN_IP="$REMOTE_ADMIN_IP"\'"
   - "\'REMOTE_ADMIN="$REMOTE_ADMIN"\'"
  tmpfs: /DNIF
  volumes:
   - /DNIF/AD:/dnif
   - /DNIF/backup/ad:/backup
  container_name: adapter-v9">/DNIF/AD/podman-compose.yaml

						echo -e "\n[-] Starting container... \n"
						cd /DNIF/AD
						podman-compose up -d
                        echo -e "\n[-] Starting container ... \e[1;32m[DONE] \e[0m\n"
						podman ps
						echo -e "\n** Congratulations you have successfully installed the Adapter\n"
						echo -e "**   Activate the Adapter ($IP) from the components page\n"
						;;
					5)
						echo -e "[-] Installing the RA-Gateway\n"
						if [[ "$1" == "proxy" ]]; then
							ProxyUrl=""
							while [[ ! "$ProxyUrl" ]]; do
								echo -e "ENTER Proxy url: \c"
								read -r ProxyUrl
							done
							set_proxy $ProxyUrl
						fi
						python_install
						podman_check
						podman_compose_check
						sysctl_check
						setenforce 0 &>> /DNIF/install.log || true
						if [[ $ProxyUrl ]]; then
							mkdir -p /etc/systemd/system/docker.service.d
							echo -e "[Service]
							Environment=\"HTTPS_PROXY=$ProxyUrl\"">/etc/systemd/system/docker.service.d/http-proxy.conf

							sudo systemctl daemon-reload
							sudo systemctl restart podman
						fi
						#Pulling the latest Docker image after verifying against the existing Docker images.
						podman_image "prom/pushgateway"
      						install_zerotier
						cd /
						sudo mkdir -p /DNIF
						sudo mkdir -p /DNIF/RA
						sudo echo -e "version: '2.1'
services:
  pushgateway:
      image: prom/pushgateway
      ports:
        - '9200:9091'
      restart: always">/DNIF/RA/podman-compose.yaml
						cd /DNIF/RA || exit
						echo -e "\n[-] Starting container...\n "
						podman-compose up -d
						echo -e "\n[-] Starting container ... \e[1;32m[DONE] \e[0m\n"
						podman ps
						echo -e "\n** Congratulations you have successfully installed the RA-Gateway\n"
						;;
					esac
			else
				echo -e "\n\e[0;31m[ERROR] \e[0m Operating system is incompatible"
			fi
		fi
		;;
	esac
