/*
 * Copyright 2023 FinancialForce.com
 */

/**
 * Store token data in an SObject as an encrypted value.
 * This allows large scale should the 10M limit for Custom Settings be an issue.
 * 
 * I have included this in the code sample because I want to gather feedback about the technique,
 * especially from a Security Review point of view. Can we do this ff we need a large amount of token storage?
 */
public with sharing class SObjectTokenStore implements TokenStoreService.API {
    private static final Integer KEY_SIZE = 256;
    private static final String CRYPTO_ALG = 'AES256';
    private static final String MAC_ALG = 'hmacSHA256';
    private static final Integer PADDING_TARGET_LENGTH = 1536;

    public TokenStoreService.Dto getToken() {
        String userId = UserInfo.getUserId();
 
        LargeTokenStore__c[] records = [SELECT Data__c FROM LargeTokenStore__c WHERE Key__c = :userId];
        if(records.size() == 0 || String.isBlank(records[0].Data__c)){
            return TokenStoreService.newEmptyToken();
        }

        Blob secretKey = getSecretKey();
        if(secretKey == null) {
            System.debug(LoggingLevel.ERROR, 'This org has token data but no secret key to decode it with');
            return TokenStoreService.newEmptyToken();
        }

        try {
            Blob data = Crypto.decryptWithManagedIV(CRYPTO_ALG, secretKey, EncodingUtil.base64Decode(records[0].Data__c));
            String text = data.toString();
            // Strip padding. It's Base64 so can't contain '['
            text = text.substring(text.indexOf('['));
            String[] parts = (List<String>) JSON.deserializeStrict(text, List<String>.class);
            String accessToken = parts[0];
            String refreshToken = parts[1];
            String signature = parts[2];
            String computedSignature = generateSignatureForCurrentUserAndOrg(accessToken, refreshToken, secretKey);
            if(computedSignature != signature) {
                System.debug(LoggingLevel.ERROR, 'Signature does not match for stored token record');
                return TokenStoreService.newEmptyToken();
            }
            return TokenStoreService.newTokenPair(accessToken, refreshToken);
        } catch (Exception e) {
            System.debug(LoggingLevel.ERROR, 'Error decoding key data: ' + e.getMessage());
            return TokenStoreService.newEmptyToken();
        }
    }

    public void storeToken(TokenStoreService.Dto value) {
        if(value == null || value.isEmpty()) {
            deleteToken();
        } else {
            writeToken(value);
        }
    }

    /**
     * Delete this user's token record from the database.
     */
    private void deleteToken() {
        String userId = UserInfo.getUserId();
        LargeTokenStore__c[] records = [SELECT Id FROM LargeTokenStore__c WHERE Key__c = :userId];
        if(records.size() > 0) delete records;
    }

    /**
     * Store the token in the database associated with this user.
     */
    private void writeToken(TokenStoreService.Dto value) {
        String userId = UserInfo.getUserId();
        Blob secretKey = getOrCreateSecretKey();

        String signature = generateSignatureForCurrentUserAndOrg(value.accessToken, value.refreshToken, secretKey);
        // The use of padding prevents the observer guessing how many tokens and which type are stored in each record.
        // Otherwise, given the constant length of each token, there will be 4 different record lengths for None,A,R,AR.
        // It also moves the known plaintext '["' from the start, though leaves known plaintext at the end ']'.
        // I'd hope the the encryption algorithm with random initialisation vector is immune to known plaintext attacks.
        String payload = JSON.serialize(new List<String>{value.accessToken, value.refreshToken, signature});
        String padding = generateRandomBase64Text(PADDING_TARGET_LENGTH - payload.length());
        String encryptedPayload = EncodingUtil.base64Encode(Crypto.encryptWithManagedIV(CRYPTO_ALG, secretKey, Blob.valueOf(padding + payload)));

        LargeTokenStore__c record = new LargeTokenStore__c(
            Name = userId,
            Key__c = userId,
            Data__c = encryptedPayload
        );
        upsert record LargeTokenStore__c.Key__c;
    }
 
    /**
     * Generate random text that includes only valid Base64 characters.
     * The generated text may not be valid Base64 due to the length not being a correct multiple.
     */
    private String generateRandomBase64Text(Integer length) {
        if(length <= 0) {
            return '';
        }

        String padding = '';
        while(padding.length() < length) {
            padding += EncodingUtil.base64Encode(Crypto.generateAesKey(256));
        }
        if(padding.length() > length) {
            padding = padding.left(length);
        }
        return padding;
    }

    /**
     * Generate a HMAC signature based on the provided information and the User/Org IDs.
     * This is to prevent a valid record being assigned to a different user or different org.
     */
    private String generateSignatureForCurrentUserAndOrg(String accessToken, String refreshToken, Blob privateKey) {
        String userId = UserInfo.getUserId();
        String orgId = UserInfo.getOrganizationId(); 
        String challengeText = orgId + userId + accessToken + '/' + refreshToken;
        String computedSignature = EncodingUtil.base64Encode(Crypto.generateMac(MAC_ALG, Blob.valueOf(challengeText), privateKey));
        return computedSignature;
    }

    /**
     * Load the secret key. Return null if none is available.
     */
    private Blob getSecretKey() {
        // Co-opt the Token protected custom setting for this.
		SObjectTokenStoreSettings__c settings = SObjectTokenStoreSettings__c.getOrgDefaults();
        return  String.isNotBlank(settings.LargeTokenStoreKey__c) ? EncodingUtil.base64Decode(settings.LargeTokenStoreKey__c) : null; 
    }

    /**
     * Load the secret key, creating and saving a new one if needed (first run)
     */
    private Blob getOrCreateSecretKey() {
        // It is not possible to call out after this call, so this call must only be used by the PUT request.
        // The get token method has to be careful to only require the secret key if it knows that a secret is stored and therefore
        // that PUT has been run.
        // The key is lazy instantiated on first use. There is a potential race condition in the unlikely condition of heavy instantaneous
        // first use.
		SObjectTokenStoreSettings__c settings = SObjectTokenStoreSettings__c.getOrgDefaults();
		if (String.isBlank(settings.LargeTokenStoreKey__c)) {
			Blob key = Crypto.generateAesKey(KEY_SIZE);
			String secret = EncodingUtil.base64Encode(key);
			settings.LargeTokenStoreKey__c = secret;
			upsert settings;
		}
        return EncodingUtil.base64Decode(settings.LargeTokenStoreKey__c);
	}
}