#!/bin/bash

apt update

echo "install dotnet"
apt install -y aspnetcore-runtime-8.0
apt install -y dotnet-sdk-8.0

echo "install git and set the configuration"
apt install git -y
git config --global user.name "yosef zaher"
git config --global user.email "zaheryosef72@gmail.com"

cd /home/ubuntu
echo "git clone"
sudo -u ubuntu git clone https://github.com/yosefzaher/dot-net-http-server.git
cd dot-net-http-server

#build the dot net service
echo "dotnet build"
echo 'DOTNET_CLI_HOME=/temp' >> /etc/environment
export DOTNET_CLI_HOME=/temp
dotnet publish -c Release --self-contained=false --runtime linux-x64

# Making a Http Service From the .NET Project
echo "Making Ta New Service"
cat >/etc/systemd/system/http_server.service <<EOL
[Unit]
Description=.NET HTTP Server Work on Port 8002

[Service]
ExecStart=/usr/bin/dotnet /home/ubuntu/dot-net-http-server/bin/Release/net8.0/linux-x64/server.dll
SyslogIdentifier=dot-net-server
Environment=DOTNET_CLI_HOME=/tmp


[Install]
WantedBy=multi-user.target
EOL

systemctl daemon-reload
systemctl enable http_server
systemctl start http_server





