pragma solidity ^0.8.0;

// #### Interface for interacting with COMPOUND protocol ####
interface ICompProxy {
    function mint() external payable;

    function redeem(uint256 _amount) external;

    function balanceOf(address owner) external view returns (uint256 balance);
}
