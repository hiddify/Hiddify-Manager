.ONESHELL:

debug: build debug-panel

debug-panel: 
	(cd hiddify-panel/src/ &&\
	systemctl stop hiddify-panel &&\
	HIDDIFY_CFG_PATH=/opt/hiddify-manager/hiddify-panel/app.cfg \
	FLASK_APP=wsgi.py \
	FLASK_DEBUG=1 \
	python -m flask run --host=0.0.0.0 --port=9000 --reload\

apply:
	@if [ "$(PWD)" = "/opt/hiddify-manager" -o "$(PWD)" = "/opt/hiddify-config" ]; then \
		echo "You cannot build from /opt/hiddify-manager. Clone the repository outside this folder."; \
		exit 2; \
	else \
		mkdir -p /opt/hiddify-manager && \
		cp -r ./* /opt/hiddify-manager/ && \
		rm -rf /opt/hiddify-manager/hiddify-panel/src/; \
		export HIDDIFY_DEBUG=1 && \
		export HIDDIFY_PANLE_SOURCE_DIR="$(PWD)/hiddify-panel/src/" &&\
		(cd /opt/hiddify-manager/hiddify-panel && bash install.sh && bash run.sh && bash ../common/replace_variables.sh); 	
	fi
.PHONY: apply
build: apply
	
	(cd /opt/hiddify-manager/ && bash install.sh --no-gui); 


# sync_panel:
# 	@bash -c '\
# 	cd hiddify-panel/src && \
# 	git pull'
latest-tags:
	@tags=$$(git for-each-ref --sort=-creatordate --format='%(refname:short)' refs/tags); \
	stable=""; beta=""; \
	for tag in $$tags; do \
	  echo $$tag | grep -qE '^v[0-9]+\.[0-9]+\.[0-9]+$$' && [ -z "$$stable" ] && stable=$$tag; \
	  echo $$tag | grep -qE '^v[0-9]+\.[0-9]+\.[0-9]+(b|\.dev)[0-9]+$$' && [ -z "$$beta" ] && beta=$$tag; \
	  [ "$$beta" != "" ] && [ "$$stable" != "" ] && break; \
	done; \
	echo "Stable: $${stable:-❌} | Beta: $${beta:-❌}"


dev:
	@echo "dev" > VERSION
	@gitchangelog > HISTORY.md || { git tag -d $${TAG}; echo "Please run pip install gitchangelog pystache mustache markdown"; exit 2; } 
	@make -C ./hiddify-panel/src dev
	@git add VERSION HISTORY.md hiddify-panel/src
	@git commit -m "release: switch to develop"

.PHONY: release
release: latest-tags
	@if [ -z "$$VIRTUAL_ENV" ]; then \
		echo "❌ Python virtual environment is NOT active. Please activate it first."; \
		exit 1; \
	fi
ifeq ($(TAG),)
	@echo "WARNING: This operation will create s version tag and push to github"
	@read -p "Version? (provide the next x.y.z semver) : " TAG
endif
	@VERSION_STR=$$(echo $$TAG | grep -Eo '^[0-9]{1,2}\.[0-9]{1,2}\.[0-9]{1,2}((b)[0-9]{1,2})?') 
	[ ! -z "$$VERSION_STR" ] || { echo "Incorrect tag. e.g., 1.2.3 or 1.2.3b1"; exit 1; } 
	@echo "$${TAG}" > VERSION 
	@make -C ./hiddify-panel/src release TAG=$${TAG}
	@git tag $${TAG} > /dev/null
	@gitchangelog > HISTORY.md || { git tag -d $${TAG}; echo "Please run pip install gitchangelog pystache mustache markdown"; exit 2; } 
	@git tag -d $${TAG} > /dev/null
	@git add VERSION HISTORY.md hiddify-panel/src
	@git commit -m "release: version $${TAG} 🚀" 
	@echo "creating git tag : v$${TAG}" 
	@git tag v$${TAG} 
	@git push -u origin HEAD --tags 
	@git checkout beta && git pull && git rebase dev && git push;
	@if ! echo "$${VERSION_STR}" | grep -q "b"; then \
		git checkout main && git rebase dev && git push; \ 
	fi
	@git checkout dev
	@echo "Github Actions will detect the new tag and release the new version."
	