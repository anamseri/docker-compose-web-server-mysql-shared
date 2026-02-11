# Docker Compose Web Server Mysql Shared

### Docker Compose based web server stack with Nginx, Laravel and Shared Mysql

- Container Architecture:
  - Db Shared Container: mariadb:11.4
  - Phpmyadmin Container: phpmyadmin:latest
  - Network: bridge external network

## Setup Directory & Environment

🔹 Directory Structure

```bash
{PROJECT_DIR}/
├ {MYSQL_DIR}/                 <-- shared mysql + phpmyadmin
│ │ ├─ mysql/
│ │ │  └── conf.d
│ │ │  │ └── my.cnf
│ │ ├── .env
│ │ ├── create_database.sh
│ │ ├── set-permissions.sh
│ │ └── docker-compose.yaml
├ {APP_DIR}/                   <-- App1
│ ...
├ {APP_DIR}/                   <-- App2, etc.
│ ...
```

## Setup Directory & Environment

🔹 Create a MYSQL_DIR directory

<sub>_Must match MYSQL_DIR in .env_</sub>

```bash
sudo mkdir -p /srv/anamseri/laravelshareddb

sudo chown -R $USER:$USER /srv/anamseri/laravelshareddb
sudo chmod -R 755 /srv/anamseri/laravelshareddb
```

<sub>_Keep working in this directory_</sub>

```bash
cd /srv/anamseri/laravelshareddb
```

🔹 Clone the repository or download-upload manually via SFTP.

```bash
git clone https://github.com/anamseri/docker-compose-web-server-mysql-shared.git .
```

🔹 Set Docker Compose Environment

```bash
cp .env.anamseri .env
ls -l .env

nano .env
```

<sup>_Configure environment_</sup>

## Setup Permissions

```bash
chmod +x set-permissions.sh

./set-permissions.sh
```

## Deploy Docker Compose

```bash
docker compose up -d
```

🔹 Check container:

```bash
docker compose ps
```

🔹 Check network

```bash
docker network ls | grep laravel_netshared
```

🔹 Debug:

```bash
docker compose logs db
docker compose logs phpmyadmin
```

🔹 Access

```bash
http://<IP-HOST>:8080

Example:
http://192.168.1.103:8080
```

## Create & Drop Database

```bash
chmod +x create_database.sh

Usage:
./create_database.sh -h
```

🔹 Prod mode

```bash
docker compose stop phpmyadmin
```
