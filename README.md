# HAProxy + Docker Compose Demo

This project stands up **HAProxy** in front of two API servers and one web server using **Docker Compose**.

## What you get
- **Load balancing** across 2 API servers (`roundrobin` by default).
- **HAProxy stats dashboard** on `http://localhost:8404/stats` (user: `admin`, pass: `admin`).
- **Health checks** on all backends.
- **Bonus features** included:
  - Weighted servers (api1 weight 3 vs api2 weight 1).
  - Multiple algorithms ready to try (`roundrobin`, `leastconn`, `source`).
  - Basic **rate limiting** (429 if >10 reqs / 10s per IP).
  - **Path-based routing**: `/api` -> API; `/web` -> nginx.
  - **Sticky sessions** via cookie.

## Prereqs
- Docker and Docker Compose installed.

## Run it
```bash
docker compose up -d
```

## Try it

### 1) Load balancing across two API servers
```bash
for i in {1..8}; do   curl -s http://localhost:8080/api -i |   grep -E "X-Served-By|Hostname" ; echo ;   sleep 0.2 ; done
```
You should see responses alternating with header `X-Served-By: api1` or `api2` (weighted ~75/25).

### 2) Sticky sessions (cookie-based)
```bash
# First request sets a cookie
curl -si http://localhost:8080/api | grep -i "^set-cookie"

# Reuse the cookie to stick to the same server
curl -s -c cookies.txt -b cookies.txt http://localhost:8080/api -i | grep -E "X-Served-By|Set-Cookie"
for i in {1..5}; do curl -s -b cookies.txt http://localhost:8080/api -i | grep -E "X-Served-By"; done
```

### 3) Weighted distribution
```bash
for i in {1..40}; do curl -s http://localhost:8080/api -i |   grep -i "X-Served-By"; done | sort | uniq -c
```

### 4) Path-based routing
```bash
curl -I http://localhost:8080/web
```

### 5) Rate limiting
```bash
# Send a quick burst; after 10 requests within 10s expect 429
for i in {1..20}; do curl -s -o /dev/null -w "%{http_code} " http://localhost:8080/api; done; echo
```

### 6) HAProxy stats
Open: `http://localhost:8404/stats` (user: `admin`, pass: `admin`).

## Switch algorithms
Edit `haproxy.cfg` in `backend be_api` and change:
```haproxy
balance roundrobin
# balance leastconn
# balance source
```
Then reload:
```bash
docker compose restart haproxy
```

## Tear down
```bash
docker compose down -v
```

## Files
- `docker-compose.yml`
- `haproxy.cfg`
- `web/index.html`
- `scripts/demo.sh`
- `README.md`
