/*
 * Copyright 2023 FinancialForce.com
 */

import { Router } from 'express';
import { OAuthClient, SuccessTokenResult, VALID_CLIENT_TYPES } from './oAuth';
import { sendTokenToSalesforceOrg } from './putToken';
import { reduceError } from './reduceError';
import { parseState } from './state';
import { ERROR_PAGE, SUCCESS_PAGE } from './flowPages';

/**
 * Create an Express router for a Web Flow callback
 * @param oAuth The OAuth client implementation
 * @returns an Express router for the Web Flow callback
 */
export function newWebFlowRoute(oAuth: OAuthClient) : Router { 
    const router = Router();

    router.get('/', async (req: any, res: any): Promise<void> => {
        try {
            const { code, state, error, error_description } = req.query;
            const { type, app } = parseState(state);

            console.log(`WebFlow request from app ${app ?? '<no namespace>'} of type ${type}`);

            if (error || error_description) {
                throw error_description || error;
            }

            const grant: SuccessTokenResult = await oAuth.requestGrantUsingTemporaryCode(type, code);
            await sendTokenToSalesforceOrg(grant.instance_url, app, grant.access_token, grant.refresh_token);
            console.log('Flow complete OK');
            res.type('html');
            res.send(SUCCESS_PAGE);
        } catch (e) {
            console.error(e);
            res.type('html');
            res.send(ERROR_PAGE(reduceError(e)));
        }
    });

    return router;
}
