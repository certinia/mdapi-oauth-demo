/*
 * Based on LWC Recipes
 * See https://github.com/trailheadapps/lwc-recipes/blob/main/force-app/main/default/lwc/ldsUtils/ldsUtils.js
 */

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

export { reduceErrors };
