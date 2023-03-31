/*
 * Copyright 2023 FinancialForce.com
 */

 /**
  * Provide interaction with the cached token store for the demo UI.
  * All calls return the state of the store after the call completes.
  * Verbs:
  *
  * * read: read the status of the store
  * * clearAccessToken: remove the access token and return the new status
  * * clearRefreshToken: remove the refresh token and return the new status
  *
  * status is
  * * hasAccessToken:  an access token is present (though not known to be valid)
  * * hasRefreshToken: a refresh token is present (though not known to be valid) 
  */
public inherited sharing class CachedTokenCommand implements Callable
{
    public Object call(String verb, Object arg) {
        TokenStoreService.Dto token = TokenStoreService.getToken();
        if(verb == 'read'){
            return new Map<String, Boolean>{
                'hasAccessToken' => String.isNotBlank(token.accessToken),
                'hasRefreshToken' => String.isNotBlank(token.refreshToken)
            };
        }
        if(verb == 'clearAccessToken'){
            TokenStoreService.storeToken(TokenStoreService.newRefreshToken(token.refreshToken));
            return new Map<String, Boolean>{
                'hasAccessToken' => false,
                'hasRefreshToken' => String.isNotBlank(token.refreshToken)
            };
        } else if(verb == 'clearRefreshToken'){
            TokenStoreService.storeToken(TokenStoreService.newAccessToken(token.accessToken));
            return new Map<String, Boolean>{
                'hasAccessToken' => String.isNotBlank(token.accessToken),
                'hasRefreshToken' => false
            };
        }
        return null;
    }
}