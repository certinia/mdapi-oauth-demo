/*
 * Copyright (c) 2023 FinancialForce.com, inc. All rights reserved.
 */

import { LightningElement, track } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import getCurrentSettings from '@salesforce/apex/MdApiClientSettingsController.getCurrentSettings';
import testConnection from '@salesforce/apex/MdApiClientSettingsController.testConnection';
import saveSettings from '@salesforce/apex/MdApiClientSettingsController.saveSettings';
import { reduceErrors } from 'c/util';

import * as Labels from './labels';

export default class App extends LightningElement {
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
            return getCurrentSettings().then((rslt) => {
                this.state.title = rslt.settingsTitle;
                this.state.config = rslt;
            });
        });
    }

    handleFieldChange(evt) {
        const field = evt.target.getAttribute('data-field');
        console.assert(field, 'Field change event missing data-field attribute');

        const record = this.state.config;

        if (record && field) {
            record[field] = evt.target.value;
        }
    }

    handleSave() {
        this.runTask(() => {
            return saveSettings({ config: this.state.config }).then(() => {
                const evt = new ShowToastEvent({
                    title: this.title,
                    message: Labels.settingsSaveOk,
                    variant: 'success'
                });
                this.dispatchEvent(evt);
            });
        });
    }

    handleTestConnection(evt) {
        const record = this.state.config;
        this.runTask(() => {
            return testConnection({
                consumerKey: record.consumerKey,
                certificateName: record.certificate,
                scopes: record.requiredScopes
            }).then((rslt) => {
                if (rslt.message || rslt.errorCode) {
                    this.showTestError(record, rslt);
                } else {
                    // We passed the scopes to the server so it is validating them. We don't need the returned scopes.
                    this.showTestSuccess(record);
                }
            });
        });
    }

    showTestError(record, result) {
        const evt = new ShowToastEvent({
            title: this.getTestConnectionToastTitle(record),
            message: result.errorCode ? `${result.errorCode}: ${result.errorMessage}` : `${result.errorMessage}`,
            variant: 'error',
            mode: 'sticky'
        });
        this.dispatchEvent(evt);
    }

    showTestSuccess(record) {
        const evt = new ShowToastEvent({
            title: Labels.settingsTest,
            message: Labels.settingsTestOk,
            variant: 'success'
        });
        this.dispatchEvent(evt);
    }

    /**
     * Run a task, maintaining the isProecssing flag and catching any errors.
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
            title: this.state.settingsTitle || 'Metadata API Configuration',
            message: reduceErrors(e).join(' '),
            variant: 'error',
            mode: 'sticky'
        });
        this.dispatchEvent(evt);
    }
}
