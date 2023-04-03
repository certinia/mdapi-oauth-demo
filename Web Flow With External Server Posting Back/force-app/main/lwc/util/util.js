/*
 * Copyright (c) 2023 FinancialForce.com, inc. All rights reserved.
 */

import { doWebFlow } from "./webFlow";
import { MessageChannelSubscription } from "./messageChannel";
import { reduceErrors } from "./reduceErrors";

const JSON_MESSAGE_PATTERN = /^\{.*\"message\":.*\}$/;

const MDAPI_CLIENT_PLEASE_RETRY = "ffdc_please_retry";

/**
 * Wrap a call to Apex in a function that can decode the encoded errors from AuthDemoApplication.callCommandForLwc().
 * Perform a Web OAuth Flow and retry if the server has requested.
 * @param {*} fn Apex function to call.
 * @returns
 */
async function apexCall(fn) {
  try {
    return await fn();
  } catch (error) {
    // Pull apart an encoded AuraHandledException if there is one.
    // This could be used in future to implement alternative oAuth patterns for MDAPI calls.
    if (
      error.body &&
      typeof error.body.message === "string" &&
      JSON_MESSAGE_PATTERN.test(error.body.message)
    ) {
      const payload = JSON.parse(error.body.message);
      if (payload.errorCode === MDAPI_CLIENT_PLEASE_RETRY) {
        if ("oAuthWebFlow" in payload) {
          await doWebFlow(payload.oAuthWebFlow);
          // Allow only one retry.
          return await fn();
        }
        // We don't yet have other reasons for retry.
        // We could allow arbitrary retries by recursing into apexCall(), but I'd want some means of preventing
        // runaway.
        return await fn();
      }
      throw payload;
    }
    throw error;
  }
}

export { reduceErrors, apexCall, MessageChannelSubscription };
