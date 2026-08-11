
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

        Date originalCloseDate = opportunity.CloseDate;

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


        List<Opportunity_Auto_Close_Log__c> logs = [
            SELECT Id,
                Invoice__c,
                Payment_Activity__c,
                Payment__c,
                Opportunity__c,
                Payment_Date__c,
                Outcome__c,
                Previous_Stage__c,
                New_Stage__c,
                Previous_Close_Date__c,
                New_Close_Date__c,
                Result__c
            FROM Opportunity_Auto_Close_Log__c
            WHERE Opportunity__c = :savedOpportunity.Id
        ];

        System.assertEquals(
            1,
            logs.size(),
            'Exactly one audit log should be created.'
        );

        Opportunity_Auto_Close_Log__c log = logs[0];

        System.assertEquals(
            invoice.Id,
            log.Invoice__c
        );

        System.assertEquals(
            activity.Id,
            log.Payment_Activity__c
        );

        System.assertEquals(
            payment.Id,
            log.Payment__c
        );

        System.assertEquals(
            savedOpportunity.Id,
            log.Opportunity__c
        );

        System.assertEquals(
            paymentDate,
            log.Payment_Date__c
        );

        System.assertEquals(
            'Opportunity Closed',
            log.Outcome__c
        );

        System.assertEquals(
            'Awaiting Agreement',
            log.Previous_Stage__c
        );

        System.assertEquals(
            'Contract',
            log.New_Stage__c
        );

        System.assertEquals(
            paymentDate.date(),
            log.New_Close_Date__c
        );

        System.assertNotEquals(
            null,
            log.Result__c
        );

        System.assertEquals(
            originalCloseDate,
            log.Previous_Close_Date__c
        );



    }


    @IsTest
    static void logsWhenOpportunityIsAlreadyClosed() {

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

        // Put the Opportunity into an already-closed state.
        opportunity.StageName = 'Contract';
        opportunity.CloseDate = Date.today().addDays(-10);
        update opportunity;

        Date originalCloseDate = opportunity.CloseDate;

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

        Test.startTest();

        PaymentCenterTestDataFactory.markInvoicePaid(
            invoice,
            PaymentCenterTestDataFactory.DEFAULT_AMOUNT
        );

        Test.stopTest();

        Opportunity savedOpportunity = [
            SELECT StageName,
                CloseDate,
                IsClosed,
                IsWon
            FROM Opportunity
            WHERE Id = :opportunity.Id
        ];

        // Opportunity should remain unchanged.
        System.assertEquals(
            'Contract',
            savedOpportunity.StageName
        );

        System.assertEquals(
            originalCloseDate,
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

        List<Opportunity_Auto_Close_Log__c> logs = [
            SELECT Id,
                Invoice__c,
                Payment_Activity__c,
                Payment__c,
                Opportunity__c,
                Payment_Date__c,
                Outcome__c,
                Previous_Stage__c,
                New_Stage__c,
                Previous_Close_Date__c,
                New_Close_Date__c,
                Result__c
            FROM Opportunity_Auto_Close_Log__c
            WHERE Opportunity__c = :savedOpportunity.Id
        ];

        System.assertEquals(
            1,
            logs.size(),
            'Exactly one audit log should be created.'
        );

        Opportunity_Auto_Close_Log__c log = logs[0];

        System.assertEquals(
            invoice.Id,
            log.Invoice__c
        );

        System.assertEquals(
            activity.Id,
            log.Payment_Activity__c
        );

        System.assertEquals(
            payment.Id,
            log.Payment__c
        );

        System.assertEquals(
            savedOpportunity.Id,
            log.Opportunity__c
        );

        System.assertEquals(
            paymentDate,
            log.Payment_Date__c
        );

        System.assertEquals(
            'Opportunity Already Closed',
            log.Outcome__c
        );

        System.assertEquals(
            'Contract',
            log.Previous_Stage__c
        );

        System.assertEquals(
            originalCloseDate,
            log.Previous_Close_Date__c
        );

        System.assertEquals(
            null,
            log.New_Stage__c
        );

        System.assertEquals(
            null,
            log.New_Close_Date__c
        );

        System.assertNotEquals(
            null,
            log.Result__c
        );
    }

    @IsTest
    static void logsWhenNoOpportunityMatchesInvoice() {

        Account account =
            PaymentCenterTestDataFactory.createAccount();

        fw1__Invoice__c invoice =
            PaymentCenterTestDataFactory.createInvoice(
                account,
                PaymentCenterTestDataFactory.DEFAULT_AMOUNT
            );

        PaymentCenterTestDataFactory.createInvoiceLine(
            invoice,
            PaymentCenterTestDataFactory.DEFAULT_AMOUNT
        );

        // Intentionally do NOT create an Opportunity.

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

        Test.startTest();

        PaymentCenterTestDataFactory.markInvoicePaid(
            invoice,
            PaymentCenterTestDataFactory.DEFAULT_AMOUNT
        );

        Test.stopTest();

        List<Opportunity> opportunities = [
            SELECT Id
            FROM Opportunity
            WHERE AgreementInvoice__c = :invoice.Id
        ];

        System.assertEquals(
            0,
            opportunities.size(),
            'There should be no Opportunity linked to the invoice.'
        );

        List<Opportunity_Auto_Close_Log__c> logs = [
            SELECT Id,
                Invoice__c,
                Payment_Activity__c,
                Payment__c,
                Opportunity__c,
                Payment_Date__c,
                Outcome__c,
                Previous_Stage__c,
                New_Stage__c,
                Previous_Close_Date__c,
                New_Close_Date__c,
                Result__c
            FROM Opportunity_Auto_Close_Log__c
            WHERE Invoice__c = :invoice.Id
        ];

        System.assertEquals(
            1,
            logs.size(),
            'Exactly one audit log should be created.'
        );

        Opportunity_Auto_Close_Log__c log = logs[0];

        System.assertEquals(
            invoice.Id,
            log.Invoice__c
        );

        System.assertEquals(
            activity.Id,
            log.Payment_Activity__c
        );

        System.assertEquals(
            payment.Id,
            log.Payment__c
        );

        System.assertEquals(
            null,
            log.Opportunity__c
        );

        System.assertEquals(
            paymentDate,
            log.Payment_Date__c
        );

        System.assertEquals(
            'No Matching Opportunity',
            log.Outcome__c
        );

        System.assertEquals(
            null,
            log.Previous_Stage__c
        );

        System.assertEquals(
            null,
            log.New_Stage__c
        );

        System.assertEquals(
            null,
            log.Previous_Close_Date__c
        );

        System.assertEquals(
            null,
            log.New_Close_Date__c
        );

        System.assertNotEquals(
            null,
            log.Result__c
        );
    }
}
