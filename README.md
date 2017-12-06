# Role to create a Concierge managed image 
## Introduction
The [Concierge Paradigm](http://www.mesoform.com/blog-listing/info/the-concierge-paradigm) is a powerful method of automating the management
of running containers by simply using a service discovery system like Consul, and an event management system, like Zabbix. By using these, 
already well developed systems, you gain incredible control and information about the state of the system as a whole and fine-grained detail
of all applications.

A concierge managed application is one that fits naturally into this concierge environment and automatically registers itself for discovery,
monitoring and scheduling.  This playbook asks only a few simple questions about your application and the environment in which you expect to 
run it in, then spits out a Docker image at the end and performs the required system and integration tests to be Concierge managed and any
custom tests you require for your application.


## About this role

Primarily the role generates a Dockerfile, a set of Docker Compose files and a Containerpilot file. Then builds an image and runs 
a set of tests against the build. It wraps up some other common roles for creating our Docker images ready to be used in a Concierge Paradigm 
environment.  The role has been split into 4 parts:
1. configure-concierge-repo: This repository. The purpose of which is to get you your own custom repository setup to start building your
application container
1. create-concierge-app: This submodule role takes the variables, scripts and any files needed for your application and constructs the necessary
application configuration files (if using templates) and orchestration files for managing the lifecycle of your application.
1. create-concierge-image: Constructs our Dockerfile and builds our image.
1. create-concierge-tests: Performs basic system tests, integration to service discovery and event management. Plus any user-defined application tests


The Dockerfile has some default attributes automatically set and allows for others to be included by creating the required lists or variables.

Currently these are as follows:
* os_distro (string) = The flavour of operating system. Current options are `alpine` and `debian` - versions *3.4* and *jessie*, respectively
* install_scripts (list) = the location of the script or scripts to install the application you want to package into the image. A list is used so 
as to logically separate different install steps into separate RUN commands and better make use of UnionFS image layers
* build_args (list) = a list of additional Docker ARG options for required variables when building
* container_vars (list) = a list of environment variables which will be set as defaults inside the running container. E.g. container_vars: FOO=bar
* env_vars (list) = a list of additional environment variables which will be passed to the container at runtime. E.g. env_vars: FOO=bar
* labels (list) = a list of additional labels to add to the container 
* ports (list) =  a list of ports to expose
* volumes (list) = a list of volume the container should create
* entrypoint (string) = process or script to run as ENTRYPOINT. For the concierge containers, it is assumed that unless you're creating a base 
image, this will always be containerpilot and already set in the base image
* command (string) = process or script to run as CMD. For the concierge containers, it is assumed that generally this will be passed via 
orchestration files like docker-compose.yml
* custom_orchestration_dir = the location where you want your custom orchestration config template to output to. Defaults to the playbook root
* Options like mem_limit are best added to compose files but other options may be added at a later date
* See vars/main.yml and defaults/main.yml for others variables and their descriptions

## Setting up
### Clone the repository
```
cd {{ roles_dir }}
mkdir my-app-name
cd my-app-name
git clone https://github.com/mesoform/configure-concierge-app.git .
```

### Submodules
Within this playbook there are some additional roles included as git submodules. These modules are synchronised with their upstream 
repositories every time you run the playbook and any changes you made locally will be stashed. Every effort is made to make these submodule
roles backward compatible but sometimes things accidents happen and sometimes its just not feasible. We've added some output messages to indicate
 that changes have happened but also advise that you watch the included each roles'repositories as well.

If you want to run the playbook without doing this, either remove the relevant entry from .gitmodules or run with `--skip-tags=update_submodules`

### Set Docker environment variables to Docker socket
TBD

### Run the setup script to set up the playbook for your application
```
./setup.sh  --initialise-git
```

### Add custom files to the right directories
{{ playbook_dir }}/files/bin  
{{ playbook_dir }}/files/etc  
{{ playbook_dir }}/files/test
#### Custom application configuration templates
Any Jinja2 templates added to `{{ playbook_dir }}/templates/app` with the `.j2` extension will automatically be processed and uploaded 
to the application configuration directory (default = /etc/{{ project_name }}). You can find an example of one already in the directory
#### Custom application orchestration templates
Any Jinja2 templates added to `{{ playbook_dir }}/templates/orchestration` with the `.j2` extension will automatically be processed and
uploaded to the application orchestration directory (default = /etc). You can find an example of one already in the directory


### Configure any variables you need
{{ playbook_dir }}/vars  

### Run the playbook
```
ansible-playbook -v app.yml
```

### Once finished
Simply run:
```docker-compose up```

### Update your documentation
{{ playbook_dir }}/README.MD

## Customising
If you want to create your own templates ([Jinja2](http://jinja.pocoo.org)), there are a few template examples in the templates directory
 and any files in these subdirectories with a .j2 suffix will be processed.
### Base images
We maintain [Docker base images](https://hub.docker.com/u/mesoform/dashboard/) which provide the necessary agents for running a Concierge managed 
container. It is recommended that you use these but if you want to manage your own, take a look at the
 [Dockerfile for one of the images](https://hub.docker.com/r/mesoform/concierge-debian-base-image/~/dockerfile/) and then specify your new image by
  setting the `base_image_name: your-image-repo:your-image-version` key in your variables file. Otherwise, leave this unset and just change
   `os_distro` to pick up the latest stable version of that flavour.


## Testing
If ran manually, there is a concierge-image.yml file which can be passed to ansible-playbook but many of the required variables 
and files will need to be set up locally.
