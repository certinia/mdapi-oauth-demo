import {RedisClientType, createClient} from 'redis';

export type RedisClient = ReturnType<typeof createClient>;

/**
 * Connect to Redis using the given URL
 * @param clientUrl 
 * @returns the connected client.
 */
export async function connectToRedis(clientUrl : string) : Promise<RedisClient> {
    const client = createClient({
        url: clientUrl
    });

    await(client.connect());

    console.log('Connected to REDIS');

    return client;
}