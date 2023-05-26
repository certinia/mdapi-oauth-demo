import { RedisClient } from './redisClient';
import crypto from 'crypto';

// Size of the surrogate token in bytes. It will be base64 encoded, so the final length will be 4/3 this size.
const SURROGATE_TOKEN_BYTES = 42;
// Token lifespan in seconds. It can be short in demo code. It will want to be a lot longer in a live system.
const SURROGATE_TOKEN_LIFESPAN = 5 * 60;
// Start pruning keys for a given user after this amount of keys.
const MAX_KEYS_PER_USER = 4;

export type TokenToClientTransformRequest = {
    /** The token to transform. */
    token: string;
    /** This is the ID returned by Salesforce. It looks like https://test.salesforce.com/id/00DDS000000uj0Y2AQ/005DS00000ugbMiYAI */
    userId: string;
}

export interface TokenTransform {
    sfToClient(args: TokenToClientTransformRequest) : Promise<string>;
    clientToSf(clientForm: string) : Promise<string>;
}

/**
 * A transform that does not change its input. The client will receive the unaltered token.
 */
export class UnityTokenTransform implements TokenTransform {
    public sfToClient({token} : TokenToClientTransformRequest): Promise<string> {
        return Promise.resolve(token);
    }

    public clientToSf(clientForm: string): Promise<string> {
        return Promise.resolve(clientForm);
    }
}

/**
 * A transform that generates surrogate tokens. These are mapped to the real tokens using a Redis
 * database.
 */
export class RedisSurrogateTokenTransform implements TokenTransform {
    public constructor(private redis: RedisClient) {}

    public async sfToClient({token, userId} : TokenToClientTransformRequest): Promise<string> {
        const uid = crypto.randomBytes(SURROGATE_TOKEN_BYTES).toString('base64'); // Base64 works on blocks of 3 bytes.
        const storeKey = newTokenKey(uid);
        await this.storeToken(storeKey, token);
        await this.maintainUserTokenStoreLimit(userId, uid);
        return uid;
    }

    private storeToken(storeKey: string, token: string) : Promise<void> {
        return this.redis.set(storeKey, token, {
            EX: SURROGATE_TOKEN_LIFESPAN,
            NX: true
        }).then(setResult => {
            if(setResult !== 'OK') {
                throw new Error('Unable to store the token in Redis');
            }    
        });
    }

    // This prevents a single user creating a lot of records.
    // A potential risk here is that we now have a mapping between users and their tokens.
    // So anyone with access to the database can easily find tokens to try for any target user
    // or org. Without this an attacker would have to try all keys in the database to find one
    // for their target user. Not a problem if we assume that the database is secure? If the
    // database is lost then is having to brute force search all keys much an impediment anyway?
    private async maintainUserTokenStoreLimit(userId: string, uid: string) : Promise<void> {
        const listKey = `KeyList.${userId}`;
        const [length] = await this.redis.multi()
            .rPush(listKey, uid)
            .expire(listKey, SURROGATE_TOKEN_LIFESPAN)
            .exec() as [number, number];

        if(length > MAX_KEYS_PER_USER) {
            // There should be only one. There are potential race conditions here, so I'll only take 
            // the one to match the one I've just inserted. Then if another thread is also adding
            // we'll take one item each.
            const firstKey = await this.redis.lPop(listKey);
            if(firstKey){
                // Fire and forget. If the key has expired then this will do nothing.
                this.redis.del(newTokenKey(firstKey));
            }
        }
    }

    public async clientToSf(clientForm: string): Promise<string> {
        const getResult = await this.redis.get(`SurrogateToken.${clientForm}`);
        if(getResult) {
            return getResult;
        }
        throw new Error('Unable to find token');
    }
}

function newTokenKey(uid: string) {
    return `SurrogateToken.${uid}`;
}