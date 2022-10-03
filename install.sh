#!/usr/bin/env bash
PATH=/bin:/sbin:/usr/bin:/usr/sbin:/usr/local/bin:/usr/local/sbin:~/bin
export PATH

update_shell_url="https://raw.githubusercontent.com/zhenxun-org/zhenxun_bot-deploy/master/install.sh"
zhenxun_url="https://github.com/HibiKier/zhenxun_bot.git"
WORK_DIR="/home"
TMP_DIR="$(mktemp -d)"
python_v="python3.8"
which python3.9 && python_v="python3.9"
sh_ver="1.0.4"
ghproxy="https://ghproxy.com/"
mirror_url="https://pypi.org/simple"

Green_font_prefix="\033[32m" && Red_font_prefix="\033[31m" && Red_background_prefix="\033[41;37m" && Font_color_suffix="\033[0m"
Info="${Green_font_prefix}[信息]${Font_color_suffix}"
Error="${Red_font_prefix}[错误]${Font_color_suffix}"
Tip="${Green_font_prefix}[注意]${Font_color_suffix}"

check_root(){
	[[ $EUID != 0 ]] && echo -e "${Error} 当前非ROOT账号(或没有ROOT权限)，无法继续操作，请更换ROOT账号或使用 ${Green_background_prefix}sudo -i${Font_color_suffix} 命令获取临时ROOT权限（执行后可能会提示输入当前账号的密码）。" && exit 1
}

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
  [[ ! -e "${WORK_DIR}/zhenxun_bot/bot.py" ]] && echo -e "${Error} zhenxun_bot 没有安装，请检查 !" && exit 1
}

check_installed_cqhttp_status() {
  [[ ! -e "${WORK_DIR}/go-cqhttp/go-cqhttp" ]] && echo -e "${Error} go-cqhttp 没有安装，请检查 !" && exit 1
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
  [[ ${mirror_num} == 2 ]] && mirror_url="https://pypi.tuna.tsinghua.edu.cn/simple"
}

Set_ghproxy() {
  echo -e "${Info} 是否使用 ghproxy 代理git相关的下载？(中国大陆建议使用)"
  read -erp "请选择 [y/n], 默认为 y:" ghproxy_check
  [[ -z "${ghproxy_check}" ]] && ghproxy_check='y'
  [[ ${ghproxy_check} == 'n' ]] && ghproxy=""
}

