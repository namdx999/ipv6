#!/bin/sh

# Hàm tạo chuỗi ngẫu nhiên
random() {
  tr </dev/urandom -dc A-Za-z0-9 | head -c5
  echo
}

# Mảng ký tự để sinh IP ngẫu nhiên  
array=(1 2 3 4 5 6 7 8 9 0 a b c d e f)

# Hàm sinh IP IPv6 ngẫu nhiên 
gen64() {
  ip64() {
    echo "${array[$RANDOM % 16]}${array[$RANDOM % 16]}${array[$RANDOM % 16]}${array[$RANDOM % 16]}"
  }

  echo "$1:$(ip64):$(ip64):$(ip64):$(ip64)"
}

# Hàm cài đặt 3proxy
install_3proxy() {

  # Cài gói cần thiết
  yum install -y gcc net-tools bsdtar make unzip

  # Tải và giải nén 3proxy
  URL=https://github.com/z3APA3A/3proxy/archive/0.9.3.tar.gz
  wget -qO- $URL | bsdtar -xvf-

  # Biên dịch và cài đặt
  cd 3proxy-0.9.3
  make -f Makefile.Linux
  make install

  # Tạo thư mục cấu hình
  mkdir -p /usr/local/etc/3proxy/{bin,logs,stat}

  # Copy binary 3proxy vào thư mục bin
  cp /usr/local/bin/3proxy /usr/local/etc/3proxy/bin/

  # Tạo systemd service 
  cat > /etc/systemd/system/3proxy.service <<EOF
[Unit]
Description=3Proxy

[Service] 
ExecStart=/usr/local/bin/3proxy /usr/local/etc/3proxy.cfg
Restart=always

[Install]
WantedBy=multi-user.target
EOF

  # Enable service 3proxy
  systemctl enable 3proxy

  echo "3proxy installed successfully!"

}

# Hàm tạo cấu hình 3proxy
gen_3proxy_conf() {
  
  cat <<EOF > /usr/local/etc/3proxy.cfg 
daemon
maxconn 2000
...

$(awk -F "/" '{print "allow " \\
           "proxy -6 -n -a -p" $2 " -i" $1 "\\n" \\
           "flush\\n"}' ${WORKDIR}/proxy_data.txt)  
EOF

}

# Hàm sinh dữ liệu proxy (ip và port)
gen_proxy_data() {

  rm -f ${WORKDIR}/proxy_data.txt

  seq $START_PORT $END_PORT | while read port; do
    echo "$PROXY_IP/$port/" >> ${WORKDIR}/proxy_data.txt
  done

}

# Hàm tạo file proxy.txt
gen_proxy_file() {

  awk -F "/" '{print $1 "|" $2}' ${WORKDIR}/proxy_data.txt > ${WORKDIR}/proxy.txt

} 

# Hàm nén và upload proxy file
upload_proxy_file() {

  cd ${WORKDIR}

  ZIP_PASS=$(random) 

  zip --password ${ZIP_PASS} proxy.zip proxy.txt

  UPLOAD_LINK=$(curl --upload-file proxy.zip https://transfer.sh/proxy.zip)

  echo "Proxy file download link: ${UPLOAD_LINK}"
  echo "Unzip password: ${ZIP_PASS}"  

}

# Thiết lập các biến cần thiết
WORKDIR=/root/proxy
mkdir -p ${WORKDIR}

PROXY_IP=$(curl -6 icanhazip.com | cut -f1-4 -d':')

START_PORT=10000
END_PORT=15000

# Cài đặt 3proxy
install_3proxy

# Sinh dữ liệu proxy
gen_proxy_data

# Tạo cấu hình 3proxy
gen_3proxy_conf

# Tạo file proxy.txt
gen_proxy_file  

# Nén và upload proxy file
upload_proxy_file

# Khởi động 3proxy
systemctl start 3proxy

echo "Proxy IPv6 generation completed!"
