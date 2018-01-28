# Role to create an image for a Concierge managed application 
## Introduction
The [Concierge Paradigm](http://www.mesoform.com/blog-listing/info/the-concierge-paradigm) is an extension of 
[The Autopilot Pattern](http://autopilotpattern.io), and is a rich and powerful method of automating the management of running 
containers by simply using a service discovery system like Consul, and an event management system, like Zabbix. By using these, 
already well developed systems, you gain incredible control and information about the state of the system as a whole and fine-grained
detail of all applications.

A concierge managed application is one that fits naturally into this concierge environment and automatically registers itself for 
discovery, monitoring and scheduling.  This playbook asks only a few simple questions about your application and the environment in
which you expect to run it in, then spits out a Docker image at the end and performs the required system and integration tests to 
be Concierge managed and any custom tests you require for your application.


## About this role

Primarily the role generates a Dockerfile, a set of Docker Compose files and a 
[Containerpilot](https://github.com/joyent/containerpilot) file. Then builds an image and runs a set of tests against the build. It
wraps up some other common roles for creating our Docker images ready to be used in a Concierge Paradigm environment.  The role has
been split into 4 parts:
1. configure-concierge-repo: This repository. The purpose of which is to get you your own custom repository setup to start building 
your application container
1. create-concierge-app: This submodule role takes the variables, scripts and any files needed for your application and constructs 
the necessary application configuration files (if using templates) and orchestration files for managing the lifecycle of your 
application.
1. create-concierge-image: Constructs your Dockerfile and builds your image.
1. create-concierge-tests: Performs basic system tests, integration to service discovery and event management. Plus any user-defined 
application tests


The Dockerfile has some default attributes automatically set and allows for others to be included by creating the required lists or 
variables.

Currently these are as follows:
* os_distro (string) = The flavour of operating system. Current options are `alpine` and `debian` - versions *3.4* and *jessie*, 
respectively
* install_scripts (list) = the location of the script or scripts to install the application you want to package into the image. A 
list is used so as to logically separate different install steps into separate RUN commands and better make use of UnionFS image 
layers
* build_args (list) = a list of additional Docker ARG options for required variables when building
* container_vars (list) = a list of environment variables which will be set as defaults inside the running container. E.g. 
container_vars: FOO=bar
* env_vars (list) = a list of additional environment variables which will be passed to the container at runtime. E.g. env_vars: 
FOO=bar
* labels (list) = a list of additional labels to add to the container 
* ports (list) = a list of ports to expose
* service_port (integer) = the port of your application which will be registered with with the service discovery system so that
downstream services know which port to use when communicating with your application.  
* volumes (list) = a list of volume the container should create
* entrypoint (string) = process or script to run as ENTRYPOINT. For the concierge containers, it is assumed that unless you're 
creating a base image, this will always be containerpilot and already set in the base image.
* command (string) = the command used to start your application. This will be executed as part of a Containerpilot job.
* app_config_dir (string) = the directory where you application's configuration files will reside. Currently this must be in /etc.
Default = `/etc/{{ project_name }}`
* custom_orchestration_dir = the location where you want your custom application orchestration config template to output to. This is 
not container orchestration (e.g. docker-compose.yml) but how you want to orchestrate your application (e.g. containerpilot.json). The
default is /etc inside your container. 

See vars/main.yml and defaults/main.yml for others variables and their descriptions and any non-declared container orchestration 
options like mem_limit (defaults to 128MB)are best updated in the compose files at the end.


## Submodules
Within this playbook there are some additional roles included as git submodules. These modules are synchronised with their upstream 
repositories every time you run the playbook and any changes you made locally will be stashed. Every effort is made to make these 
submodule roles backward compatible but sometimes things accidents happen and sometimes its just not feasible. We've added some 
output messages to indicate that changes have happened but also advise that you watch the included each roles'repositories as well.

If you want to run the playbook without doing this, either remove the relevant entry from .gitmodules or run with
 `--skip-tags=update_submodules`

## Service discovery<a name="service-discovery"></a>
Service discovery as a subject is beyond the scope of this documentation but if you're chosing to use this repository it's because 
you value it. What you also need to know is that we choose to use
[active discovery](http://containersummit.io/articles/active-vs-passive-discovery) and chose to use [Consul](http://consul.io) to 
perform that function. We aren't opinionated about using Consul but currently this playbook is. Partly this is due to time writing
the code but also, we do genuinely believe Consul is the best product on the market for this, right now.

Some other things you need to know:
1. We've written this code in such a way as to use DNS search domains so that containers and services can more easily be recognised
within your domains. For example, if you set `dns_domain=mesoform.com`, `oaas_domain=svc.mesoform.com` and `svc_discovery=consul` 
then the Consul agent running in your container will look for your service discovery system with the following addresses `consul`,
`consul.mesoform.com` and `consul.svc.mesoform.com`.
1. Therefore, if you have a system already running and in place that is reachable on the address
`service-discovery.ops.myservices.internal` you can set `svc_discovery` to `service-dicovery` (as long as `dns_domain` or
`oaas_domain` match `ops.myservices.internal`) or `service-discovery.ops.myservices.internal`
1. You don't have to have a full blown discovery system running to build your application container image. If you don't set a value 
for `svc_discovery`, then the consul agent running inside the container will simply start in development mode so that even if your
job is a service, it will still run as expected.
1. If you set `svc_discovery=consul`, you will also get service defined in the file `docker-compose-integrations.yml`. This will allow 
you to perform a proper integration test and see if your application registers as a service correctly. See 
[Standard Integration tests below](#standard-integration-tests)

## Event management
Likewise, event management and monitoring (EMM) is a large subject an beyond the scope of this documentation. The Concierge Paradigm makes
use of already well-defined systems in this area to improve the scheduling of our systems. For example, if our EMM system has metrics
from our platform, application, database and infrastructure all together we have a much more powerful tool for auto-scaling our apps.
This means we can use metrics from applications and databases, we can use predictive scaling and we have a powerful tool for debugging.

Again, we're not opinionated about which system you use, but currently code uses [Zabbix](https://www.zabbix.com). We like Zabbix because
it is an enterprise-grade, flexible and open-source monitoring solution with a really powerful event management system which we can use
for scheduling our containers.

All the points above in the [Service discovery](service-discovery) section are relevant for hooking into EMM automatically. For example,
if `event_management` is defined, the monitoring agent will be started and registration and container heartbeats will be sent to the
address specified in the value. The same goes with the DNS points, so if `event_management` is set to `event_management=zabbix` and
`oaas_domain=svc.mesoform.com dns_domain=mesoform.com`, your container will look for the EMM at `zabbix`, `zabbix.svc.mesoform.com` and
`zabbix.mesoform.com`.

_(WIP) You will also get a service definition for our pre-configured EMM in `docker-compose-integrations.yml`_ 
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
Any scripts to be used as part of your application deployment can be added to `{{ playbook_dir }}/files/bin` and will be automatically
copied to `/usr/local/bin` on the container. You can find an example scripts already in this directory.
#### Custom application configuration
Any Jinja2 templates added to `{{ playbook_dir }}/templates/app` with the `.j2` extension will automatically be processed and copied
to files/etc/{{ project_name }} where they will be uploaded to the application configuration directory (default =
/etc/{{ project_name }}). You can find an example of one already in the directory. Even if your files need no processing, simply drop
the basic files in this directory with a `.j2` extension and they will be copied to you application configuration directory.

You can add any static scripts and configuration to any other directory in the container by simply adding the full path, relative to
the root directory where you want the file to end up at, beneath the `files/` directory. For example, If you want something copied to 
`/usr/libexec/bin` inside the container, you will need to create `files/usr/libexec/bin/some_file`.
#### custom application tests 
_Not implemented but this will be where to manually add or templates will be copied to for tests. These will be copied to /tmp in the
container_
#### Custom application orchestration
Any Jinja2 templates added to `{{ playbook_dir }}/templates/orchestration` with the `.j2` extension will automatically be processed 
and copied to `files/etc/` where they will be uploaded to the application orchestration directory (default = /etc). You can find an 
example of one already in the directory. If you want the file to be copied to a different location, set `custom_orchestration_dir` to
a path value relative to `files/etc/` (e.g. `custom_orchestration_dir=files/etc/my_orchestration`).
#### Custom application test templates
_Not implemented Any Jinja2 templates added to `{{ playbook__dir }}/templates/tests` with the `.j2` extension will automatically be
processed and uploaded to the application orchestration directory (default = /etc). You can find an example of one already in the
directory_


### Configure any variables you need
{{ playbook_dir }}/vars  

### Run the playbook
* Run the playbook: `ansible-playbook -v app.yml`
* List all of the playbook tags: `ansible-playbook --list-tags app.yml`
* Skip updating the upstream submodules: `ansible-playbook -v --skip-tags=update_submodules app.yml`
* View all the tasks: `ansible-playbook --list-tasks app.yml`

### Once finished
Simply run `docker-compose up` for just your application or 
`docker-compose -f docker-compose-integrations.yml -f docker-compose.yml up` for a full integration to other services.


### Update your documentation
This README.md will be renamed to README-Concierge.md and a blank one, ready for all your fantastic documentation can be found in
{{ playbook_dir }}/README.md

## Customising
If you want to create your own templates ([Jinja2](http://jinja.pocoo.org)), there are a few template examples in the templates 
directory and any files in these subdirectories with a .j2 suffix will be processed.
### Base images
We maintain [Docker base images](https://hub.docker.com/u/mesoform/dashboard/) which provide the necessary agents for running a 
Concierge managed container. It is recommended that you use these but if you want to manage your own, take a look at the
[Dockerfile for one of the images](https://hub.docker.com/r/mesoform/concierge-debian-base-image/~/dockerfile/) and then specify 
your new image by setting the `base_image_name: your-image-repo:your-image-version` key in your variables file. Otherwise, leave this
unset and just change `os_distro` to pick up the latest stable version of that flavour.
### Install Scripts
To keep the installation of your application simple and consistent we've set up this playbook so that you can simply create a script,
name it `install.sh` and drop it into `files/bin`. This will run as /usr/local/bin/install.sh inside your a build container when creating
your image. If you want something different to run or run multiple scripts (to better make use of
 [UnionFS](https://en.wikipedia.org/wiki/UnionFS#Uses)), you can do so by modifying the `install_scripts` list. For example:
```
install_scripts:
  - /usr/local/bin/install_hadoop.sh
  - /usr/local/bin/install_other_stuff.sh
```

These scripts will then run in the order of the list by creating separate
[RUN instruction](https://docs.docker.com/engine/reference/builder/#run) in your Dockerfile. I.e. in the example, `install_hadoop.sh`
will run before `install_other_stuff.sh` and in separate image layers.

### Networking
We're not trying to create code that will automate your whole production environment, so we've kept the networking configuration
simple. Leaving `network_mode` unset will select the default network mode for the container runtime platform you're deploying to. At
the time of writing this means that for default Docker Engine implementation, a user-defined bridge network will be created. If you 
want any of the [other options](https://docs.docker.com/compose/compose-file/compose-file-v2/#network_mode), simply set the variable
to the type of network you want to test (e.g. `network_mode=host`).

Technically we've found [Joyent's Triton Container Runtime Platform](https://www.joyent.com) excellent, particularly for private
clouds, and they require containers to run in bridge network mode. Therefor, if left unset we add a commented `network_mode=bridge` 
in the outputted compose files. Later, the playbook will work out which platform you're deploying to and uncomment this if necessary
but for now if you plan to deploy to Triton, simply uncomment.

## Testing (WIP)
Some tests are included as part of the playbook and we’ve also included a simple, plugin-like function for including your own. The 
details of which area covered below.
### Standard system tests (not implemented)
not implemented - as a basic set of checks, the testing role will assert that the following jobs are running:
* Consul agent (only if `svc_discovery` is defined)
* Zabbix agent (only if `event_management` is defined)
* your project's main application job
### Standard Integration tests<a name="standard-integration-tests"></a>
Basic integration tests will also be performed if you have at least one of `svc_discovery` or `event_management` are defined.
* `svc_discovery` being set will automatically spin up a Consul server in the same network as your application. You can check that 
the service has registered by connecting to the Consul UI on port 8500 (or whatever Docker mapped it to)
* _(WIP) `event_management` being set will automatically spin up a Zabbix server in the same network as your application. You can check that
the service has registered by connecting to the Zabbix UI on port 80 (or whatever Docker mapped it to)_
### User-defined tests (WIP)
Soon we will implement a method of dropping in test files or templates into the relevant tests directory and have it processed. 
Running an integration system will simply be a case of providing the required Docker compose file/template.

[Template by Mesoform Limited](http://www.mesoform.com)