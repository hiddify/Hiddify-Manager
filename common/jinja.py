import os
from jinja2 import Environment, FileSystemLoader
import json5
import json
import subprocess
with open('c:/users/me/desktop/current.json') as f:
    configs = json.load(f)


def exec(command):
    try:
        output = subprocess.check_output(command, shell=True, stderr=subprocess.STDOUT, text=True)
        return output
    except subprocess.CalledProcessError as e:
        print(f"Command failed with exit code {e.returncode}:")
        print(e.output)
    return ""

def render_j2_templates(start_path):
    # Set up the Jinja2 environment
    env = Environment(loader=FileSystemLoader('/'))
    
    for root, dirs, files in os.walk(start_path):
        for file in files:
            if file.endswith('.j2'):
                print("Rendering: " + file)
                # Create a template object by reading the file
                template_path = os.path.join(root, file)
                template = env.get_template(template_path)

                # Render the template
                rendered_content = template.render(**configs, exec=exec)

                # Write the rendered content to a new file without the .j2 extension
                output_file_path = os.path.splitext(template_path)[0]
                if output_file_path.endswith('.json'):
                    # remove trailing comma and comments from json
                    try:
                        json5object = json5.loads(rendered_content)
                        rendered_content = json5.dumps(json5object, trailing_commas=False, indent=2, quote_keys=True)
                    except Exception as e:
                        print(f"Error parsing json: {e}")

                with open(output_file_path, 'w',encoding='utf-8') as output_file:
                    output_file.write(rendered_content)

                # print(f'Rendered and stored: {output_file_path}')


start_path = '/Users/me/Hiddify-Server/other/telegram/tgo/'
render_j2_templates(start_path)
