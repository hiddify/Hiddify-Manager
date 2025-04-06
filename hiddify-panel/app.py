#!/opt/hiddify-manager/.venv313/bin/python

if __name__ == "__main__":
    import bjoern
    import hiddifypanel
    bjoern.run(wsgi_app=hiddifypanel.create_app(), host="127.0.0.1", port=9000)
