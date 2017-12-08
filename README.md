# Role to create an image for a Concierge managed application 
## Introduction
The [Concierge Paradigm](http://www.mesoform.com/blog-listing/info/the-concierge-paradigm) is an extension of 
[The Autopilot Pattern](http://autopilotpattern.io), and is a rich and powerful method of automating the management
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
1. create-concierge-image: Constructs your Dockerfile and builds your image.
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

## Submodules
Within this playbook there are some additional roles included as git submodules. These modules are synchronised with their upstream 
repositories every time you run the playbook and any changes you made locally will be stashed. Every effort is made to make these submodule
roles backward compatible but sometimes things accidents happen and sometimes its just not feasible. We've added some output messages to indicate
 that changes have happened but also advise that you watch the included each roles'repositories as well.

If you want to run the playbook without doing this, either remove the relevant entry from .gitmodules or run with `--skip-tags=update_submodules`

## Service discovery
Service discovery as a subject is beyond the scope of this documentation but if you're chosing to use this repository it's because you value it. What 
you also need to know is that we choose to use [active discovery](http://containersummit.io/articles/active-vs-passive-discovery) and chose to use 
[Consul](http://consul.io) to perform that function. We aren't opinionated about using Consul but currently this playbook is. Partly this is due to time
writing the code but also, we do genuinely believe Consul is the best product on the market for this, right now.

Some other things you need to know:
1. We've written this code in such a way as to use DNS search domains so that containers and services can more easily be recognised within your domains.
For example, if you set `dns_domain=mesoform.com`, `oaas_domain=svc.mesoform.com` and `svc_discovery=consul` then the Consul agent running in your container 
will look for your service discovery system with the following addresses `consul`, `consul.mesoform.com` and `consul.svc.mesoform.com`.
1. Therefore, if you have a system already running and in place that is reachable on the address `service-discovery.ops.myservices.internal` you can set 
`svc_discovery` to `service-dicovery` (as long as `dns_domain` or `oaas_domain` match `ops.myservices.internal`) or `service-discovery.ops.myservices.internal`
1. You don't have to have a full blown discovery system running to build your application container image. If you don't set a value for `svc_discovery`,
 then the consul agent running inside the container will simply start in development mode so that even if your job is a service, it will still run 
 as expected.
1. If you set `svc_discovery=consul`, you will also get service defined in the file docker-compose-integrations.yml. This will allow you to perform a 
proper integration test and see if your application registers as a service correctly. See [Standard Integration tests below](#standard-integration-tests)

## Event management
_WIP_
## Setting up
### Clone the repository
```
cd {{ roles_dir }}
mkdir my-app-name # Only use hyphens, not underscores because this is used as the service name in our service discovery system
cd my-app-name
git clone https://github.com/mesoform/configure-concierge-app.git .
```
### create your project repository 
In Github, Bitbucket or whatever system you like and copy the URL to your clipboard because you'll need it when you...
### Run the setup script to set up the playbook for your application
```
./setup.sh  --initialise-git
```

This will initialise and pull down the submodules, set some defaults for your project and perform an initial commit.

### Add custom files to the right directories
#### Custom application scripts
Any scripts to be used as part of your application deployment can be added to `{{ playbook_dir }}/files/bin` and will be automatically copied
to `/usr/local/bin` on the container. You can find an example scripts already in this directory.
#### Custom application configuration
Simply drop any custom application configuration into the `{{ playbook_dir }}/files/etc/{{ project_name}}` directory to have it uploaded to the application 
configuration directory (default = /etc/{{ project_name }}).
#### custom application tests 
_Not implemented but this will be where to manually add or templates will be copied to for tests. These will be copied to /tmp in the container_
#### Custom application configuration templates
Any Jinja2 templates added to `{{ playbook_dir }}/templates/app` with the `.j2` extension will automatically be processed and copied to files/etc/{{ project_name}} where they will be uploaded 
to the application configuration directory (default = /etc/{{ project_name }}). You can find an example of one already in the directory
#### Custom application orchestration templates
Any Jinja2 templates added to `{{ playbook_dir }}/templates/orchestration` with the `.j2` extension will automatically be processed and
Copied to files/etc where they will be uploaded to the application orchestration directory (default = /etc). You can find an example of one already in the directory
#### Custom application test templates
_Not implemented Any Jinja2 templates added to `{{ playbook__dir }}/templates/tests` with the `.j2` extension will automatically be processed and uploaded to the application orchestration directory (default = /etc). You can find an example of one already in the directory_


### Configure any variables you need
{{ playbook_dir }}/vars  

### Run the playbook
Run the playbook: `ansible-playbook -v app.yml`
List all of the playbook tags: `ansible-playbook --list-tags app.yml`
Skip updating the upstream submodules: `ansible-playbook -v --skip-tags=update_submodules app.yml`
View all the tasks: `ansible-playbook --list-tasks app.yml`

### Once finished
Simply run:
```docker-compose up```

### Update your documentation
This README.md will be renamed to README-Concierge.md and a blank one, ready for all your fantastic documentation can be found in {{ playbook_dir }}/README.md

## Customising
If you want to create your own templates ([Jinja2](http://jinja.pocoo.org)), there are a few template examples in the templates directory
 and any files in these subdirectories with a .j2 suffix will be processed.
### Base images
We maintain [Docker base images](https://hub.docker.com/u/mesoform/dashboard/) which provide the necessary agents for running a Concierge managed 
container. It is recommended that you use these but if you want to manage your own, take a look at the
 [Dockerfile for one of the images](https://hub.docker.com/r/mesoform/concierge-debian-base-image/~/dockerfile/) and then specify your new image by
  setting the `base_image_name: your-image-repo:your-image-version` key in your variables file. Otherwise, leave this unset and just change
   `os_distro` to pick up the latest stable version of that flavour.
### Install Scripts
   


## Testing (WIP)
Some tests are included as part of the playbook and we’ve also included a simple, plugin-like function for including your own. The details of which area covered below.
### Standard system tests (not implemented)
not implemented - as a basic set of checks, the testing role will assert that the following jobs are running:
* Consul agent (only if `svc_discovery` is defined)
* Zabbix agent (only if `event_management` is defined)
* your project's main application job
### Standard Integration tests<a name="standard-integration-tests"></a>
Basic integration tests will also be performed if you have at least one of `svc_discovery` or `event_management` are defined.
* `svc_discovery` being set will automatically spin up a Consul server in the same network as your application. You can check that the service has registerd
by connecting to the Consul UI on port 8500 (or whatever Docker mapped it to)
* `event_management` being set will automatically spin up a Zabbix server in the same network as your application. You can check that the service has registerd
by connecting to the Zabbix UI on port 80 (or whatever Docker mapped it to)
### User-defined tests (WIP)
Soon we will implement a method of dropping in test files or templates into the relevant tests directory and have it processed. Running an integration system
will simply be a case of providing the required Docker compose file/template. 