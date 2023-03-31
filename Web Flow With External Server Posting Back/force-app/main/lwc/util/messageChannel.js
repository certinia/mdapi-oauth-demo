import {
  subscribe,
  unsubscribe,
  APPLICATION_SCOPE
} from "lightning/messageService";

import {wire} from 'lwc';

/**
 * Wrap the Message Channel subscription code.
 */
export class MessageChannelSubscription {
  subscription;
  channel;
  handler;

  constructor(channel, handler) {
    this.channel = channel;
    this.handler = handler;
  }

  connect(messageContext) {
    if (!this.subscription) {
        this.subscription = subscribe(
            messageContext,
            this.channel,
            this.handler,
            { scope: APPLICATION_SCOPE }
        );
    }
  }

  disconnect() {
    if (this.subscription) {
        unsubscribe(this.subscription);
        this.subscription = null;
    }
  }
}
