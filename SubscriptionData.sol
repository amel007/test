pragma ton-solidity >=0.43.0;

pragma AbiHeader expire;
pragma AbiHeader time;

import './resolvers/IndexResolver.sol';

import './interfaces/IData.sol';

import './libraries/Constants.sol';


contract SubscriptionData is IData, IndexResolver {

    address _addrRoot;
    address _addrOwner;

    uint64 _value;
    uint32 _period;

    uint256 _executeCount;
    uint32 _startTime;
    uint8 _status;

    uint256 static _id;

    constructor(TvmCell codeIndex, uint64 value, uint32 period) public {
        optional(TvmCell) optSalt = tvm.codeSalt(tvm.code());
        require(optSalt.hasValue(), 101);
        (address addrRoot) = optSalt.get().toSlice().decode(address);
        require(msg.value >= Constants.MIN_FOR_DEPLOY);
        tvm.accept();
        _addrRoot = addrRoot;
        _addrOwner = msg.sender;
        _codeIndex = codeIndex;

        _value = value;
        _period = period;
        _startTime = uint32(now);
        _status = Constants.STATUS_ACTIVE;
        _executeCount = 0;

        deployIndex(msg.sender);
    }

    function deployIndex(address owner) private {
        TvmCell codeIndexOwner = _buildIndexCode(_addrRoot, owner);
        TvmCell stateIndexOwner = _buildIndexState(codeIndexOwner, address(this));
        new Index{stateInit: stateIndexOwner, value: 0.4 ton}(_addrRoot);

        TvmCell codeIndexOwnerRoot = _buildIndexCode(address(0), owner);
        TvmCell stateIndexOwnerRoot = _buildIndexState(codeIndexOwnerRoot, address(this));
        new Index{stateInit: stateIndexOwnerRoot, value: 0.4 ton}(_addrRoot);
    }

    function getInfo() public view override returns (
        address addrRoot,
        address addrOwner,
        address addrData
    ) {
        addrRoot = _addrRoot;
        addrOwner = _addrOwner;
        addrData = address(this);
    }

    function getOwner() public view override returns(address addrOwner) {
        addrOwner = _addrOwner;
    }
}