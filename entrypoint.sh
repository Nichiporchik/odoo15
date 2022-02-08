#!/bin/bash
# This file based on https://github.com/odoo/docker/blob/master/14.0/entrypoint.sh
set -e

if [ -v PASSWORD_FILE ]; then
    PASSWORD="$(< $PASSWORD_FILE)"
fi

# set the postgres database host, port, user and password according to the environment
# and pass them as arguments to the odoo process if not present in the config file
: ${HOST:=${DB_PORT_5432_TCP_ADDR:='db'}}
: ${PORT:=${DB_PORT_5432_TCP_PORT:=5432}}
: ${USER:=${DB_ENV_POSTGRES_USER:=${POSTGRES_USER:='odoo'}}}
: ${PASSWORD:=${DB_ENV_POSTGRES_PASSWORD:=${POSTGRES_PASSWORD:='odoo'}}}

DB_ARGS=()
function check_config() {
    param="$1"
    value="$2"
    if grep -q -E "^\s*\b${param}\b\s*=" "$ODOO_RC" ; then
        value=$(grep -E "^\s*\b${param}\b\s*=" "$ODOO_RC" |cut -d " " -f3|sed 's/["\n\r]//g')
    fi;
    DB_ARGS+=("--${param}")
    DB_ARGS+=("${value}")
}
check_config "db_host" "$HOST"
check_config "db_port" "$PORT"
check_config "db_user" "$USER"
check_config "db_password" "$PASSWORD"

addonspath=""

get_addons () {

python 2>&1 >/dev/null - <<END
#!/usr/bin/env python
import os
import sys


MANIFEST_NAMES = ["__manifest__.py", "__odoo__.py", "__openerp__.py", "__terp__.py"]
SKIP_PATHS = ["point_of_sale/tools", "base_import_module/tests"]

def main():
    # Input in the form of an array of folders (layered image)
    inputs = sorted("$@".split())
    res = []
    for input in inputs:
        paths = set()
        for root, _, files in os.walk(input):
            if any(S in root for S in SKIP_PATHS):
                continue
            if not any(M in files for M in MANIFEST_NAMES):
                continue
            paths |= set([os.path.dirname(root)])
        paths = sorted(list(paths))  # We promise alphabetical order
        res.extend(paths)
    return ' '.join(res)


if __name__ == "__main__":
    sys.exit(main())
END
}

for dir in $(get_addons '/opt/odoo'); do
    echo "==>  Adding $dir to addons path"
    if [ -z "$addonspath" ]; then
        addonspath=$dir
    else
        addonspath=$addonspath,$dir
    fi;
done;

export ADDONS_PATH=$addonspath

case "$1" in
    -- | odoo)
        shift
        wait-for-psql.py ${DB_ARGS[@]} --timeout=30
        exec "${ODOO_CMD}" "$@" "${DB_ARGS[@]}" "--addons-path" "${ADDONS_PATH}"
        ;;
    -* | shell)
        wait-for-psql.py ${DB_ARGS[@]} --timeout=30
        exec "${ODOO_CMD}" "$@" "${DB_ARGS[@]}" "--addons-path" "${ADDONS_PATH}"
        ;;
    tests)
        shift
        exec "${ODOO_CMD}" "$@" "${DB_ARGS[@]}" "--test-enable" "--addons-path" "${ADDONS_PATH}"
        ;;
    coverage)
        if ! command -v coverage &> /dev/null
        then
            echo "coverage not installed"
            exit 1
        fi
        coverage run ${ODOO_CMD} $@ ${DB_ARGS[@]} --test-enable --stop-after-init --addons-path ${ADDONS_PATH}
        STATUS=$?
        coverage report -m
        coverage html

        COVERAGE="${COVERAGE:-90}"
        CURRENT_COVERAGE=$(cat ./htmlcov/index.html | grep '<span class="pc_cov">' | grep -o '[0-9]\+');

        if [ "$CURRENT_COVERAGE" -ge "$COVERAGE" ]; then
            exit ${STATUS}
        else
            echo "Current (${CURRENT_COVERAGE}) coverage is less than ${COVERAGE}"
            exit 1
        fi
        ;;
    *)
        exec "$@"
        ;;
esac

exit 1
