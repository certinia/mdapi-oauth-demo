/*
 * Copyright 2023 FinancialForce.com
 */
import { ParsedUrlQueryInput } from 'querystring';
import { jsonDecode, httpsPost } from './httpsPost';

/**
 * Possible outcomes from a token request
 */
export type OAuthTokenResult = SuccessTokenResult | FailTokenResult;

export type SuccessTokenResult = {
    access_token: string;
    scope: string;
    instance_url: string;
    id: string;
    token_type: string;
    issued_at: string;
    refresh_token?: string;
};

export type FailTokenResult = {
    error: string;
    error_description: string;
};

export type OAuthClientConfig = {
    client_id: string;
    client_secret: string;
    redirect_uri: string;
};

export type ClientType = 'prod' | 'test';

export const VALID_CLIENT_TYPES : ClientType[] = ['prod','test'];

export class OAuthClient {
    constructor(private readonly config: OAuthClientConfig) {}

    /**
     * Apply for a grant using an authorisation code.
     * @param type the type of the client Org
     * @param code the authorisation code passed by the OAuth flow
     * @returns the grant result.
     */
    requestGrantUsingTemporaryCode(type: ClientType, code: string): Promise<SuccessTokenResult> {
        return this.getGrant(type, {
            grant_type: 'authorization_code',
            code,
        });
    }

    /**
     * Apply for a grant using a refresh token
     * @param type the type of the client Org
     * @param refresh_token the user's refresh token
     * @returns the grant result
     */
    requestGrantUsingRefreshToken(type: ClientType, refresh_token: string): Promise<SuccessTokenResult> {
        return this.getGrant(type, {
            grant_type: 'refresh_token',
            refresh_token,
        });
    }

    private getGrant(type: ClientType, parameters: ParsedUrlQueryInput) : Promise<SuccessTokenResult> {
        const body: ParsedUrlQueryInput = Object.assign({}, parameters, this.config);

        return httpsPost(
            {
                host: type == 'test' ? 'test.salesforce.com' : 'login.salesforce.com',
                path: '/services/oauth2/token',
            },
            body
        )
            .then(jsonDecode)
            .then((grant: OAuthTokenResult) => {
                if ('access_token' in grant) {
                    console.log(`Received grant for ${grant.id}`);
                    return grant;
                } else {
                    throw new Error(grant.error_description);
                }
            });
    }
}
