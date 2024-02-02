import os
import sys
from jinja2 import Environment, FileSystemLoader
import json5
import json
import socket
import subprocess

with open("/opt/hiddify-manager/current.json") as f:
    configs = json.load(f)
    configs['chconfigs'] = {int(k): v for k, v in configs['chconfigs'].items()}
    configs['hconfigs'] = configs['chconfigs'][0]


def exec(command):
    try:
        output = subprocess.check_output(
            command, shell=True, stderr=subprocess.STDOUT, text=True
        )
        return output
    except subprocess.CalledProcessError as e:
        print(f"Command failed with exit code {e.returncode}:")
        print(e.output)
    return ""


def telegram_mtproto_secret() -> str:
    '''Telegram secret code for MTProxy'''
    sec = configs['hconfigs']['shared_secret'].replace("-", "")
    return sec[:32]


def to_hex(input: str) -> str:
    try:
        return input.encode('utf-8').hex()
    except:
        return ''


def render_j2_templates(start_path):
    # Set up the Jinja2 environment
    env_paths = ['/', '/opt/hiddify-manager/singbox/configs/']
    env = Environment(loader=FileSystemLoader(env_paths))
    # Dirs to ignore from Jinja2 rendering
    exclude_dirs = ['/opt/hiddify-manager/singbox/configs/includes']

    for root, dirs, files in os.walk(start_path):
        for file in files:
            if file.endswith(".j2") and root not in exclude_dirs:
                print("Rendering: " + file)
                # Create a template object by reading the file
                template_path = os.path.join(root, file)
                template = env.get_template(template_path)

                # Render the template
                rendered_content = template.render(**configs, exec=exec, os=os, telegram_mtproto_secret=telegram_mtproto_secret(), to_hex=to_hex
                                                   )

                # Write the rendered content to a new file without the .j2 extension
                output_file_path = os.path.splitext(template_path)[0]
                if output_file_path.endswith(".json"):
                    # Remove trailing comma and comments from json
                    try:
                        json5object = json5.loads(rendered_content)
                        rendered_content = json5.dumps(
                            json5object,
                            trailing_commas=False,
                            indent=2,
                            quote_keys=True,
                        )
                    except Exception as e:
                        print(f"Error parsing json: {e}")

                with open(output_file_path, "w", encoding="utf-8") as output_file:
                    output_file.write(rendered_content)

                # print(f'Rendered and stored: {output_file_path}')


start_path = "/opt/hiddify-manager/"

if len(sys.argv) > 1 and sys.argv[1] == "apply_users":
    start_path += "singbox/"
render_j2_templates(start_path)
