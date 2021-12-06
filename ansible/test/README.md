# EWF AMI testing

A simple docker setup to cover testing of Ansible.

This should provide enough coverage to locally test functionality of most changes to configuration code.

To test, first ensure you have all required dependancies installed:

`ansible-galaxy install -r requirements.yml`

`ansible-galaxy install -r ../requirements.yml`

Then we can execte the playbook. This will create a docker container based on Centos 6.10 and execute the playbook.

`ansible-playbook main.yml`

