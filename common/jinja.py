import os
import json
import hiddifypanel

from jinja2 import Environment, FileSystemLoader


def render_j2_templates(start_path: str, configs: dict) -> None:
    # Set up the Jinja2 environment
    env = Environment(loader=FileSystemLoader('/'))

    for root, dirs, files in os.walk(start_path):
        for file in files:
            if file.endswith('.j2'):
                # Create a template object by reading the file
                template_path = os.path.join(root, file)
                template = env.get_template(template_path, **configs)

                # Render the template
                rendered_content = template.render()

                # Write the rendered content to a new file without the .j2 extension
                output_file_path = os.path.splitext(template_path)[0]
                with open(output_file_path, 'w') as output_file:
                    output_file.write(rendered_content)

                # print(f'Rendered and stored: {output_file_path}')


def deep_defaults(configs: dict, defaults: dict):
    for k, v in defaults.items():
        if k not in configs:
            configs[k] = v
        elif type(k) == "dict":
            deep_defaults(configs[k], v)


def main() -> None:
    with open('/opt/hiddify-server/current.json') as f:
        configs: dict = json.load(f)

    with open('/opt/hiddify-server/defaults.json') as f:
        defaults: dict = json.load(f)

    defaults['hconfig']['panel_static_root'] = os.path.dirname(hiddifypanel.__file__) + '/static'
    deep_defaults(configs, defaults)

    start_path = '/opt/hiddify-server/'
    render_j2_templates(start_path, configs)


if __name__ == '__main__':
    main()
