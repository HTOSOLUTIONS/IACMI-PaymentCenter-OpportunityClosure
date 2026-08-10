
@IsTest(SeeAllData=true)
private class PaymentCenterTestDataFactoryTest {

    @IsTest
    static void canCreatePaymentCenterTestData() {

        Account account =
            PaymentCenterTestDataFactory.createAccount();

        fw1__Invoice__c invoice =
            PaymentCenterTestDataFactory.createInvoice(
                account,
                PaymentCenterTestDataFactory.DEFAULT_AMOUNT
            );

        fw1__Invoice_Line__c invoiceLine =
            PaymentCenterTestDataFactory.createInvoiceLine(
                invoice,
                PaymentCenterTestDataFactory.DEFAULT_AMOUNT
            );

        Opportunity opportunity =
            PaymentCenterTestDataFactory.createOpportunity(
                account,
                invoice
            );

        Datetime paymentDate =
            Datetime.newInstance(
                Date.today(),
                Time.newInstance(12, 0, 0, 0)
            );

        fw1__Payment__c payment =
            PaymentCenterTestDataFactory.createPayment(
                account,
                invoice,
                PaymentCenterTestDataFactory.DEFAULT_AMOUNT,
                paymentDate
            );

        fw1__Payment_Activity__c activity =
            PaymentCenterTestDataFactory.createPaymentActivity(
                payment,
                invoice,
                PaymentCenterTestDataFactory.DEFAULT_AMOUNT,
                paymentDate
            );

        PaymentCenterTestDataFactory.markInvoicePaid(
            invoice,
            PaymentCenterTestDataFactory.DEFAULT_AMOUNT
        );

        System.assertNotEquals(null, account.Id);
        System.assertNotEquals(null, invoice.Id);
        System.assertNotEquals(null, invoiceLine.Id);
        System.assertNotEquals(null, opportunity.Id);
        System.assertNotEquals(null, payment.Id);
        System.assertNotEquals(null, activity.Id);

        Opportunity savedOpportunity = [
            SELECT AccountId,
                AgreementInvoice__c,
                StageName,
                CloseDate,
                IsClosed,
                IsWon
            FROM Opportunity
            WHERE Id = :opportunity.Id
        ];

        System.assertEquals(
            account.Id,
            savedOpportunity.AccountId
        );

        System.assertEquals(
            invoice.Id,
            savedOpportunity.AgreementInvoice__c
        );

        System.assertEquals(
            'Contract',
            savedOpportunity.StageName
        );

        System.assertEquals(
            paymentDate.date(),
            savedOpportunity.CloseDate
        );

        System.assertEquals(
            true,
            savedOpportunity.IsClosed
        );

        System.assertEquals(
            true,
            savedOpportunity.IsWon
        );
    }
}
