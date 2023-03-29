#
# MIT License
#
# (C) Copyright {{cookiecutter.year}} Hewlett Packard Enterprise Development LP
#
# Permission is hereby granted, free of charge, to any person obtaining a
# copy of this software and associated documentation files (the "Software"),
# to deal in the Software without restriction, including without limitation
# the rights to use, copy, modify, merge, publish, distribute, sublicense,
# and/or sell copies of the Software, and to permit persons to whom the
# Software is furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included
# in all copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL
# THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR
# OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE,
# ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR
# OTHER DEALINGS IN THE SOFTWARE.
#
NAME ?= kyverno-policy

CHART_VERSION ?= $(VERSION)
IMAGE ?= artifactory.algol60.net/csm-docker/stable/${NAME}

CHARTDIR ?= charts

CHART_METADATA_IMAGE ?= artifactory.algol60.net/csm-docker/stable/chart-metadata
YQ_IMAGE ?= artifactory.algol60.net/docker.io/mikefarah/yq:4
HELM_IMAGE ?= artifactory.algol60.net/docker.io/alpine/helm:3.7.1
HELM_UNITTEST_IMAGE ?= artifactory.algol60.net/docker.io/quintush/helm-unittest
HELM_DOCS_IMAGE ?= artifactory.algol60.net/docker.io/jnorwood/helm-docs:v1.5.0
ifeq ($(shell uname -s),Darwin)
	HELM_CONFIG_HOME ?= $(HOME)/Library/Preferences/helm
else
	HELM_CONFIG_HOME ?= $(HOME)/.config/helm
endif
COMMA := ,

all: chart

chart: chart-package chart-test

helm:
	docker run --rm \
	    --user $(shell id -u):$(shell id -g) \
	    --mount type=bind,src="$(shell pwd)",dst=/src \
	    $(if $(wildcard $(HELM_CONFIG_HOME)/.),--mount type=bind$(COMMA)src=$(HELM_CONFIG_HOME)$(COMMA)dst=/tmp/.helm/config) \
	    -w /src \
	    -e HELM_CACHE_HOME=/src/.helm/cache \
	    -e HELM_CONFIG_HOME=/tmp/.helm/config \
	    -e HELM_DATA_HOME=/src/.helm/data \
	    $(HELM_IMAGE) \
	    $(CMD)

chart-package: packages/${NAME}-${CHART_VERSION}.tgz

packages/${NAME}-${CHART_VERSION}.tgz:
	CMD="dep up ${CHARTDIR}/${NAME}" $(MAKE) helm
	CMD="package ${CHARTDIR}/${NAME} -d packages" $(MAKE) helm

chart-test:
	CMD="lint ${CHARTDIR}/${NAME}" $(MAKE) helm
	docker run --rm -v ${PWD}/${CHARTDIR}:/apps ${HELM_UNITTEST_IMAGE} ${NAME}

snyk:
	$(MAKE) -s chart-images | xargs --verbose -n 1 snyk container test

chart-gen-docs:
	docker run --rm \
	    --user $(shell id -u):$(shell id -g) \
	    --mount type=bind,src="$(shell pwd)",dst=/src \
	    -w /src \
	    $(HELM_DOCS_IMAGE) \
	    helm-docs --chart-search-root=$(CHARTDIR)

clean:
	$(RM) -r .helm packages
