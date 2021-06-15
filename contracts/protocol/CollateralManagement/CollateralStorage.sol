pragma solidity 0.8.0;
import "../../access/AccessControlEnumerable.sol";

contract CollateralAccounting is AccessControlEnumerable {
    bytes32 public constant MANAGER_ROLE = keccak256("MANAGER_ROLE");

    constructor(address _timelock) {
        _setupRole(MANAGER_ROLE, _msgSender());
        _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());

        _setupRole(MANAGER_ROLE, _timelock);
        _setupRole(DEFAULT_ADMIN_ROLE, _timelock);
    }

    mapping(address => uint256) public depositors;

    function UpdateCollateralDeposit(address _adr, address _token uint256 _ammount) public {
        require(
            hasRole(MANAGER_ROLE, _msgSender()),
            "Must have manager role to make changes"
        );
        depositors[_adr][_token] = _ammount;
    }
}
