#! /bin/bash

# 判断expect是否安装
if ! command -v expect &> /dev/null; then
    echo "expect is not installed, installing..."
    apt-get install -y expect
    echo "------------------------------------------"
fi

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

# 删除之前的实例
vultr-cli instance list | grep  'Debian 11 x64 (bullseye)' | awk '{print $1}' | xargs vultr-cli instance delete
# 创建实例
# ssh key 获取： 打开account-> ssh keys -> 点击编辑 -> url中就包括 https://my.vultr.com/sshkeys/manage/?id={VULTR_SSH_KEY}
# os 477 Debian 11 x64 (bullseye) 
vultr-cli instance create --region ewr --plan vc2-1c-0.5gb --os 477 -s $VULTR_SSH_KEY
# 循环直到 vultr-cli instance list | grep 'Debian 11 x64 (bullseye)' | awk  '{print $2}' 有值
while [ -z "$(vultr-cli instance list | grep 'Debian 11 x64 (bullseye)' | awk  '{print $2}')" ]; do
    sleep 1
done 

# 获取ip 
instanceip=$(vultr-cli instance list | grep 'Debian 11 x64 (bullseye)' | awk  '{print $2}')
echo "new instance ip is : "$instanceip
# 移除known_hosts
ssh-keygen -f "/root/.ssh/known_hosts" -R $instanceip
echo "start try ping ..."
# 循环ping 直到ping通
while ! ping -c 1 $instanceip &> /dev/null; do
    echo "try ping ..."
    sleep 1
done

# 循环直到 ssh通畅
echo "start try ssh ..."
while ! ssh -o StrictHostKeyChecking=no root@$instanceip "echo 'test'" &> /dev/null; do
    echo "try ssh ..."
    sleep 1
done
echo "------------------------------------------"
# 输出第一次登录
echo "first login"
expect << EOF
spawn ssh root@$instanceip
expect "Are you sure you want to continue connecting"
send "yes\r"
expect "root@vultr:~#"
send "exit\r"
EOF
echo "first finshed"

echo "------------------------------------------"
# 远程执行 source <(curl -sL https://multi.netlify.app/v2ray.sh) --zh > v2ray.log
echo "start create v2ray"
ssh root@$instanceip 'source <(curl -sL https://multi.netlify.app/v2ray.sh) --zh' | grep vmess > /tmp/vmess.txt
echo "finish create v2ray"
echo "------------------------------------------"
echo "start up speed"
ssh root@$instanceip "wget -N --no-check-certificate 'https://raw.githubusercontent.com/chiakge/Linux-NetSpeed/master/tcp.sh' && chmod +x tcp.sh"

# 启动加速
expect << EOF
spawn ssh root@$instanceip
expect "root@*"
send "./tcp.sh\r"
expect ":"
send "4\r"
sleep 2
send "exit\r"
EOF

expect << EOF
spawn ssh root@$instanceip
expect "root@*"
send "./tcp.sh\r"
expect ":"
send "10\r"
expect ":"
send "y\r"
sleep 2
send "exit\r"
EOF

echo "end up speed"
echo "------------------------------------------"

# cat远端的v2ray.log
cat /tmp/vmess.txt 
