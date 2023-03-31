/*
 * Copyright (c) 2023 FinancialForce.com, inc. All rights reserved.
 */

import { LightningElement, track } from 'lwc';
import runDemo from '@salesforce/apex/MdApiInvocationDemoController.runDemo';
import { reduceErrors } from 'c/util';

export default class MdApiInvocationDemo extends LightningElement {
    @track
    state = {
        tasks: 0,
        logs: [],
        status: {}
    };

    get isProcessing() {
        return this.state.tasks > 0;
    }

    /**
     * Run the sample Metadata API request and report back into the log.
     */
    handleRunDemo() {
        this.runTask(async () => {
            let result = await runDemo();

            this.pushLog(JSON.stringify(result));
            if (result?.metadata?.apiName) {
                this.pushLog({ message: 'Looks like valid metadata', level: 'success' });
            }
        });
    }

    /**
     * Clear the log panel
     */
    handleClearLog() {
        this.state.logs = [];
    }

    /**
     * Run a task, maintaining the isProcessing flag and catching any errors.
     * The task returns a Promise.
     *
     * @param {Function} task which returns a Promise
     */
    async runTask(task) {
        try {
            this.state.tasks++;
            await task();
        } catch (e) {
            this.reportError(e);
        } finally {
            this.state.tasks--;
        }
    }

    /**
     * Report an error or errors
     * @param {string|Error|any} error
     */
    reportError(e) {
        reduceErrors(e)
            .map((message) => ({ message, level: 'error' }))
            .forEach((log) => this.pushLog(log));
    }

    /**
     * Append to the log. The log entry is mutated to add a key for LWC.
     * @param {object} log
     * @param {string} log.message the log message
     */
    pushLog(log) {
        if (typeof log === 'string') {
            log = { message: log, level: 'debug' };
        }
        log.key = `log-${this.state.logs.length}`;
        log.class = 'ff-logItem';
        if (log.level) log.class += ` ff-logItem_${log.level}`;
        console.dir(log);
        this.state.logs.push(log);
    }
}
