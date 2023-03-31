/*
 * Copyright 2023 FinancialForce.com
 */

/**
 * Store tokens in a Protected Custom Setting.
 * This is the recommended secure way to store secrets.
 * Unfortunately it doesn't scale. It is fine if only a small number of users will use this facility, for example 
 * for administration tasks. If we need to use a Connected App for a large population of users then we will rapidly
 * run out of storage space.
 */
public inherited sharing class ProtectedSettingTokenStore implements TokenStoreService.API {
    public TokenStoreService.Dto getToken() {
        Token__c record = Token__c.getValues(UserInfo.getUserId());
        if (record == null) {
            return TokenStoreService.newEmptyToken();
        }
        return TokenStoreService.newTokenPair(record.AccessToken__c, record.RefreshToken__c);
    }

    public void storeToken(TokenStoreService.Dto value) {
        Id userId = UserInfo.getUserId();
        Token__c existingToken = Token__c.getValues(userId);
        if (existingToken != null) {
            existingToken.AccessToken__c = value.accessToken;
            existingToken.RefreshToken__c = value.refreshToken;
            update existingToken; //NOPMD - Protected Custom Settings do not have CRUD/FLS
        } else {
            Token__c newRecord = new Token__c(SetupOwnerId = userId, Name = 'Token for User ' + UserInfo.getUserName());
            newRecord.AccessToken__c = value.accessToken;
            newRecord.RefreshToken__c = value.refreshToken;
            insert newRecord; //NOPMD - Protected Custom Settings do not have CRUD/FLS
        }
    }
}
