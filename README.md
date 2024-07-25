# scripts 
一些实用脚本

# vpn-create-vultr.sh 
一键创建vultr的节点，需要注册并有钱，注意每次都会销毁之前的一个节点，销毁语句为
vultr-cli instance list | grep  'Debian 11 x64 (bullseye)' | awk '{print $1}' | xargs vultr-cli instance delete

# vpn-delete-vultr.sh
删除一个节点，删除语句也是上面那个
