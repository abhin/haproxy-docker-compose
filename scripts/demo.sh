#!/usr/bin/env bash
set -euo pipefail

echo "Round-robin demo (/api):"
for i in {1..8}; do
  curl -s http://localhost:8080/api -i | grep -E "X-Served-By|Hostname" || true
  echo
  sleep 0.2
done

echo
echo "Sticky-session demo (cookie SRV):"
curl -si http://localhost:8080/api -c /tmp/cookies.txt | grep -i "^set-cookie" || true
for i in {1..5}; do
  curl -s http://localhost:8080/api -b /tmp/cookies.txt -i | grep -E "X-Served-By|Hostname" || true
  echo
done

echo
echo "Weighted demo (75/25 expected over many requests):"
for i in {1..40}; do
  curl -s http://localhost:8080/api -i | grep -i "X-Served-By"
done | sort | uniq -c

echo
echo "Path-based routing (/web):"
curl -sI http://localhost:8080/web | head -n 1

echo
echo "Rate limit demo (expect 429s after burst of >10 reqs/10s):"
for i in {1..20}; do
  code=$(curl -s -o /dev/null -w "%{http_code}" http://localhost:8080/api)
  printf "%s " "$code"
done
echo
