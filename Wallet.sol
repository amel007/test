pragma solidity >=0.6.0;

pragma experimental ABIEncoderV2;
pragma ignoreIntOverflow;
pragma AbiHeader expire;
pragma AbiHeader pubkey;
pragma AbiHeader time;

import './MultisigWallet.sol';

contract Wallet is MultisigWallet {

    mapping (address => bool) _subscriptions;

    // only ownerWallet
    function subscribe(address addrSubscription) {
        // add ownerService to mapping
        SubscriptionManager(addrSubscription).subscribe{value: 1.1 ton, callback: Wallet.addSubscription}();
    }

    // only ownerService
    function addSubscription (address addrSubscription) {
        // check ownerService exits in variable mapping
        _subscriptions[addrSubscription] = true;
    }

    // or only ownerWallet
    function executeSubscription (address addrSubscription) {
        // check exist in _subscriptions
        // check ownerService == msg.sender
        // transfer to ownerService
        // edit status, time and executeTime
        // and edit in SubscriptionData
    }

}