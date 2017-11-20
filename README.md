# Role to create a Concierge managed image 



## Using this role

This role wraps up some common roles for creating Docker images ready to be used in a Concierge Paradigm environment

If ran manually, there is a concierge-image.yml file which can be passed to ansible-playbook but many of the required variables 
and files will need to be set up locally.

Primarily the role generates a Dockerfile, a set of Docker Compose files and a Containerpilot file. Then builds an image and run 
a set of tests against the build.

There are a few template examples in the templates directory and any files in these subdirectories with a .j2 suffix will be processed.

The docker file has some default attributes set and allows for others to be included by creating the required lists or variables.

Currently these are as follows:

* install_script (string) = the location of the script required to install the application you want to package into the image
* env_vars (list) = a list of additional environment variables. E.g. env_vars: FOO=bar
* build_args (list) = a list of additional Docker ARG options for required variables when building
* labels (list) = a list of additional labels to add to the container 
* ports (list) =  a list of ports to expose
* volumes (list) = a list of volume the container should create
* entrypoint (string) = process or script to run as ENTRYPOINT. For the concierge containers, it is assumed that unless you're creating a base image, this will always be containerpilot and already set in the base image
* command (string) = process or script to run as CMD. For the concierge containers, it is assumed that generally this will be passed via orchestration files like docker-compose.yml
* Options like mem_limit are best added to compose files but other options may be added at a later date
* custom_orchestration_dir = the location where you want your custom orchestration config template to output to. Defaults to the playbook root

## Setting up
### Clone the repository
```
mkdir my-app-name
cd my-app-name
git clone https://github.com/mesoform/configure-concierge-app.git .
```
### Set Docker environment variables to Docker socket
stuff

### Run the setup script to set up the playbook for your application
```
./setup.sh  --initialise-git
```

### Add custom files to the right directories
{{ playbook_dir }}/files/bin  
{{ playbook_dir }}/files/etc  
{{ playbook_dir }}/files/test  
{{ playbook_dir }}/templates/app  
{{ playbook_dir }}/templates/orchestration  
{{ playbook_dir }}/vars  

### Configure any variables you need

### Run the playbook
```
ansible-playbook -v app.yml
```

### Once finished
Simply run:
```docker-compose up```

### Update your documentation
{{ playbook_dir }}/README.MD
