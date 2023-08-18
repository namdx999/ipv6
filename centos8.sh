#!/bin/sh

# Cài đặt các gói cần thiết
yum -y install gcc net-tools bsdtar zip make

# Hàm tạo chuỗi ngẫu nhiên
random() {
  tr </dev/urandom -dc A-Za-z0-9 | head -c5
  echo
}

# Cài đặt 3proxy
URL="https://github.com/z3APA3A/3proxy/archive/0.9.3.tar.gz"
wget -qO- $URL | bsdtar -xvf-
cd 3proxy-0.9.3
make -f Makefile.Linux
mv bin/3proxy /usr/local/bin/

# Tạo thư mục làm việc
WORKDIR=/root/proxy
mkdir -p $WORKDIR 

# Sinh dữ liệu proxy 
IP6=$(curl -6 icanhazip.com | cut -f1-4 -d':') 
seq 10000 10500 | while read port; do
  echo "$IP6/$port/" >> $WORKDIR/data.txt
done

# Tạo cấu hình 3proxy
cat <<EOF > /usr/local/etc/3proxy.cfg
daemon
$(awk -F "/" '{print "allow proxy -6 -n -p" $2 " -i" $1 "\\nflush\\n"}' $WORKDIR/data.txt)
EOF

# Tạo file proxy.txt
awk -F "/" '{print $1 "|" $2}' $WORKDIR/data.txt > $WORKDIR/proxy.txt

# Cấu hình 3proxy tự động khởi động
cat <<EOF > /etc/systemd/system/3proxy.service
[Unit]
Description=3Proxy

[Service]
ExecStart=/usr/local/bin/3proxy /usr/local/etc/3proxy.cfg
Restart=always

[Install]  
WantedBy=multi-user.target
EOF

systemctl enable 3proxy

# Khởi động 3proxy
systemctl start 3proxy

echo "Proxy IPv6 đã được tạo tại $WORKDIR/proxy.txt"