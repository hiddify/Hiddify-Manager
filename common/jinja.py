import base64
import os
import sys
from jinja2 import Environment, FileSystemLoader
import json5
import json
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
        print(command)
        print(f"Command failed with exit code {e.returncode}:")
        print(e.output, e)
    return ""


def b64encode(s):
    if type(s) == str:
        s = s.encode("utf-8")
    return base64.b64encode(s).decode("utf-8")


def render_j2_templates(start_path):
    # Set up the Jinja2 environment
    env_paths = ['/', '/opt/hiddify-manager/singbox/configs/']
    env = Environment(loader=FileSystemLoader(env_paths))
    env.filters['b64encode'] = b64encode
    env.filters['hexencode'] = lambda s: ''.join(hex(ord(c))[2:].zfill(2) for c in s)

    # Dirs to ignore from Jinja2 rendering
    exclude_dirs = ['/opt/hiddify-manager/singbox/configs/includes', '/opt/hiddify-manager/.venv']

    for root, dirs, files in os.walk(start_path):
        for file in files:
            if file.endswith(".j2") and not any(os.path.commonpath([exclude_dir, root]) == exclude_dir for exclude_dir in exclude_dirs):
                template_path = os.path.join(root, file)

                print("Rendering: " + template_path)

                # Create a template object by reading the file
                template = env.get_template(template_path)

                # Render the template
                rendered_content = template.render(**configs, exec=exec, os=os)
                if not rendered_content:
                    print(f'Warning jinja2: {template_path} - Empty')

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
                    output_file.write(str(rendered_content))

                # print(f'Rendered and stored: {output_file_path}')


start_path = "/opt/hiddify-manager/"

if len(sys.argv) > 1 and sys.argv[1] == "apply_users":
    render_j2_templates(start_path + "singbox/")
    render_j2_templates(start_path + "other/wireguard/")
else:
    render_j2_templates(start_path)
