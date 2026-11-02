@IsTest
private class ApplicationTest {
    @IsTest
    static void resolvesRegisteredImplementation() {
        Object instance = Application.newInstance(IPricingService.class);

        Assert.isInstanceOfType(instance, PricingService.class, 'IPricingService should resolve to PricingService');
    }

    @IsTest
    static void returnsMockWhenRegistered() {
        FakeFulfillmentClient fake = new FakeFulfillmentClient();
        Application.setMock(IFulfillmentClient.class, fake);

        Assert.areEqual(fake, Application.newInstance(IFulfillmentClient.class), 'Registered mock should be returned');
    }

    @IsTest
    static void unregisteredTypeThrows() {
        try {
            Application.newInstance(String.class);
            Assert.fail('Expected ApplicationException for an unregistered type');
        } catch (Application.ApplicationException ex) {
            Assert.isTrue(ex.getMessage().contains('String'), 'Message should name the missing type');
        }
    }
}
