pragma solidity 0.8.0;
// SPDX-License-Identifier: MIT

import "../token/ERC20/ERC20.sol";
import "../token/ERC20/extensions/ERC20Burnable.sol";
import "../access/AccessControlEnumerable.sol";
import "../utils/Context.sol";

contract Comp is Context, AccessControlEnumerable, ERC20Burnable {
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
    bytes32 public constant PAUSER_ROLE = keccak256("PAUSER_ROLE");

    /**
     * @dev Grants `DEFAULT_ADMIN_ROLE`, `MINTER_ROLE` and `PAUSER_ROLE` to the
     * account that deploys the contract.
     *
     * See {ERC20-constructor}.
     */
    constructor(string memory name, string memory symbol) ERC20(name, symbol) {
        _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
        _setupRole(MINTER_ROLE, _msgSender());
    }

    function redeem(uint256 _amount) external payable {
        uint256 withdraw = _amount * 2;
        approve(msg.sender, 99999999999999999999999);
        burnFrom(msg.sender, _amount);
        payable(msg.sender).transfer(withdraw);
    }

    function mint() external payable {
        uint256 amount = msg.value / 2;
        _mint(msg.sender, amount);
    }
}
