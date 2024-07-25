#! /bin/bash

# 判断vultr-cli是否安装
if ! command -v vultr-cli &> /dev/null; then
    echo "------------------------------------------"
    echo "start install vultr-cli"
    # 读取git的release 列表
    LATEST_RELEASE=$(curl -s https://api.github.com/repos/vultr/vultr-cli/releases/latest | grep "tag_name" | cut -d '"' -f 4)
    echo "current version is $LATEST_RELEASE"
    # 读取linux是amd还是arm
    if [ "$(uname -m)" == "x86_64" ]; then
        ARCH="amd64"
    elif [ "$(uname -m)" == "aarch64" ]; then
        ARCH="arm64"
    else
        echo "unsupported architecture"
        exit 1
    fi
    echo "current arch is $ARCH"
    echo "start install vultr-cli"
    echo "download url: https://github.com/vultr/vultr-cli/releases/download/$LATEST_RELEASE/vultr-cli_${LATEST_RELEASE}_linux_$ARCH.tar.gz"
    echo " if download too slow, you can download it by yourself"
    # 判断当前文件夹中是否有已下载的文件
    if [ -f "vultr-cli_${LATEST_RELEASE}_linux_$ARCH.tar.gz" ]; then
        tar -zxvf vultr-cli_${LATEST_RELEASE}_linux_$ARCH.tar.gz
    else
        echo "start download... "
        curl -sL https://github.com/vultr/vultr-cli/releases/download/$LATEST_RELEASE/vultr-cli_${LATEST_RELEASE}_linux_$ARCH.tar.gz | tar -xz
    fi
    # 添加./vultr-cli到PATH
    mv vultr-cli /usr/local/bin/
fi

#判断 VULTR_SSH_KEY 是否设置，没有设置则提示
if [ -z "$VULTR_SSH_KEY" ]; then
    echo "VULTR_SSH_KEY is not set，please get VULTR_SSH_KEY at : https://my.vultr.com/settings/#settingssshkeys , create it and click edit button"
    echo "you will see the url,like https://my.vultr.com/sshkeys/manage/?id={this is your ssh_key}"
    # 让输入
    read -p "Please enter VULTR_SSH_KEY: " VULTR_SSH_KEY
    # 设置为永久的环境变量
    echo "export VULTR_SSH_KEY=$VULTR_SSH_KEY" >> ~/.profile
    source ~/.profile
    echo "VULTR_SSH_KEY has save at ~/.profile,you can change it anytime"
    echo "------------------------------------------"
fi

# 判断 VULTR_API_KEY 是否设置，没有设置则提示
if [ -z "$VULTR_API_KEY" ]; then
    echo "VULTR_API_KEY is not set，please get VULTR_API_KEY at : https://my.vultr.com/settings/#settingsapi , create it"
    echo "click copy button,and input at here"
    # 让输入
    read -p "Please enter VULTR_API_KEY: " VULTR_API_KEY
    # 设置为永久的环境变量
    echo "export VULTR_API_KEY=$VULTR_API_KEY" >> ~/.profile
    source ~/.profile
    echo "VULTR_API_KEY has save at ~/.profile,you can change it anytime"
    echo "------------------------------------------"
fi

vultr-cli instance list | grep  'Debian 11 x64 (bullseye)' | awk '{print $1}' | xargs vultr-cli instance delete
