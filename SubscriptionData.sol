pragma ton-solidity >=0.43.0;

pragma AbiHeader expire;
pragma AbiHeader time;

import './resolvers/IndexResolver.sol';

import './interfaces/IData.sol';

import './libraries/Constants.sol';


contract SubscriptionData is IData, IndexResolver {

    address public _addrRoot;
    address public _addrOwner;

    uint64 public _value;
    uint32 public _period;

    uint public _executeCount;
    uint32 public _startTime;
    uint8 public _status;

    uint256 static _id;

    constructor(address addrOwner, TvmCell codeIndex, uint64 value, uint32 period, uint32 startTime) public {
        optional(TvmCell) optSalt = tvm.codeSalt(tvm.code());
        require(optSalt.hasValue(), 101);
        (address addrRoot) = optSalt.get().toSlice().decode(address);
        require(msg.sender == addrRoot);
        require(msg.value >= Constants.MIN_FOR_DEPLOY);
        tvm.accept();
        _addrRoot = addrRoot;
        _addrOwner = addrOwner;
        _codeIndex = codeIndex;

        _value = value;
        _period = period;
        _startTime = startTime;
        _status = Constants.STATUS_ACTIVE;
        _executeCount = 0;

        deployIndex(addrOwner);
    }

    function confirmExecute() external {
        require(msg.sender == _addrOwner, 110);
        _executeCount++;
        msg.sender.transfer({value: 0, flag: 64});
    }

    function cancelSubscription() external {
        require(msg.sender == _addrOwner);

        address indexOwner = resolveIndex(_addrRoot, address(this), _addrOwner);
        IIndex(indexOwner).destruct();
        address indexOwnerRoot = resolveIndex(address(0), address(this), _addrOwner);
        IIndex(indexOwnerRoot).destruct();

        selfdestruct(_addrOwner);
    }

    function getTimeEndPeriod() private view returns (uint32) {
        return (uint32(_executeCount * _period) + _startTime);
    }

    function isExecutedStatus() public view returns (bool isExecuted, uint32 endTime) {
        isExecuted = false;
        endTime = getTimeEndPeriod();
        if (_status == Constants.STATUS_ACTIVE && endTime > uint32(now)) {
            isExecuted = true;
        }
    }

    function isAllowExecute() public view returns (bool isAllow, uint32 allowedTimeExecute) {
        isAllow = false;
        allowedTimeExecute = getTimeEndPeriod();
        if (_status == Constants.STATUS_ACTIVE && allowedTimeExecute <= uint32(now)) {
            isAllow = true;
        }
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