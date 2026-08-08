trigger CampaignMemberTrigger on CampaignMember (after insert) {

    // Minimal trigger: enqueue only the CampaignMember ids that look eligible.
    List<Id> cmIds = new List<Id>();

    for (CampaignMember cm : Trigger.new) {
        // Only Leads are supported in this flow (per your design)
        if (cm.LeadId != null && String.isNotBlank(cm.Status)) {
            cmIds.add(cm.Id);
        }
    }

    if (!cmIds.isEmpty()) {
        System.enqueueJob(new CanvasEnrollmentQueueable(cmIds));
    }
}