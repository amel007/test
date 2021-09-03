pragma ton-solidity >=0.35.0;
pragma AbiHeader expire;
pragma AbiHeader time;
pragma AbiHeader pubkey;
import "./debot/Debot.sol";
import "https://raw.githubusercontent.com/tonlabs/DeBot-IS-consortium/main/Menu/Menu.sol";
import "https://raw.githubusercontent.com/tonlabs/DeBot-IS-consortium/main/Terminal/Terminal.sol";
import "https://raw.githubusercontent.com/tonlabs/DeBot-IS-consortium/main/AddressInput/AddressInput.sol";
import "https://raw.githubusercontent.com/tonlabs/DeBot-IS-consortium/main/Sdk/Sdk.sol";
import "./interfaces/IWallet.sol";

abstract contract Utility {
    function tonsToStr(uint128 nanotons) internal pure returns (string) {
        (uint64 dec, uint64 float) = _tokens(nanotons);
        string floatStr = format("{}", float);
        while (floatStr.byteLength() < 9) {
            floatStr = "0" + floatStr;
        }
        return format("{}.{}", dec, floatStr);
    }

    function _tokens(uint128 nanotokens) internal pure returns (uint64, uint64) {
        uint64 decimal = uint64(nanotokens / 1e9);
        uint64 float = uint64(nanotokens - (decimal * 1e9));
        return (decimal, float);
    }
}

