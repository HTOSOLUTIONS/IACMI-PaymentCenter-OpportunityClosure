@IsTest
private class ActivityRollupTriggerTest {

    @IsTest
    static void testTaskAndEmailTriggers_rollupLatestAndFallback() {
        Opportunity opp = ActivityRollupTestDataFactory.createOpportunity();

        Task task = new Task(
            WhatId = opp.Id,
            Subject = 'Task subject',
            Description = 'Task notes',
            Status = 'Completed',
            ActivityDate = Date.today().addDays(-2)
        );
        insert task;

        Opportunity afterTask = [
            SELECT Last_Activity_Type__c,
                   Last_Activity_Subject__c,
                   Last_Activity_Notes__c,
                   Last_Activity_DateTime__c
            FROM Opportunity
            WHERE Id = :opp.Id
        ];

        System.assertEquals('Task', afterTask.Last_Activity_Type__c, 'Task insert should set type to Task.');
        System.assertEquals('Task subject', afterTask.Last_Activity_Subject__c, 'Task subject should roll up.');
        System.assertEquals('Task notes', afterTask.Last_Activity_Notes__c, 'Task description should roll up.');
        System.assertNotEquals(null, afterTask.Last_Activity_DateTime__c, 'Task insert should set date/time.');

        Datetime emailDate = System.now().addDays(2);
        EmailMessage email = new EmailMessage(
            RelatedToId = opp.Id,
            Subject = 'Email subject',
            TextBody = 'Email notes',
            FromAddress = 'from@example.com',
            ToAddress = 'to@example.com',
            Incoming = false,
            Status = '3',
            MessageDate = emailDate
        );
        insert email;

        Opportunity afterEmailInsert = [
            SELECT Last_Activity_Type__c,
                   Last_Activity_Subject__c,
                   Last_Activity_Notes__c,
                   Last_Activity_DateTime__c
            FROM Opportunity
            WHERE Id = :opp.Id
        ];

        System.assertEquals('Email', afterEmailInsert.Last_Activity_Type__c, 'Later email should become latest activity.');
        System.assertEquals('Email subject', afterEmailInsert.Last_Activity_Subject__c, 'Email subject should roll up.');
        System.assertEquals('Email notes', afterEmailInsert.Last_Activity_Notes__c, 'Email body should roll up.');
        System.assertEquals(emailDate, afterEmailInsert.Last_Activity_DateTime__c, 'Email MessageDate should roll up.');

        String longSubject = buildRepeatedCharString('X', 300);
        Datetime updatedEmailDate = System.now().addDays(3);
        email.Subject = longSubject;
        email.TextBody = 'Updated email notes';
        email.MessageDate = updatedEmailDate;
        update email;

        Opportunity afterEmailUpdate = [
            SELECT Last_Activity_Type__c,
                   Last_Activity_Subject__c,
                   Last_Activity_Notes__c,
                   Last_Activity_DateTime__c
            FROM Opportunity
            WHERE Id = :opp.Id
        ];

        System.assertEquals('Email', afterEmailUpdate.Last_Activity_Type__c, 'Email update should keep email as latest.');
        System.assertEquals(255, afterEmailUpdate.Last_Activity_Subject__c.length(), 'Subject should be truncated to 255 chars.');
        System.assertEquals('Updated email notes', afterEmailUpdate.Last_Activity_Notes__c, 'Updated notes should roll up.');
        System.assertEquals(updatedEmailDate, afterEmailUpdate.Last_Activity_DateTime__c, 'Updated MessageDate should roll up.');

        delete email;

        Opportunity afterEmailDelete = [
            SELECT Last_Activity_Type__c,
                   Last_Activity_Subject__c,
                   Last_Activity_Notes__c,
                   Last_Activity_DateTime__c
            FROM Opportunity
            WHERE Id = :opp.Id
        ];

        System.assertEquals('Task', afterEmailDelete.Last_Activity_Type__c, 'Deleting email should fall back to remaining task.');
        System.assertEquals('Task subject', afterEmailDelete.Last_Activity_Subject__c, 'Task subject should be restored.');
        System.assertEquals('Task notes', afterEmailDelete.Last_Activity_Notes__c, 'Task notes should be restored.');
        System.assertNotEquals(null, afterEmailDelete.Last_Activity_DateTime__c, 'Task date/time should be restored.');

        delete task;

        Opportunity afterTaskDelete = [
            SELECT Last_Activity_Type__c,
                   Last_Activity_Subject__c,
                   Last_Activity_Notes__c,
                   Last_Activity_DateTime__c
            FROM Opportunity
            WHERE Id = :opp.Id
        ];

        System.assertEquals(null, afterTaskDelete.Last_Activity_Type__c, 'Deleting final activity should clear type.');
        System.assertEquals(null, afterTaskDelete.Last_Activity_Subject__c, 'Deleting final activity should clear subject.');
        System.assertEquals(null, afterTaskDelete.Last_Activity_Notes__c, 'Deleting final activity should clear notes.');
        System.assertEquals(null, afterTaskDelete.Last_Activity_DateTime__c, 'Deleting final activity should clear date/time.');
    }

    private static String buildRepeatedCharString(String characterValue, Integer count) {
        String value = '';
        for (Integer i = 0; i < count; i++) {
            value += characterValue;
        }
        return value;
    }
}