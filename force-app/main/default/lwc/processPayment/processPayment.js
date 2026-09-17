import { LightningElement, api } from 'lwc';
import processPayment
    from '@salesforce/apex/OpportunityAutoCloseAction.processPayment';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { CloseActionScreenEvent }
    from 'lightning/actions';

export default class ProcessPayment extends LightningElement {
    @api recordId;

    processing = false;

    handleCancel() {
        this.dispatchEvent(new CloseActionScreenEvent());
    }

    async handleProcess() {
        this.processing = true;

        try {
            await processPayment({
                paymentId: this.recordId
            });

            this.dispatchEvent(
                new ShowToastEvent({
                    title: 'Payment Processed',
                    message:
                        'Payment processing completed successfully.',
                    variant: 'success'
                })
            );

            this.dispatchEvent(new CloseActionScreenEvent());
        } catch (error) {
            const message =
                error?.body?.message ||
                error?.message ||
                'An unexpected error occurred.';

            this.dispatchEvent(
                new ShowToastEvent({
                    title: 'Payment Processing Failed',
                    message: message,
                    variant: 'error',
                    mode: 'sticky'
                })
            );
        } finally {
            this.processing = false;
        }
    }
}