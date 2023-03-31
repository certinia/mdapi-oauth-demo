/*
 * Copyright 2023 FinancialForce.com
 */
import https from 'https';
import querystring from 'querystring';

/**
 * Perform a HTTPS Post request
 * @param options request options
 * @param postData body data to post
 * @returns promise of the body data
 */
export function httpsPost(options: https.RequestOptions, postData: string|querystring.ParsedUrlQueryInput) : Promise<string> {

    const postString : string = (typeof postData === 'object') ?
        postData = querystring.encode(postData) :
        postData;

    const headers = Object.assign({
        'Content-Type': 'application/x-www-form-urlencoded',
        'Content-Length': Buffer.byteLength(postString)
    }, options?.headers || {});

    const resolveOptions = Object.assign({
        method: 'POST' 
    }, options, {headers});

    return new Promise<string>( (resolve, reject) => {
        const request = https.request(resolveOptions, (sfRes => {
            sfRes.setEncoding('utf-8');
            let data = '';
            sfRes.on('data', (chunk : string) => {
                data += chunk;
            });
            sfRes.on('end', () => {
                resolve(data);
            });
        }));

        request.write(postString);
        request.end();
    });
}

/**
 * Attempt to decode text as JSON
 * @param txt 
 * @returns 
 */
export function jsonDecode(txt : string) : any {
    try {
        return JSON.parse(txt);
    } catch (e) {
        throw new Error('Cannot parse JSON response');
    }
}
 