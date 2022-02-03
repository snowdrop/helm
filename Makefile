SHELL=/bin/sh -e
// Add list of charts: "chart1" "chart2" ...
CHARTS := "spring-boot-example-app"
SNOWDROP_GITHUB_ORG := "https://github.com/snowdrop"
REMOTE_CHARTS := "cache-example" "circuit-breaker-example" "configmap-example" "crud-example" "health-check-example" "messaging-work-queue-example" "rest-http-example"
CURRENT_FOLDER := "$(PWD)"
DESTINATION_FOLDER := "charts/"

# Example: make release
.PHONY: release
release:
	@for chart in $(CHARTS) ; do \
		chartFolder=$(PWD)/repository/$$chart; \
		chartVersion=`grep '^version:' $$chartFolder/Chart.yaml | awk '{print $2}'`; \
		echo Chart $$chart - $$chartVersion ; \
		helm package $$chartFolder -d $(DESTINATION_FOLDER) ; \
	done

	make update-index

# Example: make release-examples branch=sb-2.5.x chartVersion=2.5.8
.PHONY: release-examples
release-examples:
	@for chart in $(REMOTE_CHARTS) ; do \
		chartFolder=$(PWD)/repository/$$chart; \
		rm -rf $$chartFolder; \
		git clone $(SNOWDROP_GITHUB_ORG)/$$chart $$chartFolder; \
		cd $$chartFolder; \
		git checkout $(branch); \
		cd $(CURRENT_FOLDER); \
		echo Chart $$chart - $(chartVersion) ; \
		helm package --version $(chartVersion) $$chartFolder/helm -d $(DESTINATION_FOLDER) ; \
		rm -rf $$chartFolder; \
	done

	make update-index

.PHONY: update-index
update-index:
	cd $(DESTINATION_FOLDER)
	rm -f index-cache.yaml
	helm repo index --url https://snowdrop.github.io/helm --merge index.yaml .
	cd $(CURRENT_FOLDER)
