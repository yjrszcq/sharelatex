## 更新官方镜像版本到此镜像

### 关联 Docker Hub 账号

- 在 `Settings` 中，展开下拉列表 `Secrets and variables`，点击 `Actions`
- 点击 `New epository secrets`, 在 `Name *` 里填写 `DOCKER_USERNAME`，在 `Secret *` 里填写 Docker Hub 账号的用户名
- 点击 `New epository secrets`, 在 `Name *` 里填写 `DOCKER_PASSWORD`，在 `Secret *` 里填写 Docker Hub 账号的密码

### 更新版本信息

- 在 `Code` 中，编辑文件 `Dockerfile`，把 `from sharelatex/sharelatex:5.4.1` 中的版本号改为最新的版本号
- 在 `Code` 中，编辑文件 `.github/workflows/docker.yaml`，把 `tags: ${{ secrets.DOCKER_USERNAME }}/sharelatex:5.4.1` 中的版本号改为最新的版本号

### 更新镜像

- 在 `Actions` 中，点击 `Build and Push Docker Image`，在 `Run workflow` 下拉列表中点击 `Run workflow`，即可编译镜像，等编译完成后，会自动推送到 Docker Hub

## 使用此镜像

### 安装并配置 Overleaf

> Overleaf Toolkit 部署

1. 拉取 Overleaf Toolkit 工具包
```
git clone https://github.com/overleaf/toolkit.git ./overleaf-toolkit
```

2. 进入 overleaf-toolkit 目录
```
cd ./overleaf-toolkit
```

3. 初始化配置
```
bin/init
```
会在 config 目录下生成以下三个文件：
- overleaf.rc
- variables.env
- version

4. 进入 config 目录
```
cd config
```

5. 编辑文件 `overleaf.rc`
```
# Sharelatex container
OVERLEAF_IMAGE_NAME=szcq/sharelatex #换成我的镜像
OVERLEAF_DATA_PATH=/mydata/docker/overleaf/overleaf #数据的保存路径
SERVER_PRO=false
OVERLEAF_LISTEN_IP=0.0.0.0 #如果需要外部可访问
OVERLEAF_PORT=10802 #将该行修改为你所需服务端口，默认为80端口
```
- 其他的按需更改即可

6. 编辑文件 `version`
```
5.4.1 #此为sharelatex镜像的版本，请改为你需要的版本
```

7. 初始化 docker 服务
```
bin/up
```
- 等待一会儿后，`Ctrl + C` 停止

8. 启动 docker 服务
```
bin/start
```

9. 创建管理员账户
- 进入以下页面，填写邮箱和密码，创建管理员账户
```
http://localhost:服务端口/launchpad
```

### 注意事项

1. 停止运行
- 进入 overleaf-toolkit 目录
```
cd ./overleaf-toolkit
```
- 停止运行
```
bin/stop
```

2. 如果不是 pro 用户，Sibling Containers 需要为 false
```
# Sibling Containers
SIBLING_CONTAINERS_ENABLED=false
DOCKER_SOCKET_PATH=/var/run/docker.sock
```

3. 若要在 Project 中使用中文，则要在编辑项目时，在左上角的 `MENU` 里，`Compiler` 选择 `XeLaTeX`
