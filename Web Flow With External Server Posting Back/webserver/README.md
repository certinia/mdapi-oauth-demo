# Web Flow Demo Web Server

This is the example web server required to run the Web Flow Demo.

**IMPORTANT NOTICE**
This is a proof of concept server. It is not secure. For this reason it is bound to listen only on localhost.
Do not change this until you have understood and fixed the problems. You may at least wish to hard code your application's namespace and implement more
appropriate logging for your environment.

## Building

Instructions here assume a POSIX system such as MacOS or Linux.

This is an NPM Webpack project. These instructions assume that you have changed to the `webserver` directory.

Once NPM modules are installed with `npm i` build using webpack:

```
mpx webpack
```

## Setup

The OAuth Access Token flow can be used with the web server on localhost. If you wish to use the Web Server based Refresh Token flow then you need a server that is reachable from the public Internet. There are two approaches tested:

### Restricted to localhost

Running on localhost allows the OAuth access flow to be used, but prevents the Refresh Token flow. Set the `OAUTH_PUBLIC_SERVER_HOST` in `substitutions.sh` to `http://localhost`.

### Using ngrok

NGrok provides a HTTPS forwarding service, allowing a developer to reverse proxy from the public Internet to the HTTP server running on their localhost. Multiple levels of account are provided ranging from free (non-commercial) to paid commercial use licenses designed for production systems.

Follow the [instructions provided by ngrok](https://dashboard.ngrok.com/get-started/setup) to start forwarding.
You will then need to enter the public host name in your `substitutions.sh` and push these changes to Salesforce.

### Hosting at home or on a server

It is possible to run the server as a HTTPS server. This has been tested using certificates from Let's Encrypt. Set the `LETSENCRYPT_DOMAIN_PATH` variable in `substitutions.sh` to the location of the certificate files. For example

```
export OAUTH_PUBLIC_SERVER_HOST=https://myhomedomain.ddns.net
export LETSENCRYPT_DOMAIN_PATH='letsencrypt/live/myhomedomain.ddns.net'
```

This will cause the server to start as a HTTPS server on the specified server port. You will then need to set up firewalling as needed. The server needs to be accessible both to Salesforce and your own browser. This may require special
configuration if Network Address Translation is in use on a home network.

## Running

Run using node. You will need the environment variables defined in the `substitutions` script. You may have sourced this script while deploying the SFDX project. Otherwise

```
. ../substitutions.sh
```

Then run

```
node dist/index.js
```

## Man In The Middle Attack?

The development/proof server is designed to allow testing from any namespace. It accepts the namespace as a parameter of the oAuth State. It validates that this parameter looks vaguely like a valid Apex namespace but no more. Binding to localhost, and use of localhost as the only valid callback URL, ensures that it can only be used by the developer on their own machine.

The first thing you'll need to do is lock this to your own namespace or namespaces. If you have only one then this is as easy as hard-coding. Otherwise you need to whitelist.

But what if an org does not have your product installed? The REST endpoint is of the form `/apexrest/namespace/Token`. If your package is installed then only it can receive the tokens. If your package is not installed then the malicious administrator can install an unmanaged REST endpoint at the same location. Salesforce does not require a Connected App to be installed in an Org before a user can authorize it and cause the token flow to succeed.

If this code, as is, is ever released on the public Internet then a GET request can be formed which will cause the user to go through the oAuth flow. If they authorize the app then it will attempt to post the token back to the org. This attack would require the administrator to have placed a malicious REST endpoint on their own org, and for the user to be tricked into accepting the Connected App authorization dialog. I have not tested, but wonder if it may be possible for the administrator to pre-authorize the flow for other users having accepted it once for themselves.

There may be easier ways for this malicious administrator to steal tokens. A malicious VisualForce page could easily contain Javascript to send the result of `UserInfo.getSessionId()` wherever the administrator wishes. Such an attack would be far simpler and more likely to succeed than attempting to trick the user to accept an oAuth flow. We are defending against somebody who can already install arbitrary code
to the Org. So is this really a threat to worry about?

We can mitigate it. A simple solution could be to send a
signed JWT as the State parameter. Be sure to include the Org ID or User ID or otherwise act to prevent a valid State being used on another Org. This would require a signing key to be embedded into the app. Loss of this signing key is not as frightening as loss of a JWT Bearer signing key. Similarly an encrypted version of the PUT request could protect the tokens against a malicious endpoint.
