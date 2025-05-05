#
# MIT License
#
# (C) Copyright 2021-2025 Hewlett Packard Enterprise Development LP
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

CHART_DIR ?= charts
CHART_DIRS := $(wildcard $(CHART_DIR)/*)
CHARTS := $(patsubst $(CHART_DIR)/%,%,$(CHART_DIRS))

# Fo each chart, version is evaluated and written into CHART_VERSION_chart_name variable, if this variable is not set externally.
$(foreach CHART,$(CHARTS),$(eval CHART_VERSION_$(subst -,_,$(CHART)) ?= $$(lastword $$(shell grep ^version: $(CHART_DIR)/$(CHART)/Chart.yaml))))
CHART_PACKAGES := $(foreach CHART,$(CHARTS),packages/$(CHART)-$(CHART_VERSION_$(subst -,_,$(CHART))).tar.gz)

HELM_IMAGE ?= artifactory.algol60.net/docker.io/alpine/helm:3.7.1
ifeq ($(shell uname -s),Darwin)
	HELM_CONFIG_HOME ?= $(HOME)/Library/Preferences/helm
else
	HELM_CONFIG_HOME ?= $(HOME)/.config/helm
endif
COMMA := ,

all: $(CHART_PACKAGES)

packages/%.tar.gz:
	$(eval CHART_NAME := $(shell basename $@ | sed -e 's/-[0-9].*//'))
	$(eval CHART_VERSION := $(shell basename $@ | sed -e 's/[^0-9]*-//' | sed -e 's/\.tar\.gz//'))
	docker run --rm \
	    --user $(shell id -u):$(shell id -g) \
	    --mount type=bind,src="$(shell pwd)",dst=/src \
	    $(if $(wildcard $(HELM_CONFIG_HOME)/.),--mount type=bind$(COMMA)src=$(HELM_CONFIG_HOME)$(COMMA)dst=/tmp/.helm/config) \
	    -w /src \
	    -e HELM_CACHE_HOME=/src/.helm/cache \
	    -e HELM_CONFIG_HOME=/tmp/.helm/config \
	    -e HELM_DATA_HOME=/src/.helm/data \
	    $(HELM_IMAGE) \
	    package $(CHART_DIR)/$(CHART_NAME) \
		--version $(CHART_VERSION) \
		-d packages

clean:
	$(RM) -r .helm packages
