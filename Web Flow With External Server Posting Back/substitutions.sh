# Source this file using . ./substitutions.sh before deploying

# These values from from "Managed Consumer Details" on the Connected App page under Settings->App Manager
export OAUTH_KEY='-- Insert Your OAuth Consumer Key Into The Substitutions.sh File --'
export OAUTH_SECRET='-- Insert Your OAuth Consumer Secret Into The Substitutions.sh File --'

# Defined OAUTH_DEV_SERVER_PORT if using the local development server.
# The callback will be a http address on localhost using the given port.
# The production app will need to specify the real callback here. The port is not used.
# NOTES: The code is changing to demonstrate offloading refresh tokens to the web server.
#        This needs a server that is reachable from Salesforce for Refresh Tokens to work.

# Port to listen on for the Express server.
# Use NGROK or your own forwarding solution to direct to this port.
export OAUTH_DEV_SERVER_PORT=3000

# This is the port as seen by Salesforce on the Public Internet.
# If using localhost only then this is the same as the Server Port.
# This will be 443 if using ngrok. 
# It will depend on your firewall settings if using a local server with port forwarding.
export OAUTH_PUBLIC_SERVER_PORT=3000

# Address as available on the public internet.
# If set to http://localhost then it will not be possible to use Refresh Token flow.
# This is the host reported by ngrok or your own domain if using LestEncrypt
export OAUTH_PUBLIC_SERVER_HOST='http://localhost'

# If you wish to start a HTTPS server using a letsencrypt or similar certificate then provide the path
# to the directory containing the following files
#   privkey.pem
#   cert.pem
#   chain.pem
# I use an EdgeRouter and had to enable both port forwarding and Hairpin NAT to make this work.
# Care is needed with any firewall configuration.
#export LETSENCRYPT_DOMAIN_PATH='path to the directory containing letsencrypt PEM files'

# Server root configured in Apex for its callouts.
export OAUTH_SERVER_ROOT=${OAUTH_PUBLIC_SERVER_HOST}:${OAUTH_PUBLIC_SERVER_PORT}

# Callback configured in the Connected App and used in token requests to Salesforce.
export OAUTH_CALLBACK=${OAUTH_SERVER_ROOT}/callback
