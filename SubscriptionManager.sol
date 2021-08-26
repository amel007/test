pragma ton-solidity >=0.43.0;

pragma AbiHeader expire;
pragma AbiHeader time;

import './resolvers/IndexResolver.sol';
import './resolvers/DataResolver.sol';

contract SubscriptionManager is DataResolver, IndexResolver {

    uint256 _totalSubscriptions;
    address _ownerService;

    uint64 _value;
    uint32 _period;

    constructor(TvmCell codeIndex, TvmCell codeData, uint64 value, uint32 period) public {
        tvm.accept();
        _codeIndex = codeIndex;
        _codeData = codeData;
        _ownerService = msg.sender;
        _value = value;
        _period = period;
    }

    // need know that wallet set subscription to mapping variable
    function subscribe() public responsible returns (address) {

        // check msg.value == _value ???
        TvmCell codeData = _buildDataCode(address(this));
        TvmCell stateData = _buildDataState(codeData, _totalSubscriptions);
        // edit flag and value ??
        address addrSubscription = new SubscriptionData{stateInit: stateData, value: 1.1 ton}(_codeIndex, _value, _period);

        _totalSubscriptions++;

        return{value: 0, flag: 128} addrSubscription;
    }

    // only ownerWallet
    function executeSubscription (address addrWallet, address addrSubscription) {
        // Wallet(addrWallet).executeSubscription(addrSubscription)
    }
}