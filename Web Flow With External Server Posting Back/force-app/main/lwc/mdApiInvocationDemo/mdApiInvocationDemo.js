/*
 * Copyright (c) 2023 FinancialForce.com, inc. All rights reserved.
 */

import { LightningElement, track, wire } from 'lwc';
import {  MessageContext } from "lightning/messageService";

import runDemo from '@salesforce/apex/MdApiInvocationDemoController.runDemo';
import getCacheStatus from '@salesforce/apex/MdApiInvocationDemoController.getCacheStatus';
import clearAccessToken from '@salesforce/apex/MdApiInvocationDemoController.clearAccessToken';
import clearRefreshToken from '@salesforce/apex/MdApiInvocationDemoController.clearRefreshToken';
import tokenCacheEvent from '@salesforce/messageChannel/TokenCacheEvent__c';
import { reduceErrors, apexCall, MessageChannelSubscription } from 'c/util';

export default class MdApiInvocationDemo extends LightningElement {
    @wire(MessageContext) messageContext;

    /** The only cache event at the moment invalidates the cache, so reload status. */
    subscription = new MessageChannelSubscription(tokenCacheEvent, () => this.loadCacheStatus());

    @track
    state = {
        tasks: 0,
        logs: [],
        cache: {}
    };

    get isProcessing() {
        return this.state.tasks > 0;
    }

    get cachePillItems() {
        const pills = [],
            testAndMakePill = (name, label) => {
                if (this.state.cache[name]) {
                    pills.push({
                        name,
                        label,
                        variant: 'circle'
                    });
                }
            };

        testAndMakePill('hasAccessToken', 'Access Token');
        testAndMakePill('hasRefreshToken', 'Refresh Token');
        return pills;
    }

    connectedCallback() {
        this.loadCacheStatus();
        this.subscription.connect(this.messageContext);
    }

    disconnectedCallback() {
        this.subscription.disconnect();
    }

    loadCacheStatus() {
        this.runTask(() => {
          apexCall(getCacheStatus).then((rslt) => this.onCacheStatus(rslt));
        });
    }

    onCacheStatus(status) {
        this.state.cache = status;
    }

    /**
     * Run the sample Metadata API request and report back into the log.
     */
    handleRunDemo() {
        this.runTask(async () => {
            let result = await apexCall(runDemo);

            this.pushLog(JSON.stringify(result));
            if (result?.metadata?.apiName) {
                this.pushLog({ message: 'Looks like valid metadata', level: 'success' });
            }
            await this.loadCacheStatus();
        });
    }

    handleCachePillItemRemove(event) {
        switch (event.detail.item.name) {
            case 'hasAccessToken':
                this.runTask(() => {
                    apexCall(clearAccessToken).then(rslt => this.onCacheStatus(rslt));
                });
                break;
            case 'hasRefreshToken':
                this.runTask(() => {
                    apexCall(clearRefreshToken).then(rslt => this.onCacheStatus(rslt));
                });
                break;
        }
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