Installation_dependency() {
    if [[ ${release} == "centos" ]]; then
        yum -y update
        yum install -y git fontconfig mkfontscale epel-release wget vim curl zlib-devel bzip2-devel openssl-devel ncurses-devel sqlite-devel readline-devel tk-devel gcc make libffi-devel
        if  ! which python3.8 && ! which python3.9; then
            wget https://mirrors.huaweicloud.com/python/3.9.10/Python-3.9.10.tgz -O ${TMP_DIR}/Python-3.9.10.tgz && \
                tar -zxf ${TMP_DIR}/Python-3.9.10.tgz -C ${TMP_DIR}/ &&\
                cd ${TMP_DIR}/Python-3.9.10 --with-ensurepip=install && \
                ./configure && \
                make -j $(cat /proc/cpuinfo |grep "processor"|wc -l) && \
                make altinstall
            python_v="python3.9"
        fi
        ${python_v} <(curl -s -L https://bootstrap.pypa.io/get-pip.py) || echo -e "${Tip} pip 安装出错..."
        rpm -v --import http://li.nux.ro/download/nux/RPM-GPG-KEY-nux.ro
        rpm -Uvh http://li.nux.ro/download/nux/dextop/el7/x86_64/nux-dextop-release-0-5.el7.nux.noarch.rpm
        yum install -y https://download.postgresql.org/pub/repos/yum/reporpms/EL-7-x86_64/pgdg-redhat-repo-latest.noarch.rpm
        yum install -y postgresql13-server ffmpeg ffmpeg-devel atk at-spi2-atk cups-libs libxkbcommon libXcomposite libXdamage libXrandr mesa-libgbm gtk3
        /usr/pgsql-13/bin/postgresql-13-setup initdb
        systemctl enable postgresql-13
        systemctl start postgresql-13
        cat > /tmp/sql.sql <<-EOF
CREATE USER zhenxun WITH PASSWORD 'zxpassword';
CREATE DATABASE zhenxun OWNER zhenxun;
EOF
        su postgres -c "psql -f /tmp//sql.sql"
    elif [[ ${release} == "debian" ]]; then
        apt-get update
        apt-get install -y wget ttf-wqy-zenhei xfonts-intl-chinese wqy* build-essential zlib1g-dev libncurses5-dev libgdbm-dev libnss3-dev libssl-dev libreadline-dev libffi-dev
        if  ! which python3.8 && ! which python3.9;then
            wget https://mirrors.huaweicloud.com/python/3.9.10/Python-3.9.10.tgz -O ${TMP_DIR}/Python-3.9.10.tgz && \
                tar -zxf ${TMP_DIR}/Python-3.9.10.tgz -C ${TMP_DIR}/ &&\
                cd ${TMP_DIR}/Python-3.9.10 && \
                ./configure --with-ensurepip=install && \
                make -j $(cat /proc/cpuinfo |grep "processor"|wc -l) && \
                make altinstall
            python_v="python3.9"
        fi
        apt-get install -y \
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
        ${python_v} <(curl -s -L https://bootstrap.pypa.io/get-pip.py) || echo -e "${Tip} pip 安装出错..."
        /etc/init.d/postgresql start
        cat > /tmp/sql.sql <<-EOF
CREATE USER zhenxun WITH PASSWORD 'zxpassword';
CREATE DATABASE zhenxun OWNER zhenxun;
EOF
        su postgres -c "psql -f /tmp/sql.sql"
    elif [[ ${release} == "ubuntu" ]]; then
        apt-get update
        apt-get install -y software-properties-common ttf-wqy-zenhei ttf-wqy-microhei fonts-arphic-ukai fonts-arphic-uming
        fc-cache -f -v
        echo -e "\n" | add-apt-repository ppa:deadsnakes/ppa
        if  ! which python3.8 && ! which python3.9;then
            apt-get install -y python3.9-full
            python_v="python3.9"
        fi
        apt-get install -y \
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
        ${python_v} <(curl -s -L https://bootstrap.pypa.io/get-pip.py) || echo -e "${Tip} pip 安装出错..."
        /etc/init.d/postgresql start
        cat > /tmp//sql.sql <<-EOF
CREATE USER zhenxun WITH PASSWORD 'zxpassword';
CREATE DATABASE zhenxun OWNER zhenxun;
EOF
        su postgres -c "psql -f /tmp/sql.sql"
    elif [[ ${release} == "archlinux" ]]; then
        pacman -Sy python python-pip unzip --noconfirm
    fi
    [[ ! -e /usr/bin/python3 ]] && ln -s /usr/bin/${python_v} /usr/bin/python3
}

check_arch() {
  get_arch=$(arch)
  if [[ ${get_arch} == "x86_64" ]]; then 
    arch="amd64"
  elif [[ ${get_arch} == "aarch64" ]]; then
    arch="arm64"
  else
    echo -e "${Error} go-cqhttp 不支持该内核版本(${get_arch})..." && exit 1
  fi
}

Download_zhenxun_bot() {
    cd "${TMP_DIR}" || exit 1
    echo -e "${Info} 开始下载最新版 zhenxun_bot ..."
    git clone "${ghproxy}${zhenxun_url}" -b main || (echo -e "${Error} zhenxun_bot 下载失败 !" && exit 1)
    echo -e "${Info} 开始下载最新版 go-cqhttp ..."
    gocq_version=$(wget -qO- -t1 -T2 "https://api.github.com/repos/Mrs4s/go-cqhttp/releases/latest" | grep "tag_name" | head -n 1 | awk -F ":" '{print $2}' | sed 's/\"//g;s/,//g;s/ //g')
    wget -qO- "${ghproxy}https://github.com/Mrs4s/go-cqhttp/releases/download/${gocq_version}/go-cqhttp_$(uname -s)_${arch}.tar.gz" -O go-cqhttp.tar.gz || (echo -e "${Error} go-cqhttp 下载失败 !" && exit 1)
    cd "${WORK_DIR}" || exit 1
    mv "${TMP_DIR}/zhenxun_bot" ./
    mkdir -p "go-cqhttp"
    tar -zxf "${TMP_DIR}/go-cqhttp.tar.gz" -C ./go-cqhttp/
    echo -e "${info} 开始下载抽卡相关资源..."
    if [[ -e "${WORK_DIR}/zhenxun_bot/draw_card" ]]; then
        echo -e "${info} 抽卡资源文件已存在，跳过下载"
    else
        SOURCE_URL=https://pan.yropo.top/source/zhenxun/
        wget ${SOURCE_URL}data_draw_card.tar.gz -qO ~/.cache/data_draw_card.tar.gz \
            && wget ${SOURCE_URL}img_draw_card.tar.gz -qO ~/.cache/img_draw_card.tar.gz \
            && tar -zxf ~/.cache/data_draw_card.tar.gz -C ${WORK_DIR}/zhenxun_bot/ \
            && tar -zxf ~/.cache/img_draw_card.tar.gz -C ${WORK_DIR}/zhenxun_bot/ \
            && rm -rf ~/.cache/*.tar.gz
    fi
}

Set_config_admin() {
    echo -e "${Info} 请输入管理员QQ账号(也就超级用户账号):[QQ]"
    read -erp "管理员QQ:" admin_qq
    [[ -z "$admin_qq" ]] && admin_qq=""
    cd ${WORK_DIR}/zhenxun_bot && \
      sed -i "s/SUPERUSERS.*/SUPERUSERS=[\"$admin_qq\"]/g" .env.dev && \
      sed -i "s/PORT.*/PORT = 14514/g" .env.dev || \
      echo -e "${Error} 配置文件不存在！请检查zhenxun_bot是否安装正确!"
    echo -e "${info} 设置成功!管理员QQ: ${admin_qq}"
}

Set_config_bot() {
    echo -e "${Info} 请输入Bot QQ账号:[QQ]"
    read -erp "Bot QQ:" bot_qq
    [[ -z "$bot_qq" ]] && bot_qq=""
    cd ${WORK_DIR}/go-cqhttp && sed -i "s/uin:.*/uin: $bot_qq/g" config.yml || echo -e "${Error} 配置文件不存在！请检查go-cqhttp是否安装正确!"
    echo -e "${info} 设置成功!Bot QQ: ${bot_qq}"
}

Set_config() {
    if [[ -e "${WORK_DIR}/go-cqhttp/config.yml" ]]; then
        echo -e "${info} go-cqhttp 配置文件已存在，跳过生成"
    else
        cd ${WORK_DIR}/go-cqhttp && echo -e "3\n" | ./go-cqhttp > /dev/null 2>&1
        sudo sed -i 's|universal:.*|universal: ws://localhost:14514/onebot/v11/ws|g' config.yml
    fi
    Set_config_bot
    Set_config_admin
    echo -e "${Info} 开始设置 PostgreSQL 连接语句..."
    sed -i 's|bind.*|bind: str = "postgresql://zhenxun:zxpassword@localhost:5432/zhenxun"|g' configs/config.py
}

Start_zhenxun_bot() {
    check_installed_zhenxun_status
    check_pid_zhenxun
    [[ -n ${PID} ]] && echo -e "${Error} zhenxun_bot 正在运行，请检查 !" && exit 1
    cd ${WORK_DIR}/zhenxun_bot
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
    tail -f -n 100 ${WORK_DIR}/zhenxun_bot/zhenxun_bot.log
}

Set_config_zhenxun() {
    vim ${WORK_DIR}/zhenxun_bot/configs/config.yaml
}

Start_cqhttp() {
    check_installed_cqhttp_status
    check_pid_cqhttp
    [[ -n ${PID} ]] && echo -e "${Error} go-cqhttp 正在运行，请检查 !" && exit 1
    cd ${WORK_DIR}/go-cqhttp
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
    tail -f -n 100 ${WORK_DIR}/go-cqhttp/go-cqhttp.log
}

Set_config_cqhttp() {
    vim ${WORK_DIR}/go-cqhttp/config.yml
}


Set_config_zhenxun() {
    vim ${WORK_DIR}/zhenxun_bot/configs/config.yaml
}

Exit_cqhttp() {
    cd ${WORK_DIR}/go-cqhttp
    rm -f session.token
    echo -e "${Info} go-cqhttp 账号已退出..."
    Stop_cqhttp
    sleep 3
    menu_cqhttp
}

Set_dependency() {
    cd ${WORK_DIR}/zhenxun_bot
    Set_pip_Mirror
    ${python_v} -m pip install --ignore-installed -r ${ghproxy}https://raw.githubusercontent.com/zhenxun-org/zhenxun_bot-deploy/master/requirements.txt -i ${mirror_url}
    playwright install chromium
}

Uninstall_All() {
  echo -e "${Tip} 是否完全卸载 zhenxun_bot 和 go-cqhttp？(此操作不可逆)"
  read -erp "请选择 [y/n], 默认为 n:" uninstall_check
  [[ -z "${uninstall_check}" ]] && uninstall_check='n'
  if [[ ${uninstall_check} == 'y' ]]; then
    cd ${WORK_DIR}
    check_pid_zhenxun
    [[ -z ${PID} ]] || kill -9 ${PID}
    echo -e "${Info} 开始卸载 zhenxun_bot..."
    rm -rf zhenxun_bot || echo -e "${Error} zhenxun_bot 卸载失败！"
    check_pid_cqhttp
    [[ -z ${PID} ]] || kill -9 ${PID}
    echo -e "${Info} 开始卸载 go-cqhttp..."
    rm -rf go-cqhttp || echo -e "${Error} go-cqhttp 卸载失败！"
    echo -e "${Info} 感谢使用真寻bot，期待于你的下次相会！"
  fi
  echo -e "${Info} 操作已取消..." && menu_zhenxun
}

Install_zhenxun_bot() {
    check_root
    [[ -e "${WORK_DIR}/zhenxun_bot/bot.py" ]] && echo -e "${Error} 检测到 zhenxun_bot 已安装 !" && exit 1
    startTime=`date +%s`
    Set_ghproxy
    echo -e "${Info} 开始检查系统..."
    check_arch
    check_sys
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
        sudo cp -r ${WORK_DIR}/zhenxun_bot/resources/font /usr/share/fonts/chinese
        cd /usr/share/fonts/chinese && mkfontscale
    fi
    endTime=`date +%s`
    ((outTime=($endTime-$startTime)))
    echo -e "${Info} 安装用时 ${outTime} s ..."
    echo -e "${Info} 开始运行 zhenxun_bot..."
    Start_zhenxun_bot
    echo -e "${Info} 开始运行 go-cqhttp..."
    Start_cqhttp
    View_cqhttp_log
}

Update_Shell(){
    echo -e "${Info} 开始更新install.sh"
    bak_dir_name="sh_bak/"
    bak_file_name="${bak_dir_name}install.`date +%Y%m%d%H%M%s`.sh"
    if [[ ! -d ${bak_dir_name} ]]; then
        sudo mkdir -p ${bak_dir_name}
        echo -e "${Info} 创建备份文件夹${bak_dir_name}"
    fi
    wget ${update_shell_url} -O install.sh.new
    sudo cp -f install.sh ${bak_file_name}
    echo -e "${Info} 备份原install.sh为${bak_file_name}"
    sudo mv -f install.sh.new install.sh
    echo -e "${Info} install.sh更新完成，请重新启动"
    exit 0
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
  if [[ -e "${WORK_DIR}/go-cqhttp/go-cqhttp" ]]; then
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
 ${Green_font_prefix} 8.${Font_color_suffix} 卸载 zhenxun_bot + go-cqhttp
 ${Green_font_prefix}10.${Font_color_suffix} 切换为 go-cqhttp 菜单" && echo
  if [[ -e "${WORK_DIR}/zhenxun_bot/bot.py" ]]; then
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
  8)
    Uninstall_All
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
