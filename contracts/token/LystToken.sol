// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./ERC20/ERC20.sol";
import "./ERC20/extensions/ERC20Burnable.sol";
import "./ERC20/extensions/ERC20Snapshot.sol";
import "../access/AccessControlEnumerable.sol";
import "../utils/Context.sol";
import "../utils/math/SafeMath.sol";

// learn more: https://docs.openzeppelin.com/contracts/3.x/erc20

/**
 * @dev {ERC20} token, including:
 *
 *  - ability for holders to burn (destroy) their tokens
 *  - a minter role that allows for token minting (creation)
 *  - a pauser role that allows to stop all token transfers
 *
 * This contract uses {AccessControl} to lock permissioned functions using the
 * different roles - head to its documentation for details.
 *
 * The account that deploys the contract will be granted the minter and pauser
 * roles, as well as the default admin role, which will let it grant both minter
 * and pauser roles to other accounts.
 */
contract LystToken is
    Context,
    AccessControlEnumerable,
    ERC20Snapshot,
    ERC20Burnable
{
    using SafeMath for uint256;
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
    bytes32 public constant SNAPSHOTTER_ROLE = keccak256("SNAPSHOTER_ROLE");

    // A record of each accounts delegate
    mapping(address => address) public delegates;
    /* 
    
    Checkpointing is a system by which you can check the token balance of any user at any particular point in history. 
    This is important because when a vote comes up that users need to vote on, 
    you don't want individuals buying or selling tokens specifically to change the outcome of the vote and then dumping straight after a vote closes. 
    To avoid this, checkpoints are used.
    By the time someone creates a proposal and puts it up for a vote in the Compound ecosystem,
    the voting power of all token holders is already known, and fixed, at a point in the past.
    This way users can still buy or sell tokens, but their balances won't affect their voting power.
    
    The block at which voting begins: holders must delegate their votes prior to this block
        uint startBlock;

    
    */
    // A checkpoint for marking number of votes from a given block
    struct Checkpoint {
        uint256 fromBlock;
        uint256 votes;
    }

    // A record of votes checkpoints for each account, by index
    mapping(address => mapping(uint256 => Checkpoint)) public checkpoints;

    // The number of checkpoints for each account
    // CHECKPOINTS ARE ADDED WHEN TOKEN TRANSFERS OR DELIGATIONS ARE DONE!
    mapping(address => uint256) public numCheckpoints;

    // An event thats emitted when an account changes its delegate
    event DelegateChanged(
        address indexed delegator,
        address indexed fromDelegate,
        address indexed toDelegate
    );

    // An event thats emitted when a delegate account's vote balance changes
    event DelegateVotesChanged(
        address indexed delegate,
        uint256 previousBalance,
        uint256 newBalance
    );

    /**
     * @dev Grants `DEFAULT_ADMIN_ROLE`, `MINTER_ROLE` and `PAUSER_ROLE` to the
     * account that deploys the contract.
     *
     * See {ERC20-constructor}.
     */

    constructor(
        string memory name,
        string memory symbol,
        address farm,
        address timelock
    ) ERC20(name, symbol) {
        _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
        _setupRole(MINTER_ROLE, _msgSender());
        _setupRole(SNAPSHOTTER_ROLE, _msgSender());

        _setupRole(MINTER_ROLE, farm);

        _setupRole(DEFAULT_ADMIN_ROLE, timelock);
        _setupRole(MINTER_ROLE, timelock);
        _setupRole(SNAPSHOTTER_ROLE, timelock);
    }

    /**
     * @dev Creates `amount` new tokens for `to`.
     *
     * See {ERC20-_mint}.
     *
     * Requirements:
     *
     * - the caller must have the `MINTER_ROLE`.
     */
    function mint(address to, uint256 amount) public virtual {
        require(
            hasRole(MINTER_ROLE, _msgSender()),
            "Must have minter role to mint"
        );
        _mint(to, amount);
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual override(ERC20, ERC20Snapshot) {
        super._beforeTokenTransfer(from, to, amount);
        _moveDelegates(from, to, amount);
    }

    function snapshot() public returns (uint256) {
        require(
            hasRole(SNAPSHOTTER_ROLE, _msgSender()),
            "Must have snapshoter role to mint"
        );
        return _snapshot();
    }

    // GOVERNANCE PART

    /**
     * notice Delegate votes from `msg.sender` to `delegatee`
     * param delegatee The address to delegate votes to
     */
    function delegate(address delegatee) public {
        return _delegate(msg.sender, delegatee);
    }

    /**
     * @notice Gets the current votes balance for `account`
     * @param account The address to get votes balance
     * @return The number of current votes for `account`
     */
    function getCurrentVotes(address account) external view returns (uint256) {
        // nCheckpoints IS JUST THE REPRESENTATION OF NUMBER OF CHECKPOINTS FROM ACCOUNT.
        uint256 nCheckpoints = numCheckpoints[account];

        return
            nCheckpoints > 0 ? checkpoints[account][nCheckpoints - 1].votes : 0;
    }

    //  This function is made to delegate the votes to some other address
    function _delegate(address delegator, address delegatee) internal {
        // Delegator is the one who is delegaring and delegatee is the one who is getting the votes.

        // Defines currentDelegate for address who currently the votes are delegated to.
        // it can be your own address.
        address currentDelegate = delegates[delegator];
        if (currentDelegate == address(0)) {
            currentDelegate = msg.sender;
        }
        // Checks how many votes does the delegator have currently available?
        // The amount of the votes depends on the balance of the tokens you have.
        uint256 delegatorBalance = balanceOf(delegator);
        // Set the new address the delegate who will making the votes.
        delegates[delegator] = delegatee;

        emit DelegateChanged(delegator, currentDelegate, delegatee);

        // The balance balance of the one who is delegating are moved to the balance of the delegatee.
        _moveDelegates(currentDelegate, delegatee, delegatorBalance);
    }

    function _writeCheckpoint(
        address delegatee,
        uint256 nCheckpoints,
        uint256 oldVotes,
        uint256 newVotes
    ) internal {
        if (
            nCheckpoints > 0 &&
            checkpoints[delegatee][nCheckpoints - 1].fromBlock == block.number
        ) {
            checkpoints[delegatee][nCheckpoints - 1].votes = newVotes;
        } else {
            //   WE ARE SETTING THE CHECKPOINT WHERE WE SPECIFY THE BLOCK number
            //   THE GOAL IS TO NOT LET PEOPLE VOTE WHEN THEIR BLOCK NUMBER IS AFTER WHEN THE VOTE BLIOCK STARTED.
            checkpoints[delegatee][nCheckpoints] = Checkpoint(
                block.number,
                newVotes
            );
            numCheckpoints[delegatee] = nCheckpoints + 1;
        }

        emit DelegateVotesChanged(delegatee, oldVotes, newVotes);
    }

    function _moveDelegates(
        address from,
        address to,
        uint256 amount
    ) public {
        // If the deligates are NOT set to yourself
        if (from != to && amount > 0) {
            // BELOW WE DEFINE THE MINTING AND BURNING PROCESS

            // address(0) is defined as address where the token is sent to nowhere, so burned.
            // If the source is not 0x0 address
            //  SO i assume this is when the minting process happens.
            // IF THE DELEGATES ARE NOT COMING FROM 0X0
            // THUS SOURCE IS AN ACTUAL ADDRESS
            // MEANING THIS IS NOT HAPPENING FROM THE MINTING PROCCESS
            // BECAUSE THIS TRANSACTION WOULD FAIL IF IT WAS.
            if (from != address(0)) {
                // SOURCE REPUTATION NUMBER = HOW MANY CHECKPOINTS THIS SOURCE HAS.
                // CHECKPOINTS ARE ADDED ON

                // GET NUMBER OF CHECKPOINTS FROM SENDER ADDRESS ALSO KNOW AS SOURCE
                uint256 fromNum = numCheckpoints[from];
                // IF THE NUMBER IS BIGGER THAN 0 GET THE AMOUNT OF VOTES, OTHERWISE MARK OLD SOURCE REP POINTS AS 0
                uint256 fromOld =
                    fromNum > 0 ? checkpoints[from][fromNum - 1].votes : 0;
                //  REDUCE THE NUMBER OF VOTES BY THE NUMBER IT WAS MOVED.
                uint256 fromNew = fromOld.sub(amount);

                // After it has reduced the voting, it writes it as a checkpoints.
                // 1. ADDRESS WHERE THE VOTES ARE COMING FROM
                // 2. NUMBER OF CHECKPOINTS FROM SENDER ADDRESS ALSO KNOW AS SOURCE
                // 3. A record of votes that are stored under checkpoints struct for source account, by index
                // 4. The number of votes.

                _writeCheckpoint(from, fromNum, fromOld, fromNew);
            }
            // If the tokens are not sent to a burn address,
            // Write token checkpoint
            if (to != address(0)) {
                uint256 toNum = numCheckpoints[to];
                uint256 toOld =
                    toNum > 0 ? checkpoints[to][toNum - 1].votes : 0;
                uint256 toNew = toOld.add(amount);
                _writeCheckpoint(to, toNum, toOld, toNew);
            }
        }
    }

    function getPriorVotes(address account, uint256 blockNumber)
        public
        view
        returns (uint256)
    {
        require(
            blockNumber < block.number,
            "Comp::getPriorVotes: not yet determined"
        );

        uint256 nCheckpoints = numCheckpoints[account];
        if (nCheckpoints == 0) {
            return 0;
        }

        // First check most recent balance
        if (checkpoints[account][nCheckpoints - 1].fromBlock <= blockNumber) {
            return checkpoints[account][nCheckpoints - 1].votes;
        }

        // Next check implicit zero balance
        if (checkpoints[account][0].fromBlock > blockNumber) {
            return 0;
        }

        uint256 lower = 0;
        uint256 upper = nCheckpoints - 1;
        while (upper > lower) {
            uint256 center = upper - (upper - lower) / 2; // ceil, avoiding overflow
            Checkpoint memory cp = checkpoints[account][center];
            if (cp.fromBlock == blockNumber) {
                return cp.votes;
            } else if (cp.fromBlock < blockNumber) {
                lower = center;
            } else {
                upper = center - 1;
            }
        }
        return checkpoints[account][lower].votes;
    }
}
