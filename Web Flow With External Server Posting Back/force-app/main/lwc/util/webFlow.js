/**
 * Initiate an OAuth Web Flow.
 * The parameter keys match the OAuth Init structure defined in AuthDemoApplication.cls
 *
 * The web flow remote end is expected to use HTML5 messaging to post back its success/failure result.
 * This does not include the token, which is passed back out of band to prevent client side interception.
 *
 * @param {string} initUrl URL to redirect to in order to launch web flow.
 * @param {string} callbackUrl the OAuth callback used, in order to verify postMessages.
 * @returns a Promise of successful web flow.
 */
export function doWebFlow({ initUrl, callbackUrl }) {
    return new Promise((resolve, reject) => {
        const expectedOrigin = new URL(callbackUrl).origin;
        function resultListener(e) {
            if (e.origin === expectedOrigin) {
                window.removeEventListener('message', resultListener);
                if (e.data === 'OK') {
                    resolve();
                } else {
                    reject(e.data.error_message || 'Error performing oAuth Login');
                }
            }
        }
        window.addEventListener('message', resultListener);
        window.open(initUrl, 'FFDCLoginFlow');
    });
}
