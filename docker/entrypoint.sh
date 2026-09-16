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

# /var/lib/odoo is a volume that Docker may (re)create as root-owned; make
# sure the odoo user can write to it (data_dir, filestore, sessions, ...)
# before dropping privileges.
mkdir -p /var/lib/odoo/sessions
chown -R odoo:odoo /var/lib/odoo

case "$1" in
    odoo)
        shift
        exec gosu odoo python3 /odoo/odoo-bin -c /etc/odoo/odoo.conf "$@"
        ;;
    -*)
        exec gosu odoo python3 /odoo/odoo-bin -c /etc/odoo/odoo.conf "$@"
        ;;
    *)
        exec gosu odoo "$@"
        ;;
esac
