#!/usr/bin/env bash
PATH=/bin:/sbin:/usr/bin:/usr/sbin:/usr/local/bin:/usr/local/sbin:~/bin
export PATH

zhenxun_bot_dir="/opt/zhenxun_bot"
zhenxun_url="https://ghproxy.com/github.com/HibiKier/zhenxun_bot.git"
work_dir="/opt"
python_v="python3.8"
which python3.9 && python_v="python3.9"
sh_ver="1.0.2"

Green_font_prefix="\033[32m" && Red_font_prefix="\033[31m" && Red_background_prefix="\033[41;37m" && Font_color_suffix="\033[0m"
Info="${Green_font_prefix}[信息]${Font_color_suffix}"
Error="${Red_font_prefix}[错误]${Font_color_suffix}"
Tip="${Green_font_prefix}[注意]${Font_color_suffix}"

#检查系统
check_sys() {
    if [[ -f /etc/redhat-release ]]; then
        release="centos"
    elif grep -q -E -i "debian" /etc/issue; then
        release="debian" 
    elif grep -q -E -i "ubuntu" /etc/issue; then
        release="ubuntu"
    elif grep -q -E -i "centos|red hat|redhat" /etc/issue; then
        release="centos"
    elif grep -q -E -i "Arch|Manjaro" /etc/issue; then
        release="archlinux"
    elif grep -q -E -i "debian" /proc/version; then
        release="debian"
    elif grep -q -E -i "ubuntu" /proc/version; then
        release="ubuntu"
    elif grep -q -E -i "centos|red hat|redhat" /proc/version; then
        release="centos"
    else
        echo -e "zhenxun_bot 暂不支持该Linux发行版" && exit 1
    fi
    bit=$(uname -m)
}

check_installed_zhenxun_status() {
  [[ ! -e "${work_dir}/zhenxun_bot/bot.py" ]] && echo -e "${Error} zhenxun_bot 没有安装，请检查 !" && exit 1
}

check_installed_cqhttp_status() {
  [[ ! -e "${work_dir}/go-cqhttp/go-cqhttp" ]] && echo -e "${Error} go-cqhttp 没有安装，请检查 !" && exit 1
}

check_pid_zhenxun() {
  #PID=$(ps -ef | grep "sergate" | grep -v grep | grep -v ".sh" | grep -v "init.d" | grep -v "service" | awk '{print $2}')
  PID=$(pgrep -f "bot.py")
}

check_pid_cqhttp() {
  #PID=$(ps -ef | grep "sergate" | grep -v grep | grep -v ".sh" | grep -v "init.d" | grep -v "service" | awk '{print $2}')
  PID=$(pgrep -f "go-cqhttp")
}

Set_pip_Mirror() {
  echo -e "${Info} 请输入要选择的pip下载源，默认使用官方源，中国大陆建议选择清华源
  ${Green_font_prefix} 1.${Font_color_suffix} 默认
  ${Green_font_prefix} 2.${Font_color_suffix} 清华源"
  read -erp "请输入数字 [1-2], 默认为 1:" mirror_num
  [[ -z "${mirror_num}" ]] && mirror_num=1
  rm -rf ~/.config/pip
  [[ ${mirror_num} == 2 ]] && sudo pip config set global.index-url https://pypi.tuna.tsinghua.edu.cn/simple
}

