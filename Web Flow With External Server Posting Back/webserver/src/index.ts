/*
 * Copyright 2023 FinancialForce.com
 */
import express from 'express';
import { exit } from 'process';
import { OAuthClient } from './oAuth';
import { newWebFlowRoute } from './webFlowRoute';

const KEY = process.env.OAUTH_KEY;
const SECRET = process.env.OAUTH_SECRET;
const CALLBACK_URL = process.env.OAUTH_CALLBACK;
const PORT = process.env.OAUTH_DEV_SERVER_PORT;

if (!KEY || !SECRET || !CALLBACK_URL || !PORT) {
    console.error(
        'Please provide the environment variables referenced at the top of index.ts. The shell script substitutions.sh will help.'
    );
    exit(1);
}

const oAuth: OAuthClient = new OAuthClient({
    client_id: KEY!,
    client_secret: SECRET!,
    redirect_uri: CALLBACK_URL!
});

const app = express();
app.use('/callback', newWebFlowRoute(oAuth));

// Bind to localhost to prevent connections from outside the developer's environment.
// DO NOT CHANGE THIS UNTIL YOU HAVE FULLY UNDERSTOOD THE CODE AND FIXED ITS FLAWS.
// You may at least wish to hard code your app's namespace and implement more appropriate logging.
const port: number = parseInt(PORT!);
console.log(`Starting DEMONSTRATION OAuth Web Flow server on localhost:${port}`);
app.listen(port, 'localhost');