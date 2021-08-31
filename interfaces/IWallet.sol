pragma ton-solidity >= 0.43.0;

interface IWallet {

    struct Payment {
        address ownerService;
        address addrSubscription;
        uint64 value;
        uint32 period;
        uint32 startTime;
        uint8 status;
        uint executeCount;
    }

    function subscribe(address addrSubscriptionManager) external;
    function cancelSubscription(address addrSubscriptionManager) external;
    function getInfoSubscription(address addrSubscriptionManager) external view returns (Payment info);
}
