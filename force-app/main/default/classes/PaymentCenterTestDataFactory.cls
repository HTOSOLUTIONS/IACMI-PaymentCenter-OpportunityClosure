
@IsTest
public class PaymentCenterTestDataFactory {

    public static final Decimal DEFAULT_AMOUNT = 11500;

    public static Account createAccount() {
        Account account = new Account(
            Name = 'Payment Center Test Account'
        );

        insert account;
        return account;
    }


    public static fw1__Invoice__c createInvoice(
        Account account,
        Decimal invoiceAmount
    ) {
        fw1__Invoice__c invoice = new fw1__Invoice__c(
            fw1__Account__c = account.Id,
            fw1__Invoice_Date__c = Date.today(),
            fw1__Due_Date__c = Date.today().addDays(45)
        );

        insert invoice;
        return invoice;
    }


    public static fw1__Invoice_Line__c createInvoiceLine(
        fw1__Invoice__c invoice,
        Decimal amount
    ) {
        fw1__Invoice_Line__c invoiceLine = new fw1__Invoice_Line__c(
            fw1__Invoice__c = invoice.Id,
            fw1__Item_Description__c = 'IACMI Membership',
            fw1__Quantity__c = 1,
            fw1__Unit_Price__c = amount,
            fw1__Price_Book__c = Test.getStandardPricebookId()
        );

        insert invoiceLine;
        return invoiceLine;
    }


    public static Opportunity createOpportunity(
        Account account,
        fw1__Invoice__c invoice
    ) {
        Opportunity opportunity = new Opportunity(
            Name = 'Payment Center Test Opportunity',
            AccountId = account.Id,
            StageName = 'Awaiting Agreement',
            CloseDate = Date.today().addDays(30),
            AgreementInvoice__c = invoice.Id
        );

        insert opportunity;
        return opportunity;
    }


    public static fw1__Payment__c createPayment(
        Account account,
        fw1__Invoice__c invoice,
        Decimal amount,
        Datetime paymentDate
    ) {
        fw1__Payment__c payment = new fw1__Payment__c(
            fw1__Account__c = account.Id,
            fw1__Invoice__c = invoice.Id,
            fw1__Amount__c = amount,
            fw1__Payment_Date__c = paymentDate,
            fw1__Payment_Method__c = 'Check',
            fw1__Check_Number__c = 'TEST'
        );

        insert payment;
        return payment;
    }


    public static fw1__Payment_Activity__c createPaymentActivity(
        fw1__Payment__c payment,
        fw1__Invoice__c invoice,
        Decimal amount,
        Datetime transactionDate
    ) {
        fw1__Payment_Activity__c activity =
            new fw1__Payment_Activity__c(
                fw1__Payment__c = payment.Id,
                fw1__Invoice__c = invoice.Id,
                fw1__Amount__c = amount,
                fw1__Applied_To_Invoice__c = true,
                fw1__Remaining_Amount__c = 0,
                fw1__Transaction_Date__c = transactionDate
            );

        insert activity;
        return activity;
    }


    public static void markInvoicePaid(
        fw1__Invoice__c invoice,
        Decimal amount
    ) {
        invoice.fw1__Status_Sys__c = 'Paid';
        invoice.fw1__Total_Paid_Amount__c = amount;

        update invoice;
    }
}

