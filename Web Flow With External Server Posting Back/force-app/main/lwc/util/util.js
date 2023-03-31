/*
 * Copyright (c) 2023 FinancialForce.com, inc. All rights reserved.
 */

import { doWebFlow } from "./webFlow";
import { MessageChannelSubscription } from "./messageChannel";

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

/**
 * Reduce an error to a string if possible, or a list of strings in the case of multiple field errors.
 */
function reduceError(error) {
  // Strings
  if (typeof error === "string") {
    return error;
  }
  // JS errors
  if (typeof error.message === "string") {
    return error.message;
  }
  // UI API DML, Apex and network errors
  if (error.body) {
    if (Array.isArray(error.body) && error.body.length > 0) {
      return error.body.map((e) => e.message);
    } else if (typeof error.body.message === "string") {
      return error.body.message;
    } else if (
      typeof error.body.fieldErrors === "object" &&
      Object.keys(error.body.fieldErrors).length > 0
    ) {
      return Object.keys(error.body.fieldErrors)
        .flatMap((fieldName) => error.body.fieldErrors[fieldName])
        .map((e) => e.message);
    } else if (
      Array.isArray(error.body.pageErrors) &&
      error.body.pageErrors.length > 0
    ) {
      return error.body.pageErrors.map((e) => e.message);
    }
  }
  if (error.statusText) {
    return error.statusText;
  }
  // Unknown error shape so serialize it
  return JSON.stringify(error);
}

/**
 * Reduces one or more LDS errors into a string[] of error messages.
 * @param {String[]|Error[]|FetchResponse[]} errors
 * @return {String[]} Error messages
 */
function reduceErrors(errors) {
  if (!Array.isArray(errors)) {
    errors = [errors];
  }

  return (
    errors
      // Remove null/undefined items
      .filter((error) => !!error)
      // Extract an error message
      .map(reduceError)
      // Flatten
      .flat()
      // Remove empty strings
      .filter((message) => !!message)
  );
}

export { reduceErrors, apexCall, MessageChannelSubscription };
