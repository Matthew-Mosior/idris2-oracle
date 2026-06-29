#!/usr/bin/env bash

set -euo pipefail

IMAGE="container-registry.oracle.com/database/free:latest-lite"
CONTAINER="oracle-free"

SYS_PASSWORD="oracle123"

TEST_USER="idris"
TEST_PASSWORD="idris"

echo "=================================================="
echo "Oracle Database Free Test Setup"
echo "=================================================="

echo
echo "Pulling Oracle Database image..."
docker pull "$IMAGE"

if docker ps -a --format '{{.Names}}' | grep -qx "$CONTAINER"; then

    echo
    echo "Container '$CONTAINER' already exists."

    if docker ps --format '{{.Names}}' | grep -qx "$CONTAINER"; then
        echo "Container already running."
    else
        echo "Starting existing container..."
        docker start "$CONTAINER"
    fi

else

    echo
    echo "Creating Oracle Database container..."

    docker run -d \
        --name "$CONTAINER" \
        -p 1521:1521 \
        -e ORACLE_PWD="$SYS_PASSWORD" \
        "$IMAGE"

fi

echo
echo "Waiting for Oracle to finish starting..."

until docker exec "$CONTAINER" bash -c \
    "echo 'select 1 from dual;' | sqlplus -L -s system/$SYS_PASSWORD@//127.0.0.1:1521/FREEPDB1" \
    >/dev/null 2>&1
do
    echo "Oracle not ready yet..."
    sleep 5
done

echo "Oracle is ready."

echo
echo "Ensuring integration test user exists..."

docker exec "$CONTAINER" bash -c "
sqlplus -L -s system/$SYS_PASSWORD@//127.0.0.1:1521/FREEPDB1 <<EOF

WHENEVER SQLERROR CONTINUE

DECLARE
    user_exists NUMBER;
BEGIN

    SELECT COUNT(*)
      INTO user_exists
      FROM dba_users
     WHERE username = UPPER('$TEST_USER');

    IF user_exists = 0 THEN

        EXECUTE IMMEDIATE
            'CREATE USER $TEST_USER IDENTIFIED BY $TEST_PASSWORD';

        EXECUTE IMMEDIATE
            'GRANT CREATE SESSION TO $TEST_USER';

        EXECUTE IMMEDIATE
            'GRANT CREATE TABLE TO $TEST_USER';

        EXECUTE IMMEDIATE
            'GRANT CREATE VIEW TO $TEST_USER';

        EXECUTE IMMEDIATE
            'GRANT CREATE SEQUENCE TO $TEST_USER';

        EXECUTE IMMEDIATE
            'GRANT CREATE PROCEDURE TO $TEST_USER';

        EXECUTE IMMEDIATE
            'GRANT CREATE TRIGGER TO $TEST_USER';

        EXECUTE IMMEDIATE
            'GRANT CREATE TYPE TO $TEST_USER';

        EXECUTE IMMEDIATE
            'GRANT UNLIMITED TABLESPACE TO $TEST_USER';

    END IF;

END;
/

EXIT

EOF
"

echo
echo "=================================================="
echo "Oracle integration database is ready."
echo
echo "Host:      localhost"
echo "Port:      1521"
echo "Service:   FREEPDB1"
echo "Username:  $TEST_USER"
echo "Password:  $TEST_PASSWORD"
echo
echo "Schema installation is handled by installSchema."
echo "Test data is reset by resetDatabase before each test."
echo "=================================================="
