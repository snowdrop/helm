SHELL=/bin/sh -e
// Add list of charts: "chart1" "chart2" ...
CHARTS := "spring-boot-example-app"
DESTINATION_FOLDER := "charts/"

.PHONY: release
release:
	@for chart in $(CHARTS) ; do \
		chartFolder=$(PWD)/repository/$$chart; \
		chartVersion=`grep '^version:' $$chartFolder/Chart.yaml | awk '{print $2}'`; \
		echo Chart $$chart - $$chartVersion ; \
		helm package $$chartFolder -d $(DESTINATION_FOLDER) ; \
	done

	cd $(DESTINATION_FOLDER)
	helm repo index --url http://snowdrop.github.io/helm --merge index.yaml .
	cd ..