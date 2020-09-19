# How to use

* clone
```sh
git clone https://github.com/winewei/lua-waf.git
cd lua-waf
docker-compose up -d
```

## Set the block
- update web site you would like to protect in [`proxy.conf`](proxy.conf)
  ```
  proxy_pass  https://localhost;
  proxy_set_header Host "localhost";
  ```
- update [`docker-compose`](docker-compose.yml) environment
    ```
    COUNT_CYCLE: 10
    BASE_BAN_LIMIT: 20
    BASE_BAN_EXPIRE: 10
    SUPER_BAN_LIMIT: 100
    SUPER_EXPIRE: 3600
    ```