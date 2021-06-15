pragma solidity ^0.8.0;

import "../access/Ownable.sol";

contract LandOracle is Ownable {
    uint256 public landPriceInMana;

    constructor() public {}

    mapping(address => bool) public oracleWhitelisted;

    modifier oracleWhitelist() {
        require(
            oracleWhitelisted[msg.sender] == true,
            "You don't have permission to update the price."
        );
        _;
    }

    function setOracleWhitelist(address _address) public onlyOwner {
        oracleWhitelisted[_address] = true;
    }

    /**
     * Returns the latest ETH price in USD
     */
    //  1800 aka 18000000000000000000000
    function getLatestETHPrice() public view returns (uint256) {
        int256 ETHprice = 194708712224;
        return uint256(ETHprice);
    }

    // 1.1 aka 1100000000000000000
    // How much mana for 1 eth = 1800 * 1.1
    function getLatestManaPrice() public view returns (uint256) {
        int256 MANAprice = 998893000000000000;
        return uint256(MANAprice);
    }

    //1944931696795680320000
    function manaPerEth() public view returns (uint256) {
        uint256 ManaPrice = getLatestManaPrice();
        uint256 ETHPrice = getLatestETHPrice();
        return (ManaPrice * ETHPrice) / 1e8;
    }

    function landIndexTokenPerEth() public view returns (uint256) {
        uint256 lastManaPerEth = manaPerEth();
        uint256 lastLandIndexTokenPerEth =
            (lastManaPerEth * 1e18) / landPriceInMana;
        return lastLandIndexTokenPerEth;
    }

    function requestLandData() public oracleWhitelist {
        fulfill(51624533333333340000000);
    }

    /**
     * Receive the response in the form of uint256
     */

    function fulfill(uint256 _landPriceInMana) public {
        landPriceInMana = _landPriceInMana;
    }
}
