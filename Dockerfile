FROM python:3.6 as build

ARG PIP_INDEX_URL
ARG ARTIFACTORY_PRO_AUTH
ARG NPM_CONFIG__AUTH
ARG NPM_CONFIG_REGISTRY=https://workivaeast.jfrog.io/workivaeast/api/npm/npm-prod/
ARG NPM_CONFIG_ALWAYS_AUTH=true

COPY requirements-dev.txt ./requirements-dev.txt
COPY requirements.txt ./requirements.txt
RUN pip install -r requirements-dev.txt

WORKDIR /build/
ADD . /build/

# build ixbrlviewer.js
RUN apt-get update && apt-get install -y curl && \
    curl -sL https://deb.nodesource.com/setup_10.x | bash && \
    apt-get install -y nodejs build-essential
RUN npm install
RUN make prod

# javascript tests
RUN npm run test

# python tests
ARG BUILD_ARTIFACTS_TEST=/test_reports/*.xml
RUN mkdir /test_reports
RUN nosetests --with-xunit --xunit-file=/test_reports/results.xml --cover-html tests.unit_tests

# pypi package creation
ARG BUILD_ARTIFACTS_PYPI=/build/dist/*.tar.gz
RUN python setup.py sdist

ARG BUILD_ARTIFACTS_AUDIT=/audit/*
RUN mkdir /audit/
RUN pip freeze > /audit/pip.lock

FROM scratch
