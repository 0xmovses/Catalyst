pragma solidity 0.8.0;
import "../../access/AccessControlEnumerable.sol";

contract IndexStorage is AccessControlEnumerable {
    bytes32 public constant MANAGER_ROLE = keccak256("MANAGER_ROLE");

    constructor(address _timelock) {
        _setupRole(MANAGER_ROLE, _msgSender());
        _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());

        _setupRole(MANAGER_ROLE, _timelock);
        _setupRole(DEFAULT_ADMIN_ROLE, _timelock);
    }

    // I decided to choose struct as you can determine the lenght of the array
    // And than loop though it.
    struct IndexTokens {
        address indexToken; // Address of the index token contract.
        address oracle; // Address to the Oracle
    }

    IndexTokens[] public indexTokens;

    function storeIndexToken(address _token, address _oracle) public {
        require(
            hasRole(MANAGER_ROLE, _msgSender()),
            "Must have manager role to add tokens"
        );
        indexTokens.push(IndexTokens({indexToken: _token, oracle: _oracle}));
    }

    function updateIndexTokenOracle(uint256 _index, address _oracle) public {
        require(
            hasRole(MANAGER_ROLE, _msgSender()),
            "Must have manager role to add tokens"
        );
        IndexTokens storage indexToken = indexTokens[_index];
        indexToken.oracle = _oracle;
    }
}
