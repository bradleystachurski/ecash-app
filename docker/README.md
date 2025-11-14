# Docker

## Setup

Install Docker

```
curl -fsSL https://get.docker.com | bash
sudo usermod -aG docker "$USER"
exec sudo su -l $USER
```

Build

```
docker build -t ecash-app-builder .
```
