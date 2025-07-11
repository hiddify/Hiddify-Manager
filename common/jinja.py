#!/opt/hiddify-manager/.venv313/bin/python
import base64
import os
import sys
import threading
from jinja2 import Environment, FileSystemLoader
import json5
import json
import subprocess
from concurrent.futures import ProcessPoolExecutor, ThreadPoolExecutor
import traceback
from urllib.parse import quote

with open("/opt/hiddify-manager/current.json") as f:
    configs = json.load(f)
    configs["chconfigs"] = {int(k): v for k, v in configs["chconfigs"].items()}
    configs["hconfigs"] = configs["chconfigs"][0]


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

env_paths = ["/", "/opt/hiddify-manager/singbox/configs/"]
env = Environment(loader=FileSystemLoader(env_paths))
def render(template_path):
    try:
        env.globals['enumerate'] = enumerate 
        env.filters["b64encode"] = b64encode
        env.filters['quote'] = lambda s: quote(s,safe='')
        env.filters["hexencode"] = lambda s: "".join(
            hex(ord(c))[2:].zfill(2) for c in s
        )
        print("Rendering: " + template_path)

        # Create a template object by reading the file
        template = env.get_template(template_path)
        threading.current_thread().name

        # Render the template
        rendered_content = template.render(**configs, exec=exec, os=os)
        
        #     print(f"Warning jinja2: {template_path} - Empty")

        # Write the rendered content to a new file without the .j2 extension
        output_file_path = os.path.splitext(template_path)[0]
        if rendered_content and output_file_path.endswith(".json"):
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
                print(f"Error parsing json {template_path}: {e}", file=sys.stderr)

        with open(output_file_path, "w", encoding="utf-8") as output_file:
            output_file.write(str(rendered_content))

        input_stat = os.stat(template_path)
        os.chmod(output_file_path, input_stat.st_mode)
        # os.chmod(output_file_path, 0o600)
        os.chown(output_file_path, input_stat.st_uid, input_stat.st_gid)
    except Exception as e:
        print(f"Error rendering {template_path}: {e}", file=sys.stderr)
        traceback.print_exc(file = sys.stderr)


def render_j2_templates(*start_paths):
    # Set up the Jinja2 environment

    # Dirs to ignore from Jinja2 rendering
    exclude_dirs = [
        "/opt/hiddify-manager/.venv",
        "/opt/hiddify-manager/hiddify-panel/src/",
    ]

    # Collect all the template paths to render
    templates_to_render = []
    for start_path in start_paths:
        for root, dirs, files in os.walk(start_path):
            for file in files:
                if not file.endswith(".j2"):
                    continue
                if any(exclude_dir in root for exclude_dir in exclude_dirs):
                    continue
                templates_to_render.append(os.path.join(root, file))

    # Render templates in parallel using ThreadPoolExecutor
    with ProcessPoolExecutor(4) as executor:
        executor.map(render, templates_to_render)
    # for t in templates_to_render:
    #     render(t)

start_path = "/opt/hiddify-manager/"
if __name__ == "__main__":
    if len(sys.argv) > 1 and sys.argv[1] == "apply_users":
        render_j2_templates(
            start_path + "singbox/", start_path + "xray/", start_path + "other/wireguard/"
        )
    else:
        render_j2_templates(start_path)
