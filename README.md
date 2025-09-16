подготовьте образ и загрузите его в DockerHub

```
docker build -t <ваш_логин>/<имя образа>:<тег> .

docker push <ваш_логин>/<имя образа>:<тег>
```


# Установка и настройка CI/CD

В репозитории с приложением создайте директорию .github/workflows и добавьте в неё файл ci-cd-pipeline.yml
```
name: Pipeline

on:
  push:
    branches: [ main ]
    tags: [ '*.*.*' ]
  pull_request:
    branches: [ main ]

jobs:
  build-and-push:
    runs-on: ubuntu-latest
    steps:
      - name: Checkout code
        uses: actions/checkout@v4

      - name: Set up Docker Buildx
        uses: docker/setup-buildx-action@v3

      - name: Log in to Docker Hub
        uses: docker/login-action@v3
        with:
          username: ${{ secrets.DOCKERHUB_USERNAME }}
          password: ${{ secrets.DOCKERHUB_TOKEN }}

      - name: Extract metadata for Docker
        id: meta
        uses: docker/metadata-action@v4
        with:
          images: sergey282/test_web_application
          tags: |
            type=ref,event=branch
            type=ref,event=pr
            type=semver,pattern={{version}}
            type=semver,pattern={{major}}.{{minor}}

      - name: Build and push Docker image
        uses: docker/build-push-action@v5
        with:
          context: .
          push: true
          tags: ${{ steps.meta.outputs.tags }}
          labels: ${{ steps.meta.outputs.labels }}

  deploy:
    needs: build-and-push
    if: startsWith(github.ref, 'refs/tags/')
    runs-on: ubuntu-latest
    steps:
      - name: Checkout code
        uses: actions/checkout@v4

      - name: Deploy to Kubernetes
        uses: appleboy/ssh-action@v1.0.0
        with:
          host: ${{ secrets.K8S_MASTER_HOST }}
          username: ${{ secrets.K8S_MASTER_USER }}
          key: ${{ secrets.K8S_MASTER_SSH_KEY }}
          script: |
            kubectl set image deployment/nginx-deployment nginx=sergey282/test_web_application:${{ github.ref_name }} -n web
            kubectl rollout status deployment/nginx-deployment -n web
```

В настройках репозитория добавьте секреты (в репозитории на GitHub откройте вкладку Settings > Secrets and variables > Actions, нажмите New repository secret для создания секрета):

```
DOCKERHUB_USERNAME - имя пользователя
DOCKERHUB_TOKEN - токен доступа
K8S_MASTER_HOST - адрес мастер ноды Kubernetes кластера
K8S_MASTER_USER - пользователь для подключения
K8S_MASTER_SSH_KEY - приватный SSH ключ
```


Ожидаемый результат:

1. Интерфейс ci/cd сервиса доступен по http.

    https://github.com/<имя пользователя>/<репозиторий>/actions
    (https://github.com/sergey-prokofev/web-diplom/actions)

2. При любом коммите в репозиторие с тестовым приложением происходит сборка и отправка в регистр Docker образа.

3. При создании тега (форма: 1.0.0) происходит сборка и отправка с соответствующим label в регистри, а также деплой соответствующего Docker образа в кластер Kubernetes.
