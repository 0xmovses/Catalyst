pragma solidity ^0.8.0;
import "../token/cLand.sol";
import "./UniProxy.sol";
import "../utils/math/SafeMath.sol";
import "./CompProxy.sol";
import "./LandOracleProxy.sol";
import "../access/Ownable.sol";
import "../token/LystToken.sol";

contract CollateralAndMint is Ownable {
    using SafeMath for uint256;

    // Address of Oracle smart contract that is used to set price for Decentraland Land Index.
    // The price is requested though Chainlink, GET API call.
    // The API call link is: https://whispering-beyond-26434.herokuapp.com/decentraland/orders/price-mean/750
    // API request is a proxy to communicate with The Graph.
    // This request allows us to collect last 750 Land sale prices.
    // We take the mean price and set the dLand Token minting price accordingly.
    // Price will be updated by Keepers in the future.

    address public oracleAddress;
    // All ETH collateral deposits are re-routed to Compound protocol to earn interest.
    // The earned interest is then used to buyback protocol tokens and burn them.
    // With the purpose of creating deflation for the protocol token.
    address public compAddress;
    // Collateral requirements for minting dLand, which is set on the contract deployment.
    uint256 public collateralRequirementPercent;
    // Compound ETH balance.
    uint256 public cETHCurrentBalance;
    // For transparancy purposes we keep a balance of how much protocol tokens have we burned.
    uint256 public tokenBurnBalance;

    // Since we re-route the collateral deposits to Compound we might have to keep track of the TVL
    // TODO: uint256 public totalValueLocked;

    constructor(
        cLand _clandtoken,
        LystToken _lysttoken,
        uint256 _collateralrequirementpercent,
        address _oracleaddress,
        address _compeaddress,
        address _uniswap
    ) public {
        cLandIndexToken = _clandtoken;
        lystToken = _lysttoken;
        collateralRequirementPercent = _collateralrequirementpercent;
        oracleAddress = _oracleaddress;
        compAddress = _compeaddress;
        uniswap = IUniswap(_uniswap);
    }

    // Uniswap contract interface.
    IUniswap uniswap;

    // TODO: Make Index tokens independant of this contract.
    // ^^^^ This contract will be used to interact with other Index tokens
    // ^^^^ That are accepted by the protocol.

    // Contracts of tokens used in the protocol.
    cLand public cLandIndexToken;
    LystToken public lystToken;

    // CONTRACT IS ABLE TO RECIEVE ETH.
    // ETH is used to buyback and burn Protocol native tokens.
    receive() external payable {}

    // ##### ACCOUNTING HAPPENS HERE #####

    // TODO: Impliment liquidation functinality.
    // Liquidation function should use the liquidated collateral, buy Dland from market and burn it.
    // Needs to be though though.

    // We keep track of each users deposits.
    mapping(address => uint256) public collateralBalance;
    // Portion of used collateral.
    mapping(address => uint256) public collateralUsedEth;
    // Borrow limit of the user in ETH.
    // It is based on the collateral requarement %
    mapping(address => uint256) public currentBorrowLimitEth;
    // We keep track how much of the Comp Eth we got belongs to the user.
    mapping(address => uint256) public cETH;

    event TokensMinted(
        address account,
        address token,
        uint256 amount,
        uint256 rate
    );

    event EthUncollaterased(address account, uint256 amount);
    event TokensBurned(address account, address token, uint256 amount);

    // #### RETURNS THE PRICE OF DECENTRALAND INDEX #####
    function landIndexPrice() public view returns (uint256) {
        return ILandEthPriceOracle(oracleAddress).landIndexTokenPerEth();
    }

    // ##### ACCOUNTING CALCULATION HAPPENS HERE #####

    // Adjust Collateral Balance Based on Deposits and withdraws.
    function calculateCollateralBalance(uint256 _deposit, uint256 _withdraw)
        private
    {
        // Increase borrow limit on deposit.
        if (_deposit > 0) {
            collateralBalance[msg.sender] = collateralBalance[msg.sender].add(
                _deposit
            );
            calculateBorrowLimit();
        }
        // Decreases borrow limit on withdraw.
        if (_withdraw > 0) {
            collateralBalance[msg.sender] = collateralBalance[msg.sender].sub(
                _withdraw
            );
            calculateBorrowLimit();
        }
    }

    // Everytime we mint or burn, we calculate the new borrow limit.
    function calculateCollateralUse(uint256 _mint, uint256 _burn) private {
        uint256 landPerEthPrice = landIndexPrice();
        //
        if (_mint > 0) {
            collateralUsedEth[msg.sender] = _mint
                .mul(1e18)
                .div(landPerEthPrice)
                .add(collateralUsedEth[msg.sender]);
            calculateBorrowLimit();
        }
        if (_burn > 0) {
            uint256 balance = cLandIndexToken.balanceOf(msg.sender);
            // Avoiding rounding errors.
            if (balance == _burn) {
                collateralUsedEth[msg.sender] = collateralUsedEth[msg.sender]
                    .sub(collateralUsedEth[msg.sender]);
            } else {
                collateralUsedEth[msg.sender] = collateralUsedEth[msg.sender]
                    .sub(_burn.mul(1e18).div(landPerEthPrice));
            }
            calculateBorrowLimit();
        }
    }

    // Function used whenever we have any interaction deposit, withdraw, mint or burn.
    function calculateBorrowLimit() private {
        currentBorrowLimitEth[msg.sender] = collateralBalance[msg.sender].sub(
            collateralBalance[msg.sender]
                .div(10000)
                .mul(collateralRequirementPercent)
                .add(collateralUsedEth[msg.sender])
        );
    }

    // ^^^^^^ ACCOUNTING CALCULATION ENDS HERE ^^^^^^^^

    // ##### MINTING AND BURNING STARTS HERE #####

    // Creates the Land Index Sythetic Token & updates borrow limits.
    function mintAsset(uint256 _amount) public {
        uint256 tokenPricePerEth = landIndexPrice();
        require(
            currentBorrowLimitEth[msg.sender].mul(1e18).div(tokenPricePerEth) >=
                _amount,
            "Reason: Over allowed ammount"
        );

        calculateCollateralUse(_amount, 0);
        cLandIndexToken.mint(msg.sender, _amount);

        emit TokensMinted(
            msg.sender,
            address(cLandIndexToken),
            _amount,
            tokenPricePerEth
        );
    }

    //  Return the Shyntetic asset in order to free the collateral
    function burnAsset(uint256 _amount) public {
        require(
            collateralUsedEth[msg.sender] > 0,
            "Reason: No deposit was made."
        );
        // Re-calculating the collateral usage.
        calculateCollateralUse(0, _amount);
        cLandIndexToken.burnFrom(msg.sender, _amount);

        emit TokensBurned(msg.sender, address(cLandIndexToken), _amount);
    }

    // ^^^^^ MINTING AND BURNING STARTS HERE ^^^^^^^

    // ##### COLLATERAL DEPOSITS AND WITHDRAWS START HERE #####

    // User sends ETH as collateral though this function.
    function collateralizeEth() public payable {
        //  We set his balance and borrow limit.
        calculateCollateralBalance(msg.value, 0);
        // We re-direct the deposit to Compound Protocol.
        ICompProxy(compAddress).mint{value: msg.value}();
        // We get the new balance total of Comp on our smart contract.
        uint256 cETHNewBalance =
            ICompProxy(compAddress).balanceOf(address(this));
        // Connect the amount that belongs to user with his wallet address.
        cETH[msg.sender] = cETHNewBalance.sub(cETHCurrentBalance);
        // We replace the last balance with the new balance.
        cETHCurrentBalance = cETHNewBalance;
    }

    function prepWithdraw(uint256 _amount) private {
        // Calculate the portion of the withdraw.
        uint256 withdrawPortion = _amount;
        // Redeem and substract from CETH Balance of user.
        cETH[msg.sender] = cETH[msg.sender].sub(withdrawPortion);
        // Reduce total balance of CETH
        cETHCurrentBalance = cETHCurrentBalance.sub(withdrawPortion);
        // Send redeem request to COMP
        ICompProxy(compAddress).redeem(_amount);
    }

    function withdrawCollateral(uint256 _amount) public {
        // Requare that has made deposits he wants to withdraw & Requare that user is withdrawing less than locked up collateral.
        require(
            _amount <=
                collateralBalance[msg.sender].sub(
                    collateralUsedEth[msg.sender].mul(10000).div(
                        10000 - collateralRequirementPercent
                    )
                ),
            "Reason: Exeeds allowed"
        );
        // Calculate the portion of the withdraw.
        uint256 withdrawpercent =
            _amount.mul(1e18).div(collateralBalance[msg.sender]);
        uint256 withdrawPortion =
            cETH[msg.sender].mul(withdrawpercent).div(1e18);
        prepWithdraw(withdrawPortion);
        require(
            address(this).balance >= _amount,
            "Reason: Protocol out of ETH "
        );
        // Calculate the withdraw balance to avoid reentrancy attack.
        calculateCollateralBalance(0, _amount);
        // Return ETH to user.
        payable(msg.sender).transfer(_amount);

        // Emit an eventx
        emit EthUncollaterased(msg.sender, _amount);
    }

    // ^^^^^^^ COLLATERAL DEPOSITS AND WITHDRAWS END HERE ^^^^^^^^^^

    // ##### TOKEN BUYBACK AND BURN START HERE #####

    // Contract owner can do a buyback and token Burn.
    function buyBackAndBurn() external payable onlyOwner {
        address[] memory path = new address[](2);
        path[0] = uniswap.WETH();
        path[1] = address(lystToken);
        uint256 ethBalance = address(this).balance;
        // Calling UNISWAP to buy back Protocol Tokens
        uniswap.swapExactETHForTokens{value: ethBalance}(
            1,
            path,
            address(this),
            block.timestamp
        );
        // Adding to the balance how much tokens have we burned.
        tokenBurnBalance =
            tokenBurnBalance +
            lystToken.balanceOf(address(this));
        // Burning the Tokens.
        lystToken.burn(lystToken.balanceOf(address(this)));
    }

    // ^^^^^^^ TOKEN BUYBACK AND BURN END HERE ^^^^^^^^^^

    // ##### LIQUIDATION STARTS HERE #####

    // function liquidationCall(address user) external {
    //     //   Calculate the collateral balance and collateral used percentage.

    //     uint256 status =
    //         (collateralUsedEth[user] * 100) / collateralBalance[user];
    //     require(status > 60, "Reason: User can't be liquidated");
    //     // Calculate what portion needs to be liquidated

    //     //   prepWithdraw()
    // }

    // ^^^^^^^ LIQUIDATION END HERE ^^^^^^^^^^

    // Update contract address where the price feed is coming from.
    // Most likely a temporary function and will be removed in the future.
    function updateOracleAddress(address _address) public onlyOwner {
        oracleAddress = _address;
    }
}
