/*
 * Copyright 2023 FinancialForce.com
 */

import { Router } from 'express';
import * as bodyParser from 'body-parser';
import { OAuthClient, SuccessTokenResult } from './oAuth';
import { reduceError } from './reduceError';
import { parseState } from './state';
import { ERROR_PAGE } from './flowPages';
import { sendTokenToSalesforceOrg } from './putToken';

/**
 * Create an Express router to request a refresh
 * @param oAuth The OAuth client implementation
 * @returns an Express router for the refresh endpoint
 */
export function newRefreshRoute(oAuth: OAuthClient) : Router { 
    const router = Router();
    router.use(bodyParser.json());
    router.post('/', async (req: any, res: any, next: any): Promise<void> => {
        try {
            console.dir(req.body);
            const { state, token } = req.body;
            const { type, app } = parseState(state);

            console.log(`Refresh request from app ${app ?? '<no namespace>'} of type ${type}`);
 
            const grant: SuccessTokenResult = await oAuth.requestGrantUsingRefreshToken(type, token);
            // Salesforce do not send a new refresh token, so reuse the existing one.
            await sendTokenToSalesforceOrg(grant.instance_url, app, grant.access_token, token);
            console.log('Flow complete OK');

            res.send('OK');
        } catch (e) {
            console.error(e);
            next(e);
        }
    });

    return router;
}

