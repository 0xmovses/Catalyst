pragma solidity 0.8.0;
import "./IndexStorage.sol";

// Change it into a Struct calling proxy
interface IIndexStorage {
    function indexTokens(uint256 index) external view returns (uint256);
}

contract IndexTokenController {
    // #### RETURNS THE PRICE OF THE INDEX #####

    address public IndexStorageAdr;

    constructor(address _indexStorageAdr) {
        IndexStorageAdr = _indexStorageAdr;
    }

    function IndexTokenOraclePrice(uint256 index)
        public
        view
        returns (uint256)
    {
        // Change it into a Struct calling proxy
        IIndexStorage(IndexStorageAdr).indexTokens(index).oracle;
    }

    function IssueIndexToken(uint256 ammount, uint256 index) public {
        // TODO: Check Index Token Current Price
        // TODO: Check collateral health.
    }

    function ReturnIndexToken(uint256 ammount) public {}
}
