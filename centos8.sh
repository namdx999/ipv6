#!/bin/sh

# Get the IP addresses and ports
IP4=$(curl -4 -s icanhazip.com)
IP6=$(curl -6 -s icanhazip.com | cut -f1-4 -d':')
FIRST_PORT=10000
LAST_PORT=$(($FIRST_PORT + $COUNT))

# Create the data file
echo "" > data.txt
for port in $(seq $FIRST_PORT $LAST_PORT); do
    echo "$(random)/$(random)/$IP4/$port/$(gen64 $IP6)" >> data.txt
done

# Install the necessary packages
yum -y install gcc net-tools bsdtar zip make

# Generate the configuration file for 3proxy
cat <<EOF > 3proxy.cfg
daemon
maxconn 2000
nserver 1.1.1.1
nserver 8.8.4.4
nserver 2001:4860:4860::8888
nserver 2001:4860:4860::8844
nscache 65536
timeouts 1 5 30 60 180 1800 15 60
setgid 65535
setuid 65535
stacksize 6291456
flush
auth strong
users $(awk -F "/" 'BEGIN{ORS="";} {print $1 ":CL:" $2 " "}' data.txt)
$(awk -F "/" '{print "auth strong\n" \
"allow " $1 "\n" \
"proxy -6 -n -a -p" $4 " -i" $3 " -e"$5"\n" \
"flush\n"}' data.txt)
EOF

# Start the 3proxy server
/usr/local/etc/3proxy/bin/3proxy /usr/local/etc/3proxy/3proxy.cfg &

# Create the proxy user file
cat <<EOF > proxy.txt
$(awk -F "/" '{print $3 ":" $4 ":" $1 ":" $2 }' data.txt)
EOF

# Upload the proxy file
zip --password $PASS proxy.zip proxy.txt
URL=$(curl -s --upload-file proxy.zip https://transfer.sh/proxy.zip)

# Notify the user
echo "Proxy is ready! Format IP:PORT"
echo "Download zip archive from: ${URL}"
echo "Password: ${PASS}"
