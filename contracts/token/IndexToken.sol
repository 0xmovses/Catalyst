// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./ERC20/ERC20.sol";

contract IndexToken is ERC20 {
    address public issuer;
    event Deployed(address adr);

    constructor(
        string memory name,
        string memory symbol,
        address _issuer
    ) ERC20(name, symbol) {
        issuer = _issuer;
        emit Deployed(address(this));
    }

    function mint(address to, uint256 amount) public virtual {
        require(msg.sender == issuer, "Not Allowed");
        _mint(to, amount);
    }
}
