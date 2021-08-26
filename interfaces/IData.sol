pragma ton-solidity >= 0.43.0;

interface IData {
    function getOwner() external view returns (address addrOwner);
    function getInfo() external view returns (
        address addrRoot,
        address addrOwner,
        address addrData
    );
}
