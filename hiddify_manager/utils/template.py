"""
Jinja2 template rendering for Hiddify-Manager.

Mirrors the rendering rules used by common/jinja.py (b64encode/quote/hexencode
filters, `enumerate` global, shell `exec` helper) but uses dynamic paths and
exposes a function-call API instead of a CLI entry point. Module installers
should call render_template() / render_tree() rather than shelling out to
common/jinja.py.
"""
import base64
import os
import subprocess
import sys
import traceback
from concurrent.futures import ProcessPoolExecutor
from urllib.parse import quote

from jinja2 import Environment, FileSystemLoader

from hiddify_manager.utils.logger import log
from hiddify_manager.utils.paths import PROJECT_ROOT


def _shell_exec(command):
    try:
        return subprocess.check_output(
            command, shell=True, stderr=subprocess.STDOUT, text=True
        )
    except subprocess.CalledProcessError as e:
        log.error(f"template exec failed ({command!r}): rc={e.returncode}")
        return ""


def _b64encode(s):
    if isinstance(s, str):
        s = s.encode("utf-8")
    return base64.b64encode(s).decode("utf-8")


def _build_env(search_paths=None):
    # singbox/configs/ ships an `includes/` dir consumed by {% include
    # "includes/multiplex.json.pj2" %} from sibling templates; the legacy
    # common/jinja.py shipped this in its loader paths so the relative
    # include resolves. Keep parity.
    paths = [
        PROJECT_ROOT,
        os.path.join(PROJECT_ROOT, "singbox", "configs"),
        "/",
    ]
    if search_paths:
        paths = list(search_paths) + paths
    env = Environment(loader=FileSystemLoader(paths))
    env.globals["enumerate"] = enumerate
    env.filters["b64encode"] = _b64encode
    env.filters["quote"] = lambda s: quote(s, safe="")
    env.filters["hexencode"] = lambda s: "".join(
        hex(ord(c))[2:].zfill(2) for c in s
    )
    return env


def _prepare_configs(configs):
    """Match common/jinja.py: cast chconfigs keys to int and surface hconfigs."""
    if not configs:
        return {}
    out = dict(configs)
    chconfigs = out.get("chconfigs")
    if isinstance(chconfigs, dict):
        try:
            out["chconfigs"] = {int(k): v for k, v in chconfigs.items()}
            out["hconfigs"] = out["chconfigs"].get(0, {})
        except (TypeError, ValueError):
            pass
    return out


def _sanitize_json_output(path, body):
    """
    Many singbox/xray templates rely on json5-style trailing commas and
    comments that strict JSON parsers reject. The legacy common/jinja.py
    re-parsed the rendered text as json5 and re-emitted it as canonical
    JSON. Mirror that here for any output that ends in .json.

    Returns the sanitized text. On parse error, returns the original body
    (so the caller still writes *something* — diagnosing a bad template is
    easier when the broken file is on disk).
    """
    if not path.endswith(".json") or not body.strip():
        return body
    try:
        import json5
    except ImportError:
        log.warning("template: json5 not installed; skipping JSON sanitize")
        return body
    try:
        obj = json5.loads(body)
    except Exception as e:
        log.error(f"template: {path} produced invalid json5: {e}")
        return body
    return json5.dumps(obj, trailing_commas=False, indent=2, quote_keys=True)


def render_template(template_path, configs, output_path=None, env=None):
    """
    Render a single .j2 template to its non-.j2 path (or output_path), copying
    mode/ownership from the source. Returns the output path, or None on error.
    """
    # Add the template's own directory so {% include "sibling.j2" %} works
    # without forcing the caller to set up search paths.
    env = env or _build_env(search_paths=[os.path.dirname(template_path)])
    ctx = _prepare_configs(configs)
    try:
        with open(template_path, "r", encoding="utf-8") as f:
            template = env.from_string(f.read())
        rendered = template.render(**ctx, exec=_shell_exec, os=os)
        if output_path is None:
            output_path = os.path.splitext(template_path)[0]
        rendered = _sanitize_json_output(output_path, str(rendered))
        with open(output_path, "w", encoding="utf-8") as out:
            out.write(rendered)
        st = os.stat(template_path)
        os.chmod(output_path, st.st_mode)
        try:
            os.chown(output_path, st.st_uid, st.st_gid)
        except (PermissionError, AttributeError):
            pass
        return output_path
    except Exception as e:
        log.error(f"Error rendering {template_path}: {e}")
        traceback.print_exc(file=sys.stderr)
        return None


def render_tree(roots, configs, exclude_dirs=None, workers=4):
    """
    Walk one or more directory roots and render every *.j2 file in place.
    Mirrors common/jinja.py.render_j2_templates().
    """
    exclude_dirs = list(exclude_dirs or [])
    exclude_dirs += [
        os.path.join(PROJECT_ROOT, ".venv"),
        os.path.join(PROJECT_ROOT, ".venv313"),
        os.path.join(PROJECT_ROOT, "hiddify-panel", "src"),
    ]
    targets = []
    for root in roots:
        for dirpath, _, files in os.walk(root):
            if any(ex in dirpath for ex in exclude_dirs):
                continue
            for name in files:
                if name.endswith(".j2"):
                    targets.append(os.path.join(dirpath, name))

    if not targets:
        return []

    if workers <= 1:
        return [render_template(t, configs) for t in targets]

    with ProcessPoolExecutor(workers) as pool:
        return list(pool.map(_render_one, [(t, configs) for t in targets]))


def _render_one(args):
    path, configs = args
    return render_template(path, configs)
