# Instructions for AI coding assistants

Read [DEVELOPMENT.md](DEVELOPMENT.md) first: the setup, where things are, how to test and commit.

- The repository is checked out at `/opt/hiddify-manager`; the panel is the submodule `services/panel/src`.
- Never edit `data/` or `generated/`: they are state and generated output.
- Admin UI changes go in `services/panel/src/hiddifypanel/admin_v2` only (the Flask-Admin pages are legacy).
- Ask before restarting services: a panel restart migrates the server's database.