contract SubscriptionDebot is Debot, Utility {


    address constant _addrServiceTest = address(0x8722c26c3732d1bc62f73f0a6d8946b9970d7e431bde97e2f5cb4ac6d8f5d696);
    address constant _ownerServiceTest = address(0xb8a0ef7edc5fd1e2c724451ae861d3203a80a4c7efc7002b5917f4c3dc35a610);
    uint64 constant _valueServiceTest = 650000000;
    uint32 constant _periodServiceTest = 86400;

    struct Payment {
        address ownerService;
        address addrSubscription;
        uint64 value;
        uint32 period;
        uint32 startTime;
        uint8 status;
        uint executeCount;
    }

    address m_wallet;
    mapping (address => Payment) public _subscriptions;
    address[] public _arraySubscriptions;
    address public _addrManagerChoose;
    bytes m_icon;

    function setIcon(bytes icon) public {
        require(msg.pubkey() == tvm.pubkey(), 100);
        tvm.accept();
        m_icon = icon;
    }

    /// @notice Entry point function for DeBot.
    function start() public override {
        AddressInput.get(tvm.functionId(startChecks), "Which wallet do you want to work with?");
    }

    function startChecks(address value) public {
        Sdk.getAccountType(tvm.functionId(checkStatus), value);
        m_wallet = value;
    }

    function checkStatus(int8 acc_type) public {
        if (!_checkActiveStatus(acc_type, "Wallet")) {
            start();
            return;
        }

        Sdk.getAccountCodeHash(tvm.functionId(checkWalletHash), m_wallet);
    }

    function _checkActiveStatus(int8 acc_type, string obj) private returns (bool) {
        if (acc_type == -1)  {
            Terminal.print(0, obj + " is inactive");
            return false;
        }
        if (acc_type == 0) {
            Terminal.print(0, obj + " is uninitialized");
            return false;
        }
        if (acc_type == 2) {
            Terminal.print(0, obj + " is frozen");
            return false;
        }
        return true;
    }
    function checkWalletHash(uint256 code_hash) public {
        if (code_hash != 0xbe99f35796cd40d2aa39a0cccfc7560fafe426c8eae1c2135f6f7a1b3f52a316) {
            Terminal.print(0, "Type of your wallet(codeHash) doesn't support");
            start();
            return;
        }
        preMain();
    }

    function preMain() public  {
        Sdk.getBalance(tvm.functionId(initWallet), m_wallet);
    }

    function initWallet(uint128 nanotokens) public  {
        string str = format("This wallet has {} tokens on the balance.", tonsToStr(nanotokens));
        Terminal.print(0, str);

        mainMenu();
    }

    function mainMenu() public {
        Menu.select("What's next?", "=)", [
            MenuItem("show my subscriptions", "", tvm.functionId(showMySubscriptions)),
            MenuItem("show all services", "", tvm.functionId(showAllServices))
        ]);
    }

    function showMySubscriptions(uint32 index) public {
        _getSubscriptions(tvm.functionId(beforeShowMySubscriptionsMenu));
    }

    function showAllServices(uint32 index) public {
        _getSubscriptions(tvm.functionId(beforeShowAllServicesMenu));
    }

    function getStrInfoSubscription(address addrManager, Payment info) private returns (string str){
        str = format("Subscription details:\n Service address: {}\n ownerService address: {}\n addrSubscription: {}\n value(nanotons): {:x}\n period(sec): {:x}\n startTime(unix): {:x}\n executeCount: {:x}",
            addrManager, info.ownerService, info.addrSubscription,
            info.value, info.period, info.startTime, info.executeCount);
    }

    function getStrInfoService() private returns (string str){
        str = format("Service details:\n Service address: {}\n ownerService address: {}\n value(nanotons): {:x}\n period(sec): {:x}",
            _addrServiceTest, _ownerServiceTest,
            _valueServiceTest, _periodServiceTest);
    }

    function beforeShowMySubscriptionsMenu(mapping(address => Payment) subscriptions) public {
        _subscriptions = subscriptions;
        showMySubscriptionsMenu();
    }

    function beforeShowAllServicesMenu(mapping(address => Payment) subscriptions) public {
        _subscriptions = subscriptions;
        showAllServicesMenu();
    }

    function showAllServicesMenu() public {

        Menu.select("Choose service:", "", [
            MenuItem(format("Service address:\n {}", _addrServiceTest), "", tvm.functionId(chooseServiceMenu)),
            MenuItem("Back to Main Menu", "", tvm.functionId(mainMenu))
        ]);
    }

    function chooseServiceMenu(uint32 index) public {
        _addrManagerChoose = _addrServiceTest;
        Terminal.print(0, getStrInfoService());
        MenuItem[] items;
        if (_subscriptions.exists(_addrServiceTest) == false) {
            items.push(MenuItem("subscribe", "", tvm.functionId(subscribe)));
        } else {
            items.push(MenuItem("cancel subscription", "", tvm.functionId(cancelSubscription)));
        }
        items.push( MenuItem("Back to Services", "", tvm.functionId(showAllServicesMenu)) );
        Menu.select("Actions:", "", items);
    }

    function subscribe() public {

        optional(uint256) pubkey = 0;
        IWallet(m_wallet).subscribe{
            abiVer: 2,
            sign: true,
            pubkey: pubkey,
            time: uint64(now),
            expire: 0,
            callbackId: tvm.functionId(onSubscribeSuccess),
            onErrorId: tvm.functionId(onError)
        }(_addrManagerChoose).extMsg;
    }

    function onSubscribeSuccess() public {
        Terminal.print(0, "Success! Request of subscription was sent!");
        mainMenu();
    }

    function showMySubscriptionsMenu() public {
        for (uint i = 0; i < _arraySubscriptions.length; i++) {
            delete _arraySubscriptions[i];
        }

        MenuItem[] items;
        optional(address, Payment) mapSubscriptions = _subscriptions.min();
        while (mapSubscriptions.hasValue()) {
            (address addrManager, Payment info) = mapSubscriptions.get();
            _arraySubscriptions.push(addrManager);

            items.push( MenuItem(format("Service address:\n {}", addrManager), "", tvm.functionId(chooseSubscriptionMenu)) );

            mapSubscriptions = _subscriptions.next(addrManager);
        }

        string str = "Choose subscription:";

        if (_subscriptions.empty() == true) {
            items.push( MenuItem("show all services", "", tvm.functionId(showAllServicesMenu)) );
            str = "not found subscriptions";
        }
        items.push( MenuItem("Back to Main Menu", "", tvm.functionId(mainMenu)) );
        Menu.select(str, "", items);
    }

    function chooseSubscriptionMenu(uint32 index) public {

        address addrManager = _arraySubscriptions[index];

        _addrManagerChoose = addrManager;

        Payment info = _subscriptions[addrManager];

        Terminal.print(0, getStrInfoSubscription(addrManager, info));
        Menu.select("Actions:", "", [
            MenuItem("cancel subscription", "", tvm.functionId(cancelSubscription)),
            MenuItem("Back to subscriptions", "", tvm.functionId(showMySubscriptionsMenu))
        ]);
    }

    function cancelSubscription() public {

        optional(uint256) pubkey = 0;
        IWallet(m_wallet).cancelSubscription{
            abiVer: 2,
            sign: true,
            pubkey: pubkey,
            time: uint64(now),
            expire: 0,
            callbackId: tvm.functionId(onCancelSubscriptionSuccess),
            onErrorId: tvm.functionId(onError)
        }(_addrManagerChoose).extMsg;
    }

    function onCancelSubscriptionSuccess() public {
        Terminal.print(0, "Success! Subscription was canceled!");
        mainMenu();
    }

    function onError(uint32 sdkError, uint32 exitCode) public {
        Terminal.print(0, format("Oooops! Action failed! sdkError: {:x}, exitCode {:x}", sdkError, exitCode));
        mainMenu();
    }

    function _getSubscriptions(uint32 answerId) private view {
        optional(uint256) none;
        IWallet(m_wallet).getSubscriptions{
            abiVer: 2,
            sign: false,
            pubkey: none,
            time: uint64(now),
            expire: 0,
            callbackId: answerId,
            onErrorId: 0
        }().extMsg;
    }

    /// @notice Returns Metadata about DeBot.
    function getDebotInfo() public functionID(0xDEB) override view returns (
        string name, string version, string publisher, string caption, string author,
        address support, string hello, string language, string dabi, bytes icon
    ) {
        name = "Subscription Manager";
        version = "1.0";
        publisher = "Roman";
        caption = "subscriptions";
        author = "Roman";
        support = address.makeAddrStd(0, 0xb8a0ef7edc5fd1e2c724451ae861d3203a80a4c7efc7002b5917f4c3dc35a610);
        hello = "Hello, i am a Subscription Manager v1.0 DeBot.";
        language = "en";
        dabi = m_debotAbi.get();
        icon = m_icon;
    }

    function getRequiredInterfaces() public view override returns (uint256[] interfaces) {
        return [Menu.ID, Terminal.ID];
    }
}
