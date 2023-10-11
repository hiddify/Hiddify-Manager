# sync_panel:
# 	@bash -c '\
# 	cd hiddify-panel/src && \
# 	git pull'


release:
	@echo "previous version was $$(git describe --tags $$(git rev-list --tags --max-count=1))"
	@echo "WARNING: This operation will creates version tag and push to github"
	@bash -c '\
	read -p "Version? (provide the next x.y.z semver) : " TAG && \
	echo $$TAG &&\
	[[ "$$TAG" =~ ^[0-9]{1,2}\.[0-9]{1,2}\.[0-9]{1,2}(\.dev)?$$ ]] || { echo "Incorrect tag. e.g., 1.2.3 or 1.2.3.dev"; exit 1; } && \
	IFS="." read -r -a VERSION_ARRAY <<< "$$TAG" && \
	VERSION_STR="$${VERSION_ARRAY[0]}.$${VERSION_ARRAY[1]}.$${VERSION_ARRAY[2]}" && \
	echo "version: $${VERSION_STR}+$${BUILD_NUMBER}" && \
	echo "${TAG}" > VERSION && \
	git tag $${TAG} > /dev/null && \
	gitchangelog > HISTORY.md || { git tag -d $${TAG}; echo "Please run pip install git gitchangelog pystache mustache markdown"; exit 2; } && \
	git tag -d $${TAG} > /dev/null && \
	git add VERSION HISTORY.md && \
	git commit -m "release: version $${TAG} 🚀" && \
	echo "creating git tag : v$${TAG}" && \
	git tag v$${TAG} && \
	git push -u origin HEAD --tags && \
	echo "Github Actions will detect the new tag and release the new version."'
	

