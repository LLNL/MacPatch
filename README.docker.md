## Starting a test environment

1. Download a prebuilt docker image and load it.

    ```
    mkdir macpatch
    cd macpatch
    curl -O https://skynet.llnl.gov/docker/macpatch/llnl-macpatch-18.10.29-1540838966.tar
    docker load < llnl-macpatch-18.10.29-1540838966.tar
    ```

2. MacPatch requires an SSL cert. For testing you can generate self signed cert.

    ```
    mkdir ssl
    openssl req -new -sha256 -x509 -nodes -days 999 -subj \
        "/C=NO/ST=State/L=Country/O=MacPatch/OU=MacPatch/CN=$HOSTNAME/emailAddress=admin@mpdemo.com" \
        -newkey rsa:2048 -keyout ssl/server.key -out ssl/server.crt
    ```

3. Create local folders to store persistent content from the docker container.

    ```
    mkdir content
    mdkir dbstore
    ```

4. Start the docker environment.

    ```
    docker-compose up
    ```

You now have a fully functional MacPatch environment running at [https://localhost](https://localhost). The default admin username/password is `mpadmin`/`password`.

## Using an existing database

The `docker-compose.yml` file includes a docker MySQL database. If you prefer to use an existing database, remove the `db` block from the `docker-compose.yml` file. If your database has been initialized previously, you can also comment out the `command: "init-db"` line of the `macpatch` block.

You will also need to provide docker with a `config.cfg` file with information about your database.

```
# config.cfg

DB_HOST = 'mydb.example.com'
DB_PORT = '3306'
DB_NAME = 'MacPatchDB3'
DB_PASS = 'admin'
DB_USER = 'db-admin-password'
DB_USER_RO = 'rouser'
DB_PASS_RO = 'ro-user-password'
```

Add your `config.cfg` file to the docker container by adding it to the `volumes` section of the `docker-compose.yml` file.

```
# docker-compose.yml
...
    volumes:
      - $PWD/ssl/server.crt:/opt/MacPatch/Server/etc/ssl/server.crt
      - $PWD/ssl/server.key:/opt/MacPatch/Server/etc/ssl/server.key
      - $PWD/content:/opt/MacPatch/Content
      - $PWD/config.cfg:/opt/MacPatch/Server/apps/config.cfg
...
```

## Misc.

Building the docker image locally.

```
docker build --rm -t llnl/macpatch .
```

Creating an image tar.

```
docker save llnl/macpatch > llnl-macpatch-$(date "+%y.%m.%d-%s").tar
```
