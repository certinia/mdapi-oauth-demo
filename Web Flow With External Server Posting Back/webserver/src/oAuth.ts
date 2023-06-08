/*
 * Copyright 2023 FinancialForce.com
 */
import { ParsedUrlQueryInput } from 'querystring';
import { jsonDecode, httpsPost } from './httpsPost';
import { StateArg, parseState } from './state';

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
     * 
     * @param scopes scopes parameter to pass to Salesforce
     * @param state incoming state parameter for the request.
     * @returns the Init URL to start web flow
     */
    getInitUrl(scopes: string, state: string) : string {
        const { type } = parseState(state);

        const target = new URL(type === 'prod' ? 
        'https://login.salesforce.com/services/oauth2/authorize' :
        'https://test.salesforce.com/services/oauth2/authorize');
        target.searchParams.set('state', state);
        target.searchParams.set('client_id', this.config.client_id);
        target.searchParams.set('redirect_uri', this.config.redirect_uri);
        target.searchParams.set('response_type', 'code');
        target.searchParams.set('scope', scopes);
        return target.toString();
    }

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
