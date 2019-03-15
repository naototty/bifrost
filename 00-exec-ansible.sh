#!/bin/bash


pushd playbooks

ansible-playbook -vvv -i inventory/target install.yaml \
  -e network_interface=eth0 \
  -e extra_dib_elements=devuser \
  -e ipa_upstream_release=stable-queens \
  -e dib_os_release=xenial \
  -e dib_os_element=ubuntu-minimal \

##  -e staging_drivers_include=true

popd
