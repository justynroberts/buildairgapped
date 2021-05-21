#!/bin/bash
#
# Airgap installer. Simply grabs and builds latest console RPM, Self hosted Containers, Agent Containers & Leader Elector
#
#
#
set +x
clear
echo -e "\e[32m--------------------------------------------\e[0m"
echo -e "\e[32mAirgap Builder. Please enter customer name\e[31m"
read customer
echo -e "\e[32mPlease enter agent/download key\e[31m"
read key
echo -e "\e[32m--------------------------------------------\e[0m"
echo -e "\e[32mPlease enter license sales key\e[31m"
read saleskey
echo -e "\e[32m--------------------------------------------\e[0m"
​
cat >/etc/yum.repos.d/Instana-Product.repo <<EOF
[instana-product]
name=Instana-Product
baseurl=https://self-hosted.instana.io/rpm/release/product/rpm/generic/x86_64/Packages
enabled=1
gpgcheck=1
repo_gpgcheck=1
gpgkey=https://self-hosted.instana.io/signing_key.gpg
priority=5
sslverify=1
EOF
yum makecache -y fast
​
if [[ ! -d build ]]
then
    mkdir build
fi
rm -f build/*.*
​
echo -e "\e[32mGrabbing Console RPM\e[0m"
yum update instana-console
yumdownloader  instana-console
mv *.rpm build/
​
echo -e "\e[32mExporting onprem containers\e[0m"
instana images export -k $key
mv export* build/
​
echo -e "\e[32mExporting agent containers\e[0m"
docker login https://containers.instana.io -u="_" -p $key
docker pull containers.instana.io/instana/release/agent/static:latest
docker pull containers.instana.io/instana/release/agent/dynamic:latest
docker pull instana/leader-elector:0.5.4
​
sudo docker save containers.instana.io/instana/release/agent/static:latest > instana-static-container-agent.tar
sudo docker save containers.instana.io/instana/release/agent/dynamic:latest > instana-dynamic-container-agent.tar
sudo docker save instana/leader-elector:0.5.4 > leader-elector-container.tar
mv *.tar build/
​
echo -e "\e[32mLicense for" $customer "\e[0m"
instana license download --key=$saleskey
mv license build/
​
echo -e "\e[32mPacking Files for" $customer "\e[0m"
tar -cvf $customer-airgapped-files.tar build/*.*
​
echo -e "\e[32mLicense Key for" $customer "\e[0m"
echo -e "\e[32mDone....\e[0m"
