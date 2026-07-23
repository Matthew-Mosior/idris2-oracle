#!/usr/bin/env bash

set -euo pipefail

IMAGE="container-registry.oracle.com/database/free:latest-lite"
CONTAINER="oracle-free"

SYS_PASSWORD="oracle123"

TEST_USER="idris"
TEST_PASSWORD="idris"

TABLESPACE="idris_test_data"
DATAFILE="/opt/oracle/oradata/FREE/FREEPDB1/idris_test_data01.dbf"

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
echo "Ensuring integration test user and tablespace exist..."

docker exec "$CONTAINER" bash -c "
sqlplus -L -s system/$SYS_PASSWORD@//127.0.0.1:1521/FREEPDB1 <<EOF

WHENEVER SQLERROR EXIT SQL.SQLCODE

DECLARE
    user_exists       NUMBER;
    tablespace_exists NUMBER;
BEGIN

    ----------------------------------------------------------------
    -- Create the dedicated test tablespace if it does not exist.
    ----------------------------------------------------------------

    SELECT COUNT(*)
      INTO tablespace_exists
      FROM dba_tablespaces
     WHERE tablespace_name = UPPER('$TABLESPACE');

    IF tablespace_exists = 0 THEN

        EXECUTE IMMEDIATE
            'CREATE TABLESPACE $TABLESPACE
             DATAFILE ''$DATAFILE''
             SIZE 100M
             AUTOEXTEND ON
             NEXT 10M
             MAXSIZE 1G
             EXTENT MANAGEMENT LOCAL
             SEGMENT SPACE MANAGEMENT AUTO';

    END IF;

    ----------------------------------------------------------------
    -- Create the integration test user if it does not exist.
    ----------------------------------------------------------------

    SELECT COUNT(*)
      INTO user_exists
      FROM dba_users
     WHERE username = UPPER('$TEST_USER');

    IF user_exists = 0 THEN

        EXECUTE IMMEDIATE
            'CREATE USER $TEST_USER
             IDENTIFIED BY $TEST_PASSWORD
             DEFAULT TABLESPACE $TABLESPACE';

    END IF;

    ----------------------------------------------------------------
    -- Ensure the test user uses the dedicated tablespace.
    ----------------------------------------------------------------

    EXECUTE IMMEDIATE
        'ALTER USER $TEST_USER
         DEFAULT TABLESPACE $TABLESPACE';

    EXECUTE IMMEDIATE
        'ALTER USER $TEST_USER
         QUOTA UNLIMITED ON $TABLESPACE';


    ----------------------------------------------------------------
    -- Required privileges for the integration test suite.
    ----------------------------------------------------------------

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
echo "Tablespace: $TABLESPACE"
echo "Datafile:   $DATAFILE"
echo
echo "Schema installation is handled by installSchema."
echo "Test data is reset by resetDatabase before each test."
echo "=================================================="
