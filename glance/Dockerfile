FROM alpine
RUN apk add -U python py-pip py-crypto curl curl-dev gcc python-dev musl-dev py-openssl openssl-dev \
	nss nss-dev py-cffi libffi-dev linux-headers swig && \
	pip install --upgrade pip && \
	for package in pbr vcversioner setuptools-scm python-keystoneclient python-novaclient python-cinderclient python-glanceclient supernova; do \
	pip install --upgrade $package; done && \
	apk del openldap-dev curl curl-dev gcc python-dev nss nss-dev musl-dev openssl-dev libffi-dev linux-headers swig && \
	apk add -U py-setuptools && \
	rm -rf /var/cache/apk*

ENTRYPOINT ["/usr/bin/supernova"]
