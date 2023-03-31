/*
 * Copyright 2023 FinancialForce.com
 */
import { httpsPost, jsonDecode } from './httpsPost';

type ErrorResponse = {
    errorCode: string;
    message: string;
};

type PutTokenResponse = {
    ok: boolean;
};

type Response = ErrorResponse | PutTokenResponse;

/**
 * Put a token back to the Org for Apex to use.
 * Client of the TokenRestResource.cls
 *
 * @param instanceUrl the Org instance URL returned in the grant from Salesforce
 * @param app the app namespace to push to
 * @param token the access token to push
 * @param refreshToken the refresh token to push if refresh tokens are in use
 * @returns promise of completion
 */
export function sendTokenToSalesforceOrg(
    instanceUrl: string,
    app: string | undefined,
    token: string,
    refreshToken?: string
): Promise<void> {
    const host = instanceUrl.replace(/^https:\/\//, '');
    const path = `/services/apexrest/${app ? `${app}/` : ''}token`;
    const payload = JSON.stringify({ token, refreshToken });
    console.log(`Putting token to https://${host}${path}`);
    return httpsPost(
        {
            host,
            path,
            method: 'PUT',
            headers: {
                'Content-Type': 'application/json',
                Authorization: `Bearer ${token}`,
            },
        },
        payload
    )
        .then(jsonDecode)
        .then((response: Response) => {
            if (Array.isArray(response)) response = response[0];
            if ('errorCode' in response) {
                throw new Error(response.message);
            }

            if (response.ok) {
                console.log(`PUT Token service for ${app ?? '<no namespace>'} returned OK`);
            } else {
                console.warn(`PUT Token service for ${app ?? '<no namespace>'} returned unexpected`);
                console.dir(arguments[0]);
            }
        });
}
