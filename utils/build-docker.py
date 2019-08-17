#!/usr/bin/env python
from setuptools_scm import get_version
from packaging.version import Version
import os
import sys


def run(cmd):
    print(cmd)
    r = os.system(cmd)
    if r:
        print("ERROR: command returned {0}".format(r))
        sys.exit(r)


if __name__ == "__main__":

    version = get_version()
    version_tag = version.replace("+", "-")
    image_name = os.environ.get('QUAY_REPO', 'quay.io/ansible/molecule')

    expire = ""
    if Version(version).is_prerelease:
        expire = "--label quay.expires-after=2w"
        mobile_tag = "master"
    else:
        mobile_tag = "latest"

    print("Building version {0}".format(version_tag))
    run(
        "docker build --network host --pull "
        "-t {0}:{1} -t {0}:master {2} .".format(image_name, version_tag, expire)
    )

    # Decide to push when all conditions below are met:
    if os.environ.get('TRAVIS_BUILD_STAGE_NAME', None) == 'deploy':
        run("docker login quay.io")
        run("docker push {0}:{1}".format(image_name, version_tag))
        if os.environ.get('TRAVIS_BRANCH', None) == 'master':
            run("docker push {0}:{1}".format(image_name, mobile_tag))
            # if we are a full release on master branch
            if not Version(version).is_prerelease:
                run("docker tag {0}:{1} {0}:latest".format(image_name, version_tag))
                run("docker push {0}:latest".format(image_name))
