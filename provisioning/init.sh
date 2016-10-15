#!/bin/bash

echo
echo "===== Provisioning LiquidFeedback Environment ====="
echo
echo " =====Updating APT sources. ====="
echo
apt-get update > /dev/null
echo
echo "===== Installing packages required for LiquidFeedback ====="
echo
apt-get -y install build-essential
apt-get -y install lua5.2
apt-get -y install liblua5.2-dev
apt-get -y install postgresql-9.6
apt-get -y install libpq-dev
apt-get -y install postgresql-server-dev-all
apt-get -y install pmake
apt-get -y install imagemagick
apt-get -y install exim4
apt-get -y install sendmail-bin
apt-get -y install libbsd-dev
apt-get -y install python-pip
pip install markdown2

echo
echo "===== Base packages installed ====="
echo

echo "===== Creating www-data user ====="

su postgres << EOF
createuser --no-superuser --createdb --no-createrole www-data
EOF

echo "===== LiquidFeedback Core ====="
echo
if [ ! -f /vagrant/provisioning/liquid_feedback_core-v3.2.2.tar.gz ]; then
    wget http://www.public-software-group.org/pub/projects/liquid_feedback/backend/v3.2.2/liquid_feedback_core-v3.2.2.tar.gz
fi
tar xvzf liquid_feedback_core-v3.2.2.tar.gz

echo "===== Making Core ====="
echo
cd liquid_feedback_core-v3.2.2
make
mkdir /opt/liquid_feedback_core
echo "===== Moving LiquidFeedback Core ====="
echo
cp core.sql lf_update lf_update_issue_order lf_update_suggestion_order /opt/liquid_feedback_core
cd ..
rm -r liquid_feedback_core-v3.2.2

echo "===== Creating liquid_feedback database ====="
echo
su www-data -s $SHELL << EOF
cd /opt/liquid_feedback_core
createdb liquid_feedback
psql -v ON_ERROR_STOP=1 -f core.sql liquid_feedback

# Populate initial database
psql liquid_feedback
INSERT INTO system_setting (member_ttl) VALUES ('1 year');
INSERT INTO contingent (polling, time_frame, text_entry_limit, initiative_limit) VALUES (false, '1 hour', 20, 6);
INSERT INTO contingent (polling, time_frame, text_entry_limit, initiative_limit) VALUES (false, '1 day', 80, 12);
INSERT INTO contingent (polling, time_frame, text_entry_limit, initiative_limit) VALUES (true, '1 hour', 200, 60);
INSERT INTO contingent (polling, time_frame, text_entry_limit, initiative_limit) VALUES (true, '1 day', 800, 120);
INSERT INTO policy (index, name, min_admission_time, max_admission_time, discussion_time, verification_time, voting_time, issue_quorum_num, issue_quorum_den, initiative_quorum_num, initiative_quorum_den) VALUES (1, 'Default policy', '4 days', '8 days', '15 days', '8 days', '15 days', 10, 100, 10, 100);
INSERT INTO unit (name) VALUES ('Our organization');
INSERT INTO area (unit_id, name) VALUES (1, 'Default area');
INSERT INTO allowed_policy (area_id, policy_id, default_policy) VALUES (1, 1, TRUE);
# Insert an admin with no password
INSERT INTO member (login, name, admin, password) VALUES ('admin', 'Administrator', TRUE, '$1$/EMPTY/$NEWt7XJg2efKwPm4vectc1');
\q
EOF

echo
echo "===== Downloading Moonbridge ====="
echo
if [ ! -f /vagrant/provisioning/moonbridge-v1.0.1.tar.gz ]; then
	wget http://www.public-software-group.org/pub/projects/moonbridge/v1.0.1/moonbridge-v1.0.1.tar.gz
fi
tar xvzf moonbridge-v1.0.1.tar.gz


echo "===== Making Moonbridge ====="
echo 
cd moonbridge-v1.0.1
pmake MOONBR_LUA_PATH=/opt/moonbridge/?.lua
mkdir /opt/moonbridge
cp moonbridge /opt/moonbridge/
cp moonbridge_http.lua /opt/moonbridge/
cd ..
rm -r moonbridge-v1.0.1

echo "===== Downloading WebMCP ====="
echo
if [ ! -f /vagrant/provisioning/webmcp-v2.1.0.tar.gz ]; then
	wget http://www.public-software-group.org/pub/projects/webmcp/v2.1.0/webmcp-v2.1.0.tar.gz
fi
tar xvzf webmcp-v2.1.0.tar.gz

echo "===== Making WebMCP ====="
echo
cd webmcp-v2.1.0
rm Makefile.options
cp ../replacements/Makefile.options.webmcp Makefile.options
make
mkdir /opt/webmcp
cp -RL framework/* /opt/webmcp/

cd ..
rm -r webmcp-v2.1.0

echo "===== Downloading LiquidFeedback Frontend ====="
echo
if [ ! -f /vagrant/provisioning/liquid_feedback_frontend-v3.2.1.tar.gz ]; then
	wget http://www.public-software-group.org/pub/projects/liquid_feedback/frontend/v3.2.1/liquid_feedback_frontend-v3.2.1.tar.gz
fi
tar xvzf liquid_feedback_frontend-v3.2.1.tar.gz

mv liquid_feedback_frontend-v3.2.1 /opt/liquid_feedback_frontend

chown www-data /opt/liquid_feedback_frontend/tmp

echo "===== Setting up LiquidFeedback updater script ====="
echo
if [ ! -f /opt/liquid_feedback_core/lf_updated ]; then
	cp replacements/lf_updated /opt/liquid_feedback_core/
	chmod +x /opt/liquid_feedback_core/lf_updated
fi

echo "===== Setting LiquidFeedback config file ====="
echo
cd /opt/liquid_feedback_frontend/config
cp example.lua myconfig.lua

echo
echo "===== LiquidFeedback environment ready ====="
echo
echo "===== LiquidFeedback user 'admin' created with NO PASSWORD - you may wish to add one ====="
echo
echo "======================"
echo "Start server and connect using http://localhost:4567/"
echo "To start the server use vagrant ssh followed by:"
echo 'sudo su www-data -s $SHELL'
echo "/opt/moonbridge/moonbridge --background /opt/webmcp/bin/mcp.lua /opt/webmcp/ /opt/liquid_feedback_frontend/ main myconfig"
echo "======================"