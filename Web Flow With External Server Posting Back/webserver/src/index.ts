/*
 * Copyright 2023 FinancialForce.com
 */
import express from 'express';
import { exit } from 'process';
import { OAuthClient } from './oAuth';
import { newWebFlowRoute } from './webFlowRoute';
import { newStartRoute } from './startRoute';
import { newRefreshRoute } from './refreshRoute';
import fs from 'fs';
import https from 'https';
import path from 'path';
import { RedisSurrogateTokenTransform, TokenTransform, UnityTokenTransform } from './tokenTransform';
import { connectToRedis } from './redisClient';

const KEY = process.env.OAUTH_KEY;
const SECRET = process.env.OAUTH_SECRET;
const CALLBACK_URL = process.env.OAUTH_CALLBACK;
const PORT = process.env.OAUTH_DEV_SERVER_PORT;
const LETSENCRYPT_DOMAIN_PATH = process.env.LETSENCRYPT_DOMAIN_PATH;
const REDIS = process.env.REDIS_URL;

if (!KEY || !SECRET || !CALLBACK_URL || !PORT) {
    console.error(
        'Please provide the environment variables referenced at the top of index.ts. The shell script substitutions.sh will help.'
    );
    exit(1);
}

(async function() {
    const refreshTokenTransform : TokenTransform = REDIS ?
        new RedisSurrogateTokenTransform(await connectToRedis(REDIS)) :
        new UnityTokenTransform();

    const oAuth: OAuthClient = new OAuthClient({
        client_id: KEY!,
        client_secret: SECRET!,
        redirect_uri: CALLBACK_URL!,
        refreshTokenTransform
    });

    const app = express();
    app.use('/start', newStartRoute(oAuth));
    app.use('/callback', newWebFlowRoute(oAuth));
    app.use('/refresh', newRefreshRoute(oAuth));

    const port: number = parseInt(PORT!);

    if(LETSENCRYPT_DOMAIN_PATH) {
        const credentials = {
            key: fs.readFileSync(path.join(LETSENCRYPT_DOMAIN_PATH, 'privkey.pem'), 'utf-8'),
            cert: fs.readFileSync(path.join(LETSENCRYPT_DOMAIN_PATH, 'cert.pem'), 'utf-8'),
            ca: fs.readFileSync(path.join(LETSENCRYPT_DOMAIN_PATH, 'chain.pem'), 'utf-8')
        };
        const server = https.createServer(credentials, app);
        server.listen(port, () => {
            console.log(`DEMONSTRATION OAuth Web Flow HTTPS server listening on ${port}`);
        });
    } else {
        console.log(`Starting DEMONSTRATION OAuth Web Flow server on ${port}`);
        app.listen(port);
    }
})();