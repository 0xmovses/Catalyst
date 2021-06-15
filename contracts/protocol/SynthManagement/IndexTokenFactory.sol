import "../../token/IndexToken.sol";

pragma solidity 0.8.0;

contract IndexTokenFactory {
    event ContractDeployed(address sender, string purpose);

    // Should Index Tokens be able to change their Issuers?
    function createIndexToken(
        string memory name,
        string memory symbol,
        address issuer
    ) public {
        new IndexToken(name, symbol, issuer);
    }
}