Installation_dependency() {
    if [[ ${release} == "centos" ]]; then
        sudo yum -y update
        sudo yum install -y git fontconfig mkfontscale epel-release wget vim curl zlib-devel bzip2-devel openssl-devel ncurses-devel sqlite-devel readline-devel tk-devel gcc make libffi-devel
        if  ! which python3.8 && ! which python3.9;then
            wget https://mirrors.huaweicloud.com/python/3.9.10/Python-3.9.10.tgz -O /tmp/Python-3.9.10.tgz && \
                tar -zxf /tmp/Python-3.9.10.tgz -C /tmp/ &&\
                cd /tmp/Python-3.9.10 && \
                ./configure && \
                make -j $(cat /proc/cpuinfo |grep "processor"|wc -l) && \
                sudo make altinstall
            python_v="pythono3.9"
        fi
        which python3.9 || ${python_v} <(curl -s -L https://bootstrap.pypa.io/get-pip.py)
        sudo rpm -v --import http://li.nux.ro/download/nux/RPM-GPG-KEY-nux.ro
        sudo rpm -Uvh http://li.nux.ro/download/nux/dextop/el7/x86_64/nux-dextop-release-0-5.el7.nux.noarch.rpm
        sudo yum install -y https://download.postgresql.org/pub/repos/yum/reporpms/EL-7-x86_64/pgdg-redhat-repo-latest.noarch.rpm
        sudo yum install -y postgresql13-server ffmpeg ffmpeg-devel atk at-spi2-atk cups-libs libxkbcommon libXcomposite libXdamage libXrandr mesa-libgbm gtk3
        sudo /usr/pgsql-13/bin/postgresql-13-setup initdb
        sudo systemctl enable postgresql-13
        sudo systemctl start postgresql-13
        cat > /tmp/sql.sql <<-EOF
CREATE USER zhenxun WITH PASSWORD 'zxpassword';
CREATE DATABASE zhenxun OWNER zhenxun;
EOF
        su postgres -c "psql -f /tmp/sql.sql"
    elif [[ ${release} == "debian" ]]; then
        sudo apt-get update
        sudo apt-get install -y wget ttf-wqy-zenhei xfonts-intl-chinese wqy* build-essential zlib1g-dev libncurses5-dev libgdbm-dev libnss3-dev libssl-dev libreadline-dev libffi-dev
        if  ! which python3.8 && ! which python3.9;then
            wget https://mirrors.huaweicloud.com/python/3.9.10/Python-3.9.10.tgz -O /tmp/Python-3.9.10.tgz && \
                tar -zxf /tmp/Python-3.9.10.tgz -C /tmp/ &&\
                cd /tmp/Python-3.9.10 && \
                ./configure && \
                make -j $(cat /proc/cpuinfo |grep "processor"|wc -l) && \
                sudo make altinstall
            python_v="python3.9"
        fi
        sudo apt-get install -y \
            vim \
            wget \
            git \
            ffmpeg \
            postgresql \
            postgresql-contrib \
            libgl1 \
            libglib2.0-0 \
            libnss3 \
            libatk1.0-0 \
            libatk-bridge2.0-0 \
            libcups2 \
            libxkbcommon0 \
            libxcomposite1 \
            libxrandr2 \
            libgbm1 \
            libgtk-3-0 \
            libasound2
        which python3.9 || ${python_v} <(curl -s -L https://bootstrap.pypa.io/get-pip.py)
        /etc/init.d/postgresql start
        cat > /tmp/sql.sql <<-EOF
CREATE USER zhenxun WITH PASSWORD 'zxpassword';
CREATE DATABASE zhenxun OWNER zhenxun;
EOF
        su postgres -c "psql -f /tmp/sql.sql"
    elif [[ ${release} == "ubuntu" ]]; then
        sudo apt-get update
        sudo apt-get install -y software-properties-common ttf-wqy-zenhei ttf-wqy-microhei fonts-arphic-ukai fonts-arphic-uming
        sudo fc-cache -f -v
        echo -e "\n" | sudo add-apt-repository ppa:deadsnakes/ppa
        if  ! which python3.8 && ! which python3.9;then
            sudo apt-get install -y python3.9
            python_v="python3.9"
        fi
        sudo apt-get install -y \
            vim \
            wget \
            git \
            ffmpeg \
            postgresql \
            postgresql-contrib \
            libgl1 \
            libglib2.0-0 \
            libnss3 \
            libatk1.0-0 \
            libatk-bridge2.0-0 \
            libcups2 \
            libxkbcommon0 \
            libxcomposite1 \
            libxrandr2 \
            libgbm1 \
            libgtk-3-0 \
            libasound2
        which python3.9 || ${python_v} <(curl -s -L https://bootstrap.pypa.io/get-pip.py)
        /etc/init.d/postgresql start
        cat > /tmp/sql.sql <<-EOF
CREATE USER zhenxun WITH PASSWORD 'zxpassword';
CREATE DATABASE zhenxun OWNER zhenxun;
EOF
        su postgres -c "psql -f /tmp/sql.sql"
    elif [[ ${release} == "archlinux" ]]; then
        pacman -Sy python python-pip unzip --noconfirm
    fi
    [[ ! -e /usr/bin/python3 ]] && ln -s /usr/bin/${python_v} /usr/bin/python3
}

Download_zhenxun_bot() {
    cd "/tmp" || exit 1
    echo -e "${Info} 开始下载最新版 zhenxun_bot ..."
    git clone "${zhenxun_url}" || (echo -e "${Error} zhenxun_bot 下载失败 !" && exit 1)
    echo -e "${Info} 开始下载最新版 go-cqhttp ..."
    gocq_version=$(wget -qO- -t1 -T2 "https://api.github.com/repos/Mrs4s/go-cqhttp/releases/latest" | grep "tag_name" | head -n 1 | awk -F ":" '{print $2}' | sed 's/\"//g;s/,//g;s/ //g')
    wget -qO- "https://github.com/Mrs4s/go-cqhttp/releases/download/${gocq_version}/go-cqhttp_$(uname -s)_amd64.tar.gz" -O go-cqhttp.tar.gz || (echo -e "${Error} go-cqhttp 下载失败 !" && exit 1)
    cd "${work_dir}" || exit 1
    mv "/tmp/zhenxun_bot" ./
    mkdir -p "go-cqhttp"
    tar -zxf "/tmp/go-cqhttp.tar.gz" -C ./go-cqhttp/
    echo -e "${info} 开始下载抽卡相关资源..."
    if [[ -e "${work_dir}/zhenxun_bot/draw_card" ]]; then
        echo -e "${info} 抽卡资源文件已存在，跳过下载"
    else
        SOURCE_URL=https://pan.yropo.top/source/zhenxun/
        wget ${SOURCE_URL}data_draw_card.tar.gz -qO ~/.cache/data_draw_card.tar.gz \
            && wget ${SOURCE_URL}img_draw_card.tar.gz -qO ~/.cache/img_draw_card.tar.gz \
            && tar -zxf ~/.cache/data_draw_card.tar.gz -C ${work_dir}/zhenxun_bot/ \
            && tar -zxf ~/.cache/img_draw_card.tar.gz -C ${work_dir}/zhenxun_bot/ \
            && rm -rf ~/.cache/*.tar.gz
    fi
}

Set_config_admin() {
    echo -e "${Info} 请输入管理员QQ账号(也就超级用户账号):[QQ]"
    read -erp "管理员QQ:" admin_qq
    [[ -z "$admin_qq" ]] && admin_qq=""
    cd ${work_dir}/zhenxun_bot && sed -i "s/SUPERUSERS.*/SUPERUSERS=[\"$admin_qq\"]/g" .env.dev || echo -e "${Error}配置文件不存在！请检查zhenxun_bot是否安装正确!"
    echo -e "${info} 设置成功!管理员QQ: ${admin_qq}"
}

Set_config_bot() {
    echo -e "${Info} 请输入Bot QQ账号:[QQ]"
    read -erp "Bot QQ:" bot_qq
    [[ -z "$bot_qq" ]] && bot_qq=""
    cd ${work_dir}/go-cqhttp && sed -i "s/uin:.*/uin: $bot_qq/g" config.yml || echo -e "${Error}配置文件不存在！请检查go-cqhttp是否安装正确!"
    echo -e "${info} 设置成功!Bot QQ: ${bot_qq}"
}

Set_config() {
    if [[ -e "${work_dir}/go-cqhttp/config.yml" ]]; then
        echo -e "${info} go-cqhttp 配置文件已存在，跳过生成"
    else
        cd ${work_dir}/go-cqhttp && echo -e "3\n" | ./go-cqhttp > /dev/null 2>&1
        sudo sed -i 's|universal:.*|universal: ws://localhost:8080/onebot/v11/ws|g' config.yml
    fi
    Set_config_bot
    Set_config_admin
    echo -e "${Info} 开始设置 PostgreSQL 连接语句..."
    sed -i 's|bind.*|bind: str = "postgresql://zhenxun:zxpassword@localhost:5432/zhenxun"|g' configs/config.py
    echo -e "${Info} 开始下载 config.yaml 文件..."
    wget https://cdn.jsdelivr.net/gh/AkashiCoin/zhenxun_bot-deploy/config.yaml -O configs/config.yaml
}

Start_zhenxun_bot() {
    check_installed_zhenxun_status
    check_pid_zhenxun
    [[ -n ${PID} ]] && echo -e "${Error} zhenxun_bot 正在运行，请检查 !" && exit 1
    cd ${work_dir}/zhenxun_bot
    nohup ${python_v} bot.py >> zhenxun_bot.log 2>&1 &
    echo -e "${Info} zhenxun_bot 开始运行..."
}

Stop_zhenxun_bot() {
    check_installed_zhenxun_status
    check_pid_zhenxun
    [[ -z ${PID} ]] && echo -e "${Error} zhenxun_bot 没有运行，请检查 !" && exit 1
    kill -9 ${PID}
    echo -e "${Info} zhenxun_bot 已停止运行..."
}

Restart_zhenxun_bot() {
    Stop_zhenxun_bot
    Start_zhenxun_bot
}

View_zhenxun_log() {
    tail -f -n 100 ${work_dir}/zhenxun_bot/zhenxun_bot.log
}

Set_config_zhenxun() {
    vim ${work_dir}/zhenxun_bot/configs/config.yaml
}

Start_cqhttp() {
    check_installed_cqhttp_status
    check_pid_cqhttp
    [[ -n ${PID} ]] && echo -e "${Error} go-cqhttp 正在运行，请检查 !" && exit 1
    cd ${work_dir}/go-cqhttp
    nohup ./go-cqhttp -faststart >> go-cqhttp.log 2>&1 &
    echo -e "${Info} go-cqhttp 开始运行..."
    echo -e "${info} 请扫描二维码登录 bot，bot 账号登录完成后，使用Ctrl + C退出 !"
    sleep 2
}

Stop_cqhttp() {
    check_installed_cqhttp_status
    check_pid_cqhttp
    [[ -z ${PID} ]] && echo -e "${Error} cqhttp 没有运行，请检查 !" && exit 1
    kill -9 ${PID}
    echo -e "${Info} go-cqhttp 停止运行..."
}

Restart_cqhttp() {
    Stop_cqhttp
    Start_cqhttp
}

View_cqhttp_log() {
    tail -f -n 100 ${work_dir}/go-cqhttp/go-cqhttp.log
}

Set_config_zhenxun() {
    vim ${work_dir}/go-cqhttp/config.yml
}

Exit_cqhttp() {
    cd ${work_dir}/go-cqhttp
    rm -f session.token
    echo -e "${Info} go-cqhttp 账号已退出..."
    Stop_cqhttp
    sleep 3
    menu_cqhttp
}

Set_dependency() {
    cd ${work_dir}/zhenxun_bot
    Set_pip_Mirror
    ${python_v} -m pip install --ignore-installed -r https://cdn.jsdelivr.net/gh/AkashiCoin/zhenxun_bot-deploy/requirements.txt
    playwright install chromium
}

Install_zhenxun_bot() {
    [[ -e "${zhenxun_bot}/bot.py" ]] && echo -e "${Error} 检测到 zhenxun_bot 已安装 !" && exit 1
    check_sys
    if [[ ${release} == "centos" ]]; then
        if grep "6\..*" /etc/redhat-release | grep -i "centos" | grep -v "{^6}\.6" >/dev/null; then
        echo -e "${Info} 检测到你的系统为 CentOS6，该系统自带的 Python2.6 版本过低，会导致无法运行客户端，如果你有能力升级为 Python2.7或以上版本，那么请继续(否则建议更换系统)：[y/N]"
        read -erp "(默认: N 继续安装):" sys_centos6
        [[ -z "$sys_centos6" ]] && sys_centos6="n"
        if [[ "${sys_centos6}" == [Nn] ]]; then
            echo -e "\n${Info} 已取消...\n"
            exit 1
        fi
        fi
    fi
    echo -e "${Info} 开始安装/配置 依赖..."
    Installation_dependency
    echo -e "${Info} 开始下载/安装..."
    Download_zhenxun_bot
    echo -e "${Info} 开始设置 用户配置..."
    Set_config
    echo -e "${Info} 开始配置 zhenxun_bot 环境..."
    Set_dependency
    if [[ ${release} == "centos" ]]; then
        echo -e "${Info} CentOS 中文字体设置..."
        sudo mkdir -p /usr/share/fonts/chinese
        sudo cp -r /opt/zhenxun_bot/resources/font /usr/share/fonts/chinese
        cd /usr/share/fonts/chinese && mkfontscale
    fi
    echo -e "${Info} 开始运行 zhenxun_bot..."
    Start_zhenxun_bot
    echo -e "${Info} 开始运行 go-cqhttp..."
    Start_cqhttp
    View_cqhttp_log
}

menu_cqhttp() {
  echo && echo -e "  go-cqhttp 一键安装管理脚本 ${Red_font_prefix}[v${sh_ver}]${Font_color_suffix}
  -- Sakura | github.com/AkashiCoin --
 ${Green_font_prefix} 0.${Font_color_suffix} 升级脚本
 ————————————
 ${Green_font_prefix} 1.${Font_color_suffix} 安装 zhenxun_bot + go-cqhttp
————————————
 ${Green_font_prefix} 2.${Font_color_suffix} 启动 go-cqhttp
 ${Green_font_prefix} 3.${Font_color_suffix} 停止 go-cqhttp
 ${Green_font_prefix} 4.${Font_color_suffix} 重启 go-cqhttp
————————————
 ${Green_font_prefix} 5.${Font_color_suffix} 设置 bot QQ账号
 ${Green_font_prefix} 6.${Font_color_suffix} 修改 go-cqhttp 配置文件
 ${Green_font_prefix} 7.${Font_color_suffix} 查看 go-cqhttp 日志
————————————
 ${Green_font_prefix} 8.${Font_color_suffix} 退出 go-cqhttp 账号
 ${Green_font_prefix}10.${Font_color_suffix} 切换为 zhenxun_bot 菜单" && echo
  if [[ -e "${work_dir}/go-cqhttp/go-cqhttp" ]]; then
    check_pid_cqhttp
    if [[ -n "${PID}" ]]; then
      echo -e " 当前状态: go-cqhttp ${Green_font_prefix}已安装${Font_color_suffix} 并 ${Green_font_prefix}已启动${Font_color_suffix}"
    else
      echo -e " 当前状态: go-cqhttp ${Green_font_prefix}已安装${Font_color_suffix} 但 ${Red_font_prefix}未启动${Font_color_suffix}"
    fi
  else
    if [[ -e "${file}/go-cqhttp/go-cqhttp" ]]; then
      check_pid_cqhttp
      if [[ -n "${PID}" ]]; then
        echo -e " 当前状态: go-cqhttp ${Green_font_prefix}已安装${Font_color_suffix} 并 ${Green_font_prefix}已启动${Font_color_suffix}"
      else
        echo -e " 当前状态: go-cqhttp ${Green_font_prefix}已安装${Font_color_suffix} 但 ${Red_font_prefix}未启动${Font_color_suffix}"
      fi
    else
      echo -e " 当前状态: go-cqhttp ${Red_font_prefix}未安装${Font_color_suffix}"
    fi
  fi
  echo
  read -erp " 请输入数字 [0-10]:" num
  case "$num" in
  0)
    Update_Shell
    ;;
  1)
    Install_zhenxun_bot
    ;;
  2)
    Start_cqhttp
    ;;
  3)
    Stop_cqhttp
    ;;
  4)
    Restart_cqhttp
    ;;
  5)
    Set_config_bot
    ;;
  6)
    Set_config_cqhttp
    ;;
  7)
    View_cqhttp_log
    ;;  
  8)
    Exit_cqhttp
    ;;
  10)
    menu_zhenxun
    ;;
  *)
    echo "请输入正确数字 [0-10]"
    ;;
  esac
}

