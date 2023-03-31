/*
 * Copyright 2023 FinancialForce.com
 */

 /**
  * Provide a REST resource to allow the web server to write tokens to the org.
  * Store the provided token against the authenticated user.
  */
@RestResource(urlMapping='/token')
global with sharing class TokenRestResource {
    @HttpPut
    global static TokenResponse putToken(String token, String refreshToken) {
        try {
            TokenStoreService.storeToken(TokenStoreService.newTokenPair(token, refreshToken));
            return new TokenResponse(true);
        } catch (Exception e) {
            System.debug(LoggingLevel.ERROR, e.getMessage());
            // Do not allow exception details to leak.
            throw AuthDemoApplicationException.builder(AuthDemoApplicationException.ERROR_INTERNAL_EXCEPTION, 'Internal Exception').build();
        }
    }

    global with sharing class TokenResponse {
        global boolean ok;

        global TokenResponse(Boolean ok) {
            this.ok = ok;
        }
    }
}
