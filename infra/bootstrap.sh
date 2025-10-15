#!/usr/bin/env bash
set -euo pipefail

# location of this script
ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
COMPOSE_FILE="$ROOT_DIR/docker-compose.yml"
INIT_CYPHER="$ROOT_DIR/init.cypher"
ENV_FILE="$ROOT_DIR/.env"

if [ ! -f "$COMPOSE_FILE" ]; then
  echo "ERROR: docker-compose.yml not found in $ROOT_DIR"
  exit 1
fi

if [ ! -f "$ENV_FILE" ]; then
  echo "ERROR: .env file not found. Copy .env.example -> .env and set NEO4J_PASSWORD."
  exit 2
fi

# read password from .env (simple parsing)
NEO4J_PASSWORD=$(grep -E '^NEO4J_PASSWORD=' "$ENV_FILE" | cut -d '=' -f2- || true)
if [ -z "$NEO4J_PASSWORD" ]; then
  echo "ERROR: NEO4J_PASSWORD not set in .env"
  exit 3
fi

echo "Bringing up Neo4j with docker-compose..."
docker compose -f "$COMPOSE_FILE" up -d

echo "Waiting for Neo4j HTTP endpoint to become healthy..."

# wait until HTTP endpoint responds
MAX_RETRIES=60
SLEEP_SECONDS=5
i=0
until curl -sSf http://localhost:7474/ >/dev/null 2>&1; do
  i=$((i+1))
  if [ "$i" -ge "$MAX_RETRIES" ]; then
    echo "ERROR: Neo4j did not become available in time."
    docker compose -f "$COMPOSE_FILE" ps
    exit 4
  fi
  printf "."
  sleep "$SLEEP_SECONDS"
done
echo -e "\nNeo4j appears to be up."

# run the init.cypher via cypher-shell (stdin)
if [ ! -f "$INIT_CYPHER" ]; then
  echo "WARNING: init.cypher not found; skipping seeding."
  exit 0
fi

echo "Seeding database from $INIT_CYPHER..."
# Use docker exec + cypher-shell and pass password from env
docker exec -i graphwise-neo4j cypher-shell -u neo4j -p "$NEO4J_PASSWORD" --format plain < "$INIT_CYPHER"

echo "Seeding complete. Example: connect to http://localhost:7474 with user=neo4j and the password from .env"
echo "Bolt endpoint: bolt://localhost:7687"
