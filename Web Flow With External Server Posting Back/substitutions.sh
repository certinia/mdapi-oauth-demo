# Source this file using . ./substitutions.sh before deploying

# These values from from "Managed Consumer Details" on the Connected App page under Settings->App Manager
export OAUTH_KEY='-- Insert Your OAuth Consumer Key Into The Substitutions.sh File --'
export OAUTH_SECRET='-- Insert Your OAuth Consumer Secret Into The Substitutions.sh File --'

# Defined OAUTH_DEV_SERVER_PORT if using the local development server.
# The callback will be a http address on localhost using the given port.
# The production app will need to specify the real callback here. The port is not used.
export OAUTH_DEV_SERVER_PORT=3000
export OAUTH_CALLBACK=http://localhost:${OAUTH_DEV_SERVER_PORT}/callback
