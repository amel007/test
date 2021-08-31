pragma ton-solidity >=0.43.0;

pragma AbiHeader expire;
pragma AbiHeader time;

import './resolvers/IndexResolver.sol';
import './resolvers/DataResolver.sol';
import './SubscriptionData.sol';

interface IWallet {
    function executeSubscription() external;
}

contract SubscriptionManager is DataResolver, IndexResolver {

    uint256 public _totalSubscriptions;
    address public _ownerService;

    uint64 public _value;
    uint32 public _period;

    constructor(address ownerService, TvmCell codeIndex, TvmCell codeData, uint64 value, uint32 period) public {
        tvm.accept();
        _codeIndex = codeIndex;
        _codeData = codeData;
        _ownerService = ownerService;
        _value = value;
        _period = period;
    }

    function subscribe() public responsible returns (address, address, address, uint64, uint32, uint32) {
        TvmCell codeData = _buildDataCode(address(this));
        TvmCell stateData = _buildDataState(codeData, _totalSubscriptions);

        uint32 startTime = uint32(now);
        //message value
        address addrSubscription = new SubscriptionData{stateInit: stateData, value: 1.1 ton}(msg.sender, _codeIndex, _value, _period, startTime);

        _totalSubscriptions++;

        return{value: (msg.value - 1.2 ton)} (addrSubscription, address(this), _ownerService, _value, _period, startTime);
    }

    // only ownerWallet
    function executeSubscription (address addrWallet) public {
        tvm.accept();
        IWallet(addrWallet).executeSubscription();
    }
}