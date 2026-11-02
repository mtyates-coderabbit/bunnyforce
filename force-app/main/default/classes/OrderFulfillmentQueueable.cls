/**
 * Asynchronously submits orders to the 3PL in chunks that stay within the callout limit,
 * chaining a new job for any remainder.
 */
public inherited sharing class OrderFulfillmentQueueable implements Queueable, Database.AllowsCallouts {
    private static final Integer DEFAULT_CHUNK_SIZE = 50;

    // Apex tests cannot chain queueable jobs; the remainder path is covered by asserting on
    // remainingAfter() instead.
    @TestVisible
    private static Boolean chainingEnabled = !Test.isRunningTest();

    private final List<Id> orderIds;

    public OrderFulfillmentQueueable(Set<Id> orderIds) {
        this.orderIds = new List<Id>(orderIds);
    }

    /**
     * Enqueues a job when the transaction still has queueable capacity; otherwise logs the
     * orders so they can be resubmitted.
     */
    public static void enqueue(Set<Id> orderIds) {
        if (orderIds == null || orderIds.isEmpty()) {
            return;
        }
        if (Limits.getQueueableJobs() >= Limits.getLimitQueueableJobs()) {
            Logger.error(
                'OrderFulfillmentQueueable.enqueue',
                'Queueable limit reached; orders not submitted for fulfillment: ' + orderIds,
                null
            );
            return;
        }
        System.enqueueJob(new OrderFulfillmentQueueable(orderIds));
    }

    public void execute(QueueableContext context) {
        Integer chunkSize = chunkSize();
        Set<Id> current = new Set<Id>();
        for (Integer i = 0; i < orderIds.size() && i < chunkSize; i++) {
            current.add(orderIds[i]);
        }

        new OrderFulfillmentService().submit(current);

        Set<Id> remaining = remainingAfter(chunkSize);
        if (!remaining.isEmpty() && chainingEnabled) {
            System.enqueueJob(new OrderFulfillmentQueueable(remaining));
        }
        Logger.flush();
    }

    @TestVisible
    private Set<Id> remainingAfter(Integer chunkSize) {
        Set<Id> remaining = new Set<Id>();
        for (Integer i = chunkSize; i < orderIds.size(); i++) {
            remaining.add(orderIds[i]);
        }
        return remaining;
    }

    private static Integer chunkSize() {
        Integer configured = BunnyforceSettings.getInteger(
            BunnyforceSettings.FULFILLMENT_BATCH_SIZE,
            DEFAULT_CHUNK_SIZE
        );
        return Math.min(configured, Limits.getLimitCallouts());
    }
}
