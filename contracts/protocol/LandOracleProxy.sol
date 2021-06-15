pragma solidity ^0.8.0;

// Interface to request price from the oracle.
interface ILandEthPriceOracle {
    function landIndexTokenPerEth() external view returns (uint256);
}
