# Code for Denver LiquidFeedback

Provision a fully funtional LiquidFeedback environment using Vagrant

LiquidFeedback's installation process is complicated and not completely documented. To expedite setup, this repo uses a [Vagrant](https://www.vagrantup.com/) virtual machine as the development environment.

As of the initial commit, the actual LiquidFeedback files are not under version control. While this repo will allow you to instantly get a working version up and running, for future development efforts, a better solution needs to be found.

## Setup via Vagrant

To get vanilla LiquidFeedback up and running:

1. Install or Update [VirtualBox](https://www.virtualbox.org).
2. Install or Update [Vagrant](https://www.vagrantup.com).
3. Clone this repository to your machine.
4. Navigate to the repo directory.
5. Run `vagrant up`.
6. Enter your password when prompted.

Running `vagrant up` downloads a Debian Stretch image to your host machine and provisions it with everything this project needs to run. This will take a few minutes, so be patient.

#### System Provisioning

The provisioning script uses apt-get and pip to install the following:

* build-essential
* lua5.2
* liblua5.2-dev
* postgresql-9.6
* libpq-dev
* postgresql-server-dev-all
* pmake
* imagemagick
* exim4
* sendmail-bin
* libbsd-dev
* python-pip
* markdown2

#### LiquidFeedback Configuration

The provisioning script will also download, install, and configure everything you need to run a vanilla installation of LiquidFeedback:

* LiquidFeedback Core 3.2.2
* LiquidFeedback Frontend 3.2.1
* Moonbridge 1.0.1 (lightweight Lua server)
* WebMCP 2.1.0 (Lua framework)

### Running the App

Once `vagrant up` has finished, follow these steps to start the server.

1. `vagrant ssh` to login into the virtual machine.
2. `sudo su www-data -s $SHELL` to act as the www-data user
3. `/opt/moonbridge/moonbridge --background /opt/webmcp/bin/mcp.lua /opt/webmcp/ /opt/liquid_feedback_frontend/ main myconfig` to start the server in the background.
4. Open your browser
5. Navigate to http://localhost:4567/
6. Login as the `admin` user - by default there is no password, you might want to add one

### Troubleshooting

* It may be necessary to configure the server's mail system
* `lf_update` is a custom script that has been placed at `/opt/liquid_feedback_core/lf_updated` and that may need to run on a regular basis; it may be necessary to run this manually or if the site does not seem to be functioning correctly