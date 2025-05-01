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
