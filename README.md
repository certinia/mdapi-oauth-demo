# Apex Metadata API OAuth Sample Code

This repository contains sample code demonstrating two mechanisms to perform Metadata API calls from Apex.

This code is provided as a sample only. We do not recommend you use this code in any production system, it is provided for demonstration purposes only.

## Context

Applications have traditionally used the Apex method UserInfo.getSessionId() when calling into Salesforce's Metadata API for metadata operations to authenticate. A change to the Salesforce security review process has required that a ConnectedApp is used in some circumstances, see [salesforce.stackexchange.com](https://salesforce.stackexchange.com/questions/389121/call-salesforce-api-from-apex-and-not-fail-security-review) and [Partner Forum](https://partners.salesforce.com/0D54V00006EGIJz) for further details.

## JWT Bearer Flow with Admin Provided Connected App

This solution is designed to be the easiest to retrofit to an existing codebase while avoiding the need to store sensitive keys on a packaging org. This is the quick fix. Its disadvantage is that it needs the administrator to perform post-deployment setup to create a Connected App. See [its README](JWT%20Bearer%20Flow%20with%20Admin%20Provided%20Connected%20App/README.md) for more details.

### JWT Bearer Flow with Packaged Connected App

Salesforce provide [sample code](https://partners.salesforce.com/0694V00000NCWhr) for a JWT Bearer Implementation with packaged signing keys. This solution works well and is easy to retrofit, but requires shipping a signing key with the package. It was rejected because of its dependency on a central master key.
It is very hard to
rotate the key of a packaged connected app when the key is also present in installed protected metadata in customer Orgs. Compromise of the key, no matter
how unlikely given good internal security practice, would have unthinkable consequences. An attacker in possession of the key would be able to impersonate
any user of the app in any customer org from anywhere on the Internet.

## Web Flow With External Server Posting Back

This solution is the more user friendly of the two. It is the harder for an ISV to retrofit quickly. This codebase demonstrates two concepts which are worth review. One is the small web server which posts keys back
to the org. The other is the Large SObject Based Token Store. The Large Token Store is proposed solution should this technique be required for a large user base which would overload the Protected Custom Setting based token store. It does stray from Salesforce's security best practices, but tries to be secure using encryption and signing with a local secret key.

The solution is described in its [README file](Web%20Flow%20With%20External%20Server%20Posting%20Back/README.md)