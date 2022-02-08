## Setup

- Install [docker](https://docs.docker.com/engine/install/), [docker-compose](https://docs.docker.com/compose/install/), [make](https://wiki.ubuntu.com/ubuntu-make)

- Update all submodules
  ```bash
  make reset-submodules
  ```
  
- Build image
  ```bash
  make build
  ```

- Clone addons repository into `addons/<repository_name>` folder

- Create `postgres_password` file and put it to `secrets` folder

- Create odoo configuration file `odoo.conf` inside `configs` folder (check example in Additional Information section)

## Run Odoo

- Build development docker image

  ```
  docker-compose up odoo
  ```

- Running development instance

  ```
  make run
  ```

- Stop development instance
  ```
  make stop
  ```

## Additional Information

- If you want debugging python code you should add two new lines in `.py` file:

  ```
  import wdb; wdb.set_trace()
  ```

  After that, when the interpreter reaches these lines, the debug console will open in the browser

- Shell access:
  ```
  docker-compose run odoo shell -d <DB_NAME>
  ```
  
- `odoo.conf` example
  ```text
  [options]
  data_dir = /opt/odoo/data
  admin_passwd = some_password
  limit_time_cpu = 600
  limit_time_real = 1200
  ```
