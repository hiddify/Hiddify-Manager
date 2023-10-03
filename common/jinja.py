import os
from jinja2 import Environment, FileSystemLoader

with open('/opt/hiddify-server/current.json') as f:
    configs = json.load(f)


def render_j2_templates(start_path):
    # Set up the Jinja2 environment
    env = Environment(loader=FileSystemLoader('/'))

    for root, dirs, files in os.walk(start_path):
        for file in files:
            if file.endswith('.j2'):
                # Create a template object by reading the file
                template_path = os.path.join(root, file)
                template = env.get_template(template_path)

                # Render the template
                rendered_content = template.render(**configs)

                # Write the rendered content to a new file without the .j2 extension
                output_file_path = os.path.splitext(template_path)[0]
                with open(output_file_path, 'w') as output_file:
                    output_file.write(rendered_content)

                # print(f'Rendered and stored: {output_file_path}')


start_path = '/opt/hiddify-server/'
render_j2_templates(start_path)
