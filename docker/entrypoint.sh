#!/bin/bash
set -e

: "${PGHOST:=db}"
: "${PGPORT:=5432}"
: "${PGUSER:=odoo}"
: "${PGPASSWORD:=odoo}"
export PGHOST PGPORT PGUSER PGPASSWORD

echo "Waiting for PostgreSQL at ${PGHOST}:${PGPORT}..."
until pg_isready -h "$PGHOST" -p "$PGPORT" -U "$PGUSER" -q 2>/dev/null; do
    sleep 1
done
echo "PostgreSQL is available."

case "$1" in
    odoo)
        shift
        exec python3 /odoo/odoo-bin -c /etc/odoo/odoo.conf "$@"
        ;;
    -*)
        exec python3 /odoo/odoo-bin -c /etc/odoo/odoo.conf "$@"
        ;;
    *)
        exec "$@"
        ;;
esac
