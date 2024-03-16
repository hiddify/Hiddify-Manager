#!/usr/bin/python3
import os
import json
from sys import stderr

BASE_PATH: str = '/opt/hiddify-manager/'
ENV_PATH: str = '/opt/hiddify-manager/.env'


def write_records_to_bash_file(records: dict) -> bool:
    try:
        with open(ENV_PATH, 'w') as f:
            f.write("#!/bin/bash\n")
            for k, v in records.items():
                f.write(f"{k.upper()}={'true' if v==1 else 'false'}\n")

        os.chmod(ENV_PATH, 0o600)
        return True
    except:
        return False


def main():
    cfg_path = os.path.join(BASE_PATH, 'current.json')
    try:
        with open(cfg_path, 'r') as f:
            cfgs = json.load(f)
            cfgs = {k: v for k, v in cfgs['chconfigs']['0'].items() if type(v) is bool}
            if write_records_to_bash_file(cfgs):
                print("Environment file generated successfully.")
    except Exception as e:
        print(f"Error: gen_env.py: {e}", file=stderr)


if __name__ == '__main__':
    main()
