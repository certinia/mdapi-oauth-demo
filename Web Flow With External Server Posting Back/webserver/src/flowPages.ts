/**
 * Page served to indicate to the calling page that the result was successful
 */
export const SUCCESS_PAGE = `<html>
<head><title>oAuth Web Flow Success Page</title></head>
<body>
<h1>Connected App Connection OK</h1>
<p>This window should close automatically. You can now return to the app</p>
<script>
    window.opener.postMessage('OK','*');
    window.close();
</script>
</body>
</html>
`;

/**
 * Create a page which passes an error back to the calling page.
 * @param error error text
 */
// TODO: Only close the window on receipt of an ACK from the host
export const ERROR_PAGE = (error: string): string =>
    `<html>
<head><title>oAuth Web Flow Error Page</title></head>
<body>
<h1>Connected App Connection Failed</h1>
<p>This window should close automatically. You can now return to the app</p>
<div class="error" id="errorText"></div>
<script>
    (function(){
        const error_message = decodeURIComponent("${encodeURIComponent(error)}");
        document.getElementById('errorText').appendChild(
            document.createTextNode(error_message)
        );
        if(window.opener) {
            window.opener.postMessage({error_message},'*');
            window.close();
        }
    }());
</script>
</body>
</html>
`;
