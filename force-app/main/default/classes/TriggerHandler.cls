/**
 * Base class for every trigger handler in the org.
 *
 * Conventions (see docs/apex-standards.md):
 *  - Exactly one trigger per SObject. The trigger contains a single line that calls
 *    `new XTriggerHandler().run()`; no logic lives in the trigger body.
 *  - Handlers override only the context methods they need and delegate business logic
 *    to service classes.
 *  - A handler can be disabled for an object through Trigger_Setting__mdt (data loads,
 *    incident response) or for the rest of a transaction via bypass().
 */
public virtual inherited sharing class TriggerHandler {
    private static final Set<String> BYPASSED = new Set<String>();

    @TestVisible
    private static Map<String, Boolean> settingOverrides = new Map<String, Boolean>();

    @TestVisible
    protected System.TriggerOperation operation;
    @TestVisible
    protected List<SObject> newRecords;
    @TestVisible
    protected Map<Id, SObject> newMap;
    @TestVisible
    protected Map<Id, SObject> oldMap;

    private final String settingName;

    /**
     * @param settingName DeveloperName of the Trigger_Setting__mdt record that controls this
     *                    handler, and the key used by bypass()/clearBypass().
     */
    public TriggerHandler(String settingName) {
        this.settingName = settingName;
        this.operation = Trigger.operationType;
        this.newRecords = Trigger.new;
        this.newMap = Trigger.newMap;
        this.oldMap = Trigger.oldMap;
    }

    /**
     * Dispatches to the context method matching the current trigger operation.
     */
    public void run() {
        if (!isEnabled()) {
            return;
        }
        switch on operation {
            when BEFORE_INSERT {
                beforeInsert();
            }
            when BEFORE_UPDATE {
                beforeUpdate();
            }
            when BEFORE_DELETE {
                beforeDelete();
            }
            when AFTER_INSERT {
                afterInsert();
            }
            when AFTER_UPDATE {
                afterUpdate();
            }
            when AFTER_DELETE {
                afterDelete();
            }
            when AFTER_UNDELETE {
                afterUndelete();
            }
        }
    }

    /**
     * Skips the named handler for the remainder of the transaction.
     */
    public static void bypass(String settingName) {
        BYPASSED.add(settingName);
    }

    public static void clearBypass(String settingName) {
        BYPASSED.remove(settingName);
    }

    public static Boolean isBypassed(String settingName) {
        return BYPASSED.contains(settingName);
    }

    @TestVisible
    private Boolean isEnabled() {
        if (operation == null || isBypassed(settingName)) {
            return false;
        }
        if (settingOverrides.containsKey(settingName)) {
            return settingOverrides.get(settingName);
        }
        Trigger_Setting__mdt setting = Trigger_Setting__mdt.getInstance(settingName);
        return setting == null || setting.Is_Active__c;
    }

    /**
     * True when the value of the given field differs between Trigger.old and Trigger.new.
     */
    protected Boolean isChanged(SObject record, Schema.SObjectField field) {
        if (oldMap == null || record.Id == null) {
            return true;
        }
        SObject previous = oldMap.get(record.Id);
        return previous == null || previous.get(field) != record.get(field);
    }

    protected virtual void beforeInsert() {
    }
    protected virtual void beforeUpdate() {
    }
    protected virtual void beforeDelete() {
    }
    protected virtual void afterInsert() {
    }
    protected virtual void afterUpdate() {
    }
    protected virtual void afterDelete() {
    }
    protected virtual void afterUndelete() {
    }
}
