pragma solidity >=0.6.0;

pragma experimental ABIEncoderV2;
pragma ignoreIntOverflow;
pragma AbiHeader expire;
pragma AbiHeader pubkey;
pragma AbiHeader time;

import './MultisigWallet.sol';
import './libraries/Constants.sol';

interface ISubscriptionManager {
    function subscribe() external responsible returns (address, address, address, uint64, uint32, uint32);
}

interface ISubscriptionData {
    function confirmExecute() external;
    function cancelSubscription() external;
}


contract Wallet is MultisigWallet {

    mapping (address => Payment) public _subscriptions;

    mapping (address => bool) public _allowedServices;

    struct Payment {
        address ownerService;
        address addrSubscription;
        uint64 value;
        uint32 period;
        uint32 startTime;
        uint8 status;
        uint executeCount;
    }

    function subscribe(address addrSubscriptionManager) public checkOwnerAndAccept {
        _allowedServices[addrSubscriptionManager] = true;

        ISubscriptionManager(addrSubscriptionManager).subscribe{value: 1.5 ton, flag: 1, callback: Wallet.addSubscription}();
    }

    function cancelSubscription(address addrSubscriptionManager) public checkOwnerAndAccept {
        require(_subscriptions.exists(addrSubscriptionManager) == true, 107);

        ISubscriptionData(_subscriptions[addrSubscriptionManager].addrSubscription).cancelSubscription{value: 1 ton}();
        delete _subscriptions[addrSubscriptionManager];
        delete _allowedServices[addrSubscriptionManager];
    }

    function addSubscription (
        address addrSubscription,
        address addrSubscriptionManager,
        address ownerService,
        uint64 value,
        uint32 period,
        uint32 startTime
    ) external {
        require(_allowedServices.exists(addrSubscriptionManager) == true, 104);
        require(_subscriptions.exists(addrSubscriptionManager) == false, 105);

        _subscriptions[addrSubscriptionManager] = Payment(ownerService, addrSubscription, value, period, startTime, Constants.STATUS_ACTIVE, 0);
    }

    function executeSubscription () external {
        require(_subscriptions.exists(msg.sender) == true, 106);
        tvm.accept();
        Payment subscription = _subscriptions[msg.sender];

        // change condition for tvm.accept();

        // maybe better send value to SubscriptionData???
        if (subscription.status == Constants.STATUS_ACTIVE) {

             if (
                 ( uint32(subscription.executeCount * subscription.period) + subscription.startTime ) <= uint32(now)
             ) {
                subscription.ownerService.transfer(subscription.value);
                subscription.executeCount = subscription.executeCount + 1;
                ISubscriptionData(subscription.addrSubscription).confirmExecute{value: 1 ton}();
             }

        }

    }

}