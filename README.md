## 更新官方镜像版本到此镜像

### 更新版本信息

- `Dockerfile` 中，把 `from sharelatex/sharelatex:5.4.1` 中的版本号改为最新的版本号
- `.github/workflows/docker.yaml` 中，把 `tags: ${{ secrets.DOCKER_USERNAME }}/sharelatex:5.4.1` 中的版本号改为最新的版本号

### 更新镜像

- 在 `Actions` 里，点击 `Build and Push Docker Image`，在 `Run workflow` 下拉列表中点击 `Run workflow`，即可编译镜像，等编译完成后，会自动推送到 Docker Hub
