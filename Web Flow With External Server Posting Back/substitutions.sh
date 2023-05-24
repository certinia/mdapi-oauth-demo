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

# Address as available on the public internet.
export OAUTH_PUBLIC_SERVER_HOST='This is the host reported by ngrok'

# Server root configured in Apex for its callouts.
export OAUTH_SERVER_ROOT=${OAUTH_PUBLIC_SERVER_HOST}/

# Callback configured in the Connected App and used in token requests to Salesforce.
export OAUTH_CALLBACK=${OAUTH_PUBLIC_SERVER_HOST}/callback
