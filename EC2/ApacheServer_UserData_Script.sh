#!/bin/bash
# Update packages
sudo dnf update -y

# Install Apache (httpd in Amazon Linux)
sudo dnf install httpd -y

# Enable Apache to start on boot
sudo systemctl enable httpd
sudo systemctl start httpd

# Get instance IP and hostname
IP=$(hostname -I | awk '{print $1}')
HOSTNAME=$(hostname)

# Create HTML file with styling
sudo bash -c "cat > /var/www/html/index.html <<EOL
<!DOCTYPE html>
<html>
<head>
<title>Server Info</title>
<style>
body {
    background-color: #1e1e1e;
    color: #ffffff;
    font-family: Arial, sans-serif;
    text-align: center;
    padding-top: 50px;
}
.container {
    background-color: #2e2e2e;
    padding: 20px;
    border-radius: 10px;
    display: inline-block;
    box-shadow: 0px 0px 20px rgba(0,0,0,0.5);
}
h1 {
    color: #4CAF50;
}
p {
    font-size: 18px;
}
</style>
</head>
<body>
<div class='container'>
    <h1>Server Information</h1>
    <p><strong>IP Address:</strong> $IP</p>
    <p><strong>Hostname:</strong> $HOSTNAME</p>
</div>
</body>
</html>
EOL"

# Restart Apache to ensure changes are applied
sudo systemctl restart httpd
