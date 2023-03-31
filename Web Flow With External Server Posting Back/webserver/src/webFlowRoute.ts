/*
 * Copyright 2023 FinancialForce.com
 */

import { Router } from 'express';
import { ClientType, OAuthClient, SuccessTokenResult, VALID_CLIENT_TYPES } from './oAuth';
import { sendTokenToSalesforceOrg } from './putToken';
import { reduceError } from './reduceError';

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

type StateArg = {
    type: ClientType,
    app: string | undefined
};

/**
 * Parse and validate the State parameter.
 * @param stateArg 
 * @returns 
 */
function parseState(stateArg: string) : StateArg {
    try {
        return JSON.parse(stateArg, (key:string, value:any) => {
            switch (key) {
                case '': // The root object
                    if(!('type' in value)) {
                        throw new Error('State value missing type parameter');
                    }
                    return value;
                case 'type':
                    // The type must be 'test' or 'prod'.
                    if(VALID_CLIENT_TYPES.includes(value)) {
                        return value;
                    }
                    throw new Error('Bad type value');
                case 'app':
                    // The App parameter allows to caller to specify their namespace.
                    // This is great in development, but a production system MUST validate this.
                    // Ideally this will be hardcoded in your application because you only have
                    // one namespace.
                    if(/^[a-zA-Z0-9_]*$/.test(value)) {
                        return value;
                    }
                    throw new Error('Bad app value');
            }
            return undefined;
        });
    } catch (e) {
        throw new Error(`Invalid Argument state: ${reduceError(e)}`);
    }
}

const SUCCESS_PAGE = `<html>
<head><title>oAuth Web Flow Success Page</title></head>
<body>
<h1>Connected App Connection OK</h1>
<p>This window should close automatically. You can now return to the app</p>
<script>
    window.opener.postMessage('OK','*');
    window.close();
</script>
</body>
</html>
`;

// TODO: Only close the window on receipt of an ACK from the host
const ERROR_PAGE = (error: string): string =>
    `<html>
<head><title>oAuth Web Flow Error Page</title></head>
<body>
<h1>Connected App Connection Failed</h1>
<p>This window should close automatically. You can now return to the app</p>
<div class="error" id="errorText"></div>
<script>
    (function(){
        const error_message = decodeURIComponent("${encodeURIComponent(error)}");
        document.getElementById('errorText').appendChild(
            document.createTextNode(error_message)
        );
        if(window.opener) {
            window.opener.postMessage({error_message},'*');
            window.close();
        }
    }());
</script>
</body>
</html>
`;
