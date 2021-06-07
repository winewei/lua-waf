# How to use

* clone
```sh
git clone https://github.com/winewei/lua-waf.git
cd lua-waf
docker-compose up -d
```

## Set the block
- support no redis
    ```
    BASE_COUNT_TTL: 10
    BASE_BAN_LIMIT: 10
    BASE_BAN_TTL: 60
    SUPER_BAN_LIMIT: 50
    SUPER_BAN_TLL: 3600
    ```
- update [`docker-compose`](docker-compose.yml) environment
    ```
    BASE_COUNT_TTL: 10
    BASE_BAN_LIMIT: 10
    BASE_BAN_TTL: 60
    SUPER_BAN_LIMIT: 50
    SUPER_BAN_TLL: 3600
    REDISHOST: "192.168.1.2"
    REDISPORT: 6379
    ```
