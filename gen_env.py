#!/usr/bin/python3
import re
import pymysql
from pymysql import cursors
import os
from typing import Tuple, Optional, Dict, Any, List
from sys import stderr

BASE_PATH: str = '/opt/hiddify-manager/'
ENV_PATH: str = '/opt/hiddify-manager/.env'


def check_database_exists(cursor: cursors.Cursor) -> bool:
    cursor.execute("SHOW DATABASES LIKE 'hiddifypanel'")
    return cursor.fetchone() is not None


def check_table_exists(cursor: cursors.Cursor) -> bool:
    cursor.execute("SHOW TABLES LIKE 'bool_config'")
    return cursor.fetchone() is not None


def check_table_not_empty(cursor: cursors.Cursor) -> bool:
    cursor.execute("SELECT COUNT(*) FROM bool_config")
    return cursor.fetchone()['COUNT(*)'] > 0  # type: ignore


def retrieve_records(cursor: cursors.Cursor) -> List[Dict[str, Any]]:
    cursor.execute("SELECT `key`,`value` FROM bool_config where 'child_id' = 0")
    return cursor.fetchall()[1:]  # type: ignore


def write_records_to_bash_file(records: List[Dict[str, Any]]) -> bool:
    try:
        with open(ENV_PATH, 'w') as f:
            f.write("#!/bin/bash\n")
            for record in records:
                f.write(f"{record['key'].upper()}={'true' if record['value']==1 else 'false'}\n")

        os.chmod(ENV_PATH, 0o600)
        return True
    except:
        return False


def extract_database_uri(file_path: str) -> Optional[str]:
    with open(file_path, 'r') as file:
        for line in file:
            if line.startswith('SQLALCHEMY_DATABASE_URI'):
                match = re.search(r"SQLALCHEMY_DATABASE_URI\s*=\s*'(.*)'", line)
                if match:
                    return match.group(1)
    return None


def parse_uri(uri: str) -> Tuple[str, str, str, str, str]:
    uri = uri.split('://')[1]
    user, uri = uri.split(':', 1)
    password, uri = uri.split('@', 1)
    host, uri = uri.split('/', 1)
    db, uri = uri.split('?', 1)
    charset = uri.split('=',)[1]
    return user, password, host, db, charset


def connect_to_mysql(uri: str) -> Tuple[pymysql.connections.Connection | None, cursors.Cursor | None]:
    # Parse the URI
    user, password, host, database, charset = parse_uri(uri)

    try:
        # Establishing connection to MySQL server
        connection: pymysql.connections.Connection = pymysql.connect(host=host, user=user, password=password, database=database, charset=charset)
        cursor: cursors.Cursor = connection.cursor(cursor=cursors.DictCursor)
        return connection, cursor
    except pymysql.Error as err:
        print("Error:", err)
        return None, None


def main() -> None:
    uri_path = os.path.join(BASE_PATH, 'hiddify-panel', 'app.cfg')
    uri = extract_database_uri(uri_path)
    if not uri:
        print(f'Error: gen_env.py: Cannot extract database uri from: {uri_path}', stderr)
        exit(1)

    connection, cursor = connect_to_mysql(uri)  # type: ignore
    if connection and cursor:
        try:
            if check_database_exists(cursor):
                cursor.execute("USE hiddifypanel")
                if check_table_exists(cursor):
                    if check_table_not_empty(cursor):
                        records = retrieve_records(cursor)
                        if write_records_to_bash_file(records):
                            print("Environment file generated successfully.")
                    else:
                        print("Error: gen_env.py: 'bool_config' table is empty", file=stderr)
                else:
                    print("Error: gen_env.py: 'bool_config' table does not exist", file=stderr)
            else:
                print("Error: gen_env.py: 'hiddifypanel' database does not exist", file=stderr)
        finally:
            cursor.close()
            connection.close()


if __name__ == '__main__':
    main()
