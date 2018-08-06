# Sample service provider for UAA
This demo app authenticates its users against UAA as a identity provider.
It's roughly based on https://github.com/cloudfoundry/omniauth-uaa-oauth2/blob/master/examples/config.ru and uses this library.

Although it needs this library that's tailored for UAA interaction, any OAuth2 library should do.

It is primarily designed to run on CloudFoundry, since it expects the OAuth2 configuration to be passed in `VCAP_SERVICES`.

## Scope
When the `Sign in` link is clicked by an unauthorized user,
it redirects the user to UAA as IDP (standard OAuth2 `Authorization code` flow).

When the user logs in on UAA provider, he is redirected back to the sample app.
The app completes the OAuth2 flow and receives the user's info (using the Userinfo endpoint), i.e. its attributes like firstname, lastname.

*Disclaimer: Not for production use*
Although it is meant to be pushed on CF, be aware that this app can only run one instance (since it's using the File based session store, because the Cookie store limit of 4k is easily exceeded with UAA's large tokens when syncing a large number of groups).
So, do not use this demo app for production. If you have to do so, you can base on this code, but please use a prod-ready the session store (i.e. with Redis or DBMS backend) to be able to run it with multiple instances.

## Configure, deploy and test
```
cf push sample-uaa --random-route --no-start -i 1

# Now create the user provided service which will be provided to the app in `VCAP_SERVICES`.
# The client specified here must be created manually beforehand on the OAuth2 provider.
CREDENTIALS='{"authorizationEndpoint": "<uaa-url>/oauth/authorize", "tokenEndpoint": "<uaa-url>/oauth/token", "userInfoEndpoint": "<uaa-url>/userinfo", "logoutEndpoint": "<uaa-url>/logout.do", "clientId": "<client-id>", "clientSecret": "<client-secret>"}'
cf create-user-provided-service OAUTH2-CLIENT -p $CREDENTIALS

# Bind & start the app to make the service instance available
cf bind-service sample-uaa OAUTH2-CLIENT
cf start sample-app

Now access the app in your browser.
```


## Other applications
For a Spring boot demo app, check out https://github.com/swisscom/oauth2-simple.
