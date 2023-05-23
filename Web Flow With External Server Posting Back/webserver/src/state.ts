import { ClientType, VALID_CLIENT_TYPES } from './oAuth';
import { reduceError } from './reduceError';

export type StateArg = {
    type: ClientType,
    app: string | undefined
};

/**
 * Parse and validate the State parameter.
 * @param stateArg 
 * @returns 
 */
export function parseState(stateArg: string) : StateArg {
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