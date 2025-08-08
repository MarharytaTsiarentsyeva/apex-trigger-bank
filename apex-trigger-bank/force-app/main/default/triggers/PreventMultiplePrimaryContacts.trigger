trigger PreventMultiplePrimaryContacts on Contact (before insert, before update) {
    Set<Id> accountIds = new Set<Id>();

    for (Contact con : Trigger.new) {
        if (con.IsPrimary__c == true && con.AccountId != null) {
            accountIds.add(con.AccountId);
        }
    }

    Map<Id, List<Contact>> accountToPrimaryContacts = new Map<Id, List<Contact>>();

    if (!accountIds.isEmpty()) {
        List<Contact> primaryContacts = [
            SELECT Id, AccountId, IsPrimary__c
            FROM Contact
            WHERE IsPrimary__c = true AND AccountId IN :accountIds
        ];

        for (Contact pc : primaryContacts) {
            if (!accountToPrimaryContacts.containsKey(pc.AccountId)) {
                accountToPrimaryContacts.put(pc.AccountId, new List<Contact>());
            }
            accountToPrimaryContacts.get(pc.AccountId).add(pc);
        }
    }

    for (Contact con : Trigger.new) {
        if (con.IsPrimary__c == true && con.AccountId != null) {
            List<Contact> existingPrimaries = accountToPrimaryContacts.get(con.AccountId);

            Boolean isUpdatingSame = existingPrimaries != null &&
                existingPrimaries.anyMatch(existing =>
                    Trigger.isUpdate && existing.Id == con.Id
                );

            if (!isUpdatingSame && existingPrimaries != null && !existingPrimaries.isEmpty()) {
                con.addError('Only one primary contact is allowed per Account.');
            }
        }
    }
}