# Sharelatex 部署说明

## 使用此镜像

### 安装并配置 Overleaf

> Overleaf Toolkit 部署

#### 1. 拉取 Overleaf Toolkit 工具包
```
git clone https://github.com/overleaf/toolkit.git ./overleaf-toolkit
```

#### 2. 进入 overleaf-toolkit 目录
```
cd ./overleaf-toolkit
```

#### 3. 初始化配置
```
bin/init
```
- 会在 config 目录下生成以下三个文件：
  - overleaf.rc
  - variables.env
  - version

#### 4. 进入 config 目录
```
cd config
```

#### 5. 编辑文件 `overleaf.rc`
```
# Sharelatex container
OVERLEAF_IMAGE_NAME=szcq/sharelatex #更改镜像
OVERLEAF_DATA_PATH=/mydata/docker/overleaf/overleaf #数据的保存路径
SERVER_PRO=false
OVERLEAF_LISTEN_IP=0.0.0.0 #如果不需要外部可访问，则填127.0.0.1
OVERLEAF_PORT=10802 #将该行修改为你所需服务端口，默认为80端口
```
- 其他的按需更改即可

#### 6. 编辑文件 `version`
```
5.4.1 #此为szcq/sharelatex镜像的版本，请改为你需要的版本
```

#### 7. 初始化 docker 服务
```
bin/up
```
- 等待一会儿后，`Ctrl + C` 停止

#### 8. 启动 docker 服务
```
bin/start
```

#### 9. 创建管理员账户
- 进入以下页面，填写邮箱和密码，创建管理员账户
```
http://localhost:服务端口/launchpad
```

### 注意事项

#### 1. 若要在 Project 中使用中文，则要在编辑项目时，在左上角的 `MENU` 里，`Compiler` 选择 `XeLaTeX`

#### 2. 停止运行
- 进入 overleaf-toolkit 目录
```
cd ./overleaf-toolkit
```
- 停止运行
```
bin/stop
```

#### 3. 如果不是 pro 用户，则文件 `overleaf.rc` 里的 Sibling Containers 需要为 `false`
```
# Sibling Containers
SIBLING_CONTAINERS_ENABLED=false
DOCKER_SOCKET_PATH=/var/run/docker.sock
```

### 容器创建后手动添加字体

- 仓库里提供了脚本 `install-sharelatex-fonts.sh`，用于在容器已经创建并运行后，手动把字体复制进容器并刷新字体缓存
- 脚本支持三种输入方式：字体 zip 文件、字体目录、单个字体文件
- 脚本默认容器名是 `sharelatex`；如果你的容器名不是这个值，需要用 `-c` 指定
- 当前 [docker-compose.yml](/Users/yjrszcq/MyData/codes/sharelatex/docker-compose.yml:1) 示例里的容器名是 `overleaf-sharelatex`

#### 1. 给脚本执行权限
```bash
chmod +x ./install-sharelatex-fonts.sh
```

#### 2. 使用 zip 文件导入字体
```bash
./install-sharelatex-fonts.sh -z Fonts.zip
./install-sharelatex-fonts.sh -c overleaf-sharelatex -z Fonts.zip
```

#### 3. 使用字体目录导入字体
```bash
./install-sharelatex-fonts.sh -d Fonts
./install-sharelatex-fonts.sh -c overleaf-sharelatex -d Fonts
```

#### 4. 使用单个字体文件导入字体
```bash
./install-sharelatex-fonts.sh -f simsun.ttc
./install-sharelatex-fonts.sh -c overleaf-sharelatex -f simhei.ttf
```

#### 5. 脚本会做的事情

- 将字体复制到容器内的 `/usr/share/fonts/addfonts`
- 如果输入的是 zip 文件，会在容器内自动安装 `unzip` 并解压
- 最后执行 `fc-cache -fv` 刷新字体缓存

#### 6. 注意事项

- 运行脚本前，请先确认 ShareLaTeX/Overleaf 容器已经启动
- 如果脚本提示找不到容器，可以先执行 `docker ps --format '{{.Names}}'` 查看实际容器名
- 导入完成后，新编译的文档即可使用这些字体；如果项目仍识别不到中文字体，优先检查编译器是否为 `XeLaTeX`



## 自己制作镜像

### 关联 Docker Hub 账号

- 在 `Settings` 中，展开下拉列表 `Secrets and variables`，点击 `Actions`
- 点击 `New epository secrets`, 在 `Name *` 里填写 `DOCKER_USERNAME`，在 `Secret *` 里填写 Docker Hub 账号的用户名
- 点击 `New epository secrets`, 在 `Name *` 里填写 `DOCKER_PASSWORD`，在 `Secret *` 里填写 Docker Hub 账号的密码

### 更新版本信息（可跳过，以后需要更新官方镜像时，执行此处操作，并编译镜像）

- 在 `Code` 中，编辑文件 `Dockerfile`，把 `from sharelatex/sharelatex:5.4.1` 中的版本号改为最新的版本号
- 在 `Code` 中，编辑文件 `.github/workflows/docker.yaml`，把 `tags: ${{ secrets.DOCKER_USERNAME }}/sharelatex:5.4.1` 中的版本号改为最新的版本号

### 编译镜像

- 在 `Actions` 中，点击 `Build and Push Docker Image`，在 `Run workflow` 下拉列表中点击 `Run workflow`，即可编译镜像，等编译完成后，会自动推送到 Docker Hub
