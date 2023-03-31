/*
 * Copyright (c) 2023 FinancialForce.com, inc. All rights reserved.
 */

import { LightningElement, track, wire } from 'lwc';
import { publish, MessageContext } from 'lightning/messageService';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import getCurrentSettings from '@salesforce/apex/MdApiClientSettingsController.getCurrentSettings';
import saveSettings from '@salesforce/apex/MdApiClientSettingsController.saveSettings';
import tokenCacheEvent from "@salesforce/messageChannel/TokenCacheEvent__c";
import { reduceErrors, apexCall } from 'c/util';

import * as Labels from './labels';

export default class App extends LightningElement {
    @wire(MessageContext) messageContext;
    
    @track
    state = {
        tasks: 0,
        config: {}
    };

    labels = Labels;

    get isProcessing() {
        return this.state.tasks > 0;
    }

    get title() {
        return this.state.settingsTitle || 'Metadata API Configuration';
    }

    connectedCallback() {
        this.runTask(() => {
            return apexCall(getCurrentSettings).then((rslt) => {
                this.state.config = rslt;
            });
        });
    }

    handleFieldChange(evt) {
        const field = evt.target.getAttribute('data-field');
        console.assert(field, 'Field change event missing data-field attribute');

        if (field) {
            this.state.config[field] = evt.target.checked;
        }
    }

    handleSave() {
        this.runTask(() => {
            return apexCall(() =>
                saveSettings({
                    config: this.state.config
                })
            ).then(() => {
                publish(this.messageContext, tokenCacheEvent, {event: 'INVALIDATED'});
                const evt = new ShowToastEvent({
                    title: this.title,
                    message: Labels.settingsSaveOk,
                    variant: 'success'
                });
                this.dispatchEvent(evt);
            });
        });
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
            console.log('runTask()#catch');
            this.reportError(e);
        } finally {
            this.state.tasks--;
        }
    }

    reportError(e) {
        console.error(e);
        const evt = new ShowToastEvent({
            title: 'Metadata API Configuration',
            message: reduceErrors(e).join(' '),
            variant: 'error',
            mode: 'sticky'
        });
        this.dispatchEvent(evt);
    }
}
