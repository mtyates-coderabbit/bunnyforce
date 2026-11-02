trigger OrderItemTrigger on OrderItem(
    before insert,
    before update,
    before delete,
    after insert,
    after update,
    after delete,
    after undelete
) {
    new OrderItemTriggerHandler().run();
}