menu_zhenxun() {
  echo && echo -e "  zhenxun_bot 一键安装管理脚本 ${Red_font_prefix}[v${sh_ver}]${Font_color_suffix}
  -- Sakura | github.com/AkashiCoin --
 ${Green_font_prefix} 0.${Font_color_suffix} 升级脚本
 ————————————
 ${Green_font_prefix} 1.${Font_color_suffix} 安装 zhenxun_bot + go-cqhttp
————————————
 ${Green_font_prefix} 2.${Font_color_suffix} 启动 zhenxun_bot
 ${Green_font_prefix} 3.${Font_color_suffix} 停止 zhenxun_bot
 ${Green_font_prefix} 4.${Font_color_suffix} 重启 zhenxun_bot
————————————
 ${Green_font_prefix} 5.${Font_color_suffix} 设置 管理员账号
 ${Green_font_prefix} 6.${Font_color_suffix} 修改 zhenxun_bot 配置文件
 ${Green_font_prefix} 7.${Font_color_suffix} 查看 zhenxun_bot 日志
————————————
 ${Green_font_prefix}10.${Font_color_suffix} 切换为 go-cqhttp 菜单" && echo
  if [[ -e "${work_dir}/zhenxun_bot/bot.py" ]]; then
    check_pid_zhenxun
    if [[ -n "${PID}" ]]; then
      echo -e " 当前状态: zhenxun_bot ${Green_font_prefix}已安装${Font_color_suffix} 并 ${Green_font_prefix}已启动${Font_color_suffix}"
    else
      echo -e " 当前状态: zhenxun_bot ${Green_font_prefix}已安装${Font_color_suffix} 但 ${Red_font_prefix}未启动${Font_color_suffix}"
    fi
  else
    if [[ -e "${file}/zhenxun_bot/bot.py" ]]; then
      check_pid_zhenxun
      if [[ -n "${PID}" ]]; then
        echo -e " 当前状态: zhenxun_bot ${Green_font_prefix}已安装${Font_color_suffix} 并 ${Green_font_prefix}已启动${Font_color_suffix}"
      else
        echo -e " 当前状态: zhenxun_bot ${Green_font_prefix}已安装${Font_color_suffix} 但 ${Red_font_prefix}未启动${Font_color_suffix}"
      fi
    else
      echo -e " 当前状态: zhenxun_bot ${Red_font_prefix}未安装${Font_color_suffix}"
    fi
  fi
  echo
  read -erp " 请输入数字 [0-10]:" num
  case "$num" in
  0)
    Update_Shell
    ;;
  1)
    Install_zhenxun_bot
    ;;
  2)
    Start_zhenxun_bot
    ;;
  3)
    Stop_zhenxun_bot
    ;;
  4)
    Restart_zhenxun_bot
    ;;
  5)
    Set_config_admin
    ;;
  6)
    Set_config_zhenxun
    ;;
  7)
    View_zhenxun_log
    ;;
  10)
    menu_cqhttp
    ;;
  *)
    echo "请输入正确数字 [0-10]"
    ;;
  esac
}
menu_zhenxun