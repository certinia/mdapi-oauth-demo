/*
 * Copyright 2023 FinancialForce.com
 */

import { Router } from 'express';
import { OAuthClient } from './oAuth';
import { reduceError } from './reduceError';
import { parseState } from './state';
import { ERROR_PAGE } from './flowPages';

/**
 * Create an Express router to start the web flow.
 * @param oAuth The OAuth client implementation
 * @returns an Express router for the start page
 */
export function newStartRoute(oAuth: OAuthClient) : Router { 
    const router = Router();

    router.get('/', async (req: any, res: any): Promise<void> => {
        try {
            const { state, scope } = req.query;
            const initUrl = oAuth.getInitUrl(scope, state);
            res.redirect(initUrl);
        } catch (e) {
            console.error(e);
            res.type('html');
            res.send(ERROR_PAGE(reduceError(e)));
        }
    });

    return router;
}

