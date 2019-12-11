## Starting a test environment

1. Build the docker image.

    ```
    docker build -t macpatch .
    ```

2. Create local folders to store persistent data outside the docker container.

    ```
    mkdir content
    mkdir dbstore
    mkdir invdata/files
    ```

3. Start the docker environment.

    ```
    docker-compose up
    ```

You now have a demo MacPatch server running. You can access the web console at [https://localhost](https://localhost). The default admin username/password is `mpadmin`/`password`.

## Using an existing database

The `docker-compose.yml` file includes a docker MySQL database. If you prefer to use an existing database, remove the `db` block from the `docker-compose.yml` file.

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
      - $PWD/config.cfg:/opt/MacPatch/ServerConfig/flask/config.cfg
...
```

## Misc.

Creating an image tar archive.

```
docker save macpatch > macpatch-$(date "+%y.%m.%d-%s").tar
```
