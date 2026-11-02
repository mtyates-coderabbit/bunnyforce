/**
 * Minimal dependency-injection registry.
 *
 * Consumers depend on interfaces and resolve implementations through newInstance(), which
 * lets tests substitute fakes with setMock() instead of performing real callouts or DML.
 * Register every new abstraction in BINDINGS.
 */
public inherited sharing class Application {
    private static final Map<Type, Type> BINDINGS = new Map<Type, Type>{
        IPricingService.class => PricingService.class,
        IFulfillmentClient.class => FulfillmentClient.class
    };

    private static final Map<Type, Object> MOCKS = new Map<Type, Object>();

    /**
     * Returns the registered implementation (or test mock) for the given interface.
     */
    public static Object newInstance(Type abstraction) {
        if (MOCKS.containsKey(abstraction)) {
            return MOCKS.get(abstraction);
        }
        Type implementation = BINDINGS.get(abstraction);
        if (implementation == null) {
            throw new ApplicationException('No implementation registered for ' + abstraction.getName());
        }
        return implementation.newInstance();
    }

    @TestVisible
    private static void setMock(Type abstraction, Object mockInstance) {
        MOCKS.put(abstraction, mockInstance);
    }

    public class ApplicationException extends Exception {
    }
}
