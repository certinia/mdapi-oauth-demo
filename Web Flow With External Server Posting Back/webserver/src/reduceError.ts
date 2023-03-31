/*
 * Copyright 2023 FinancialForce.com
 */

/**
 * Convert an error from Salesforce or Javascript into a string for display
 * @param e the raw error
 * @returns string representation
 */
export function reduceError(e: any) : string {
    if (e === null || e === undefined) {
        return '(null)';
    } 
    
    if (typeof e === 'string') {
        return e;
    }

    if (typeof e === 'object') {
        if ('message' in e) return e.message;
        if ('error_description' in e) return e.error_description;
        if ('error' in e) return e.error;
    }

    return JSON.stringify(e);
}