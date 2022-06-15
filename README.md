# zhenxun_bot-deploy

真寻 bot 一键部署脚本

## 食用方法

```bash
bash <(curl -s -L https://raw.githubusercontent.com/zhenxun-org/zhenxun_bot-deploy/master/install.sh)
```

## 更新

**2022/06/15**

- 修复运行psql时的权限问题 [#21](https://github.com/zhenxun-org/zhenxun_bot-deploy/issues/21)

**2022/05/21**

- 修复 bug [#15](https://github.com/zhenxun-org/zhenxun_bot-deploy/issues/15)

**2022/05/20**

- 更改监听端口为 14514
- 添加卸载二次验证 [#12](https://github.com/zhenxun-org/zhenxun_bot-deploy/issues/12)

**2022/05/18** [v1.0.4]

- 添加切换 git 源功能
- 添加卸载功能
- 显示安装时长
- 修改 pip 源使用方式
- 修改安装目录为/home
