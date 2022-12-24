// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.10;

import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";

/// @title Crowd Funding Upgradeable Smart Contract
/// @author Shivam Agrawal
/// @notice This contract allows anyone to create crowdfunds where user can make deposits. 
/// Each fund will have an end time and a funding goal. If the fund has ended and the funding goal
/// is not met, users can get refunds for their deposits. If the fund has ended and the funding goal
/// is also met, the creator of the fund is eligible to withdraw the funds from the fund.
contract CrowdFundingUpgradeable is Initializable, AccessControlUpgradeable, UUPSUpgradeable {
    using SafeERC20Upgradeable for IERC20Upgradeable;

    struct Funding {
        bool isClaimed; // Are funds claimed by the creator
        address creator; // Address of the creator
        uint256 fundEndTime; // Time for the end of the fund
        uint256 fundingGoal; // Total funding goal
        uint256 fundCollected; // Total funds collected
    }

    // Current fund ID
    uint256 public currentFundId;

    // Fund ID to Funding struct
    mapping (uint256 => Funding) public funding;

    // Address of user + Fund ID to user funds
    mapping (address => mapping(uint256 => uint256)) public userDeposits;

    // token in which funding is accepted
    IERC20Upgradeable public fundingToken;

    // max time for any fund to exist
    uint256 public constant MAX_FUND_TIME = 100 days;

    event FundCreated (address indexed creator, uint256 indexed fundId, uint256 fundingGoal);
    event UserDeposit (address indexed user, uint256 indexed fundId, uint256 amount);
    event RefundProcessed (address indexed user, uint256 indexed fundId, uint256 amount);
    event FundsWithdrawn (address indexed creator, uint256 indexed fundId, uint256 amount);

    // modifier to check whether the fund exists
    modifier fundExists (uint256 fundId) {
        require(funding[fundId].creator != address(0), "fund does not exist");
        _;
    }


    /// @notice Function to initialize the crowd-funding contract
    /// @param _fundingToken a parameter just like in doxygen (must be followed by parameter name)
    function initialize(address _fundingToken) external initializer {
        require(_fundingToken != address(0), "funding token cannot be address(0)");

        fundingToken = IERC20Upgradeable(_fundingToken);
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
    }

    function _authorizeUpgrade(address newImplementation) internal override onlyRole(DEFAULT_ADMIN_ROLE) {}

    /// @notice Function to create a new fund.
    /// @param fundingGoal amount of tokens as goal of the fund.
    /// @param fundDurationInSeconds duration of fund in seconds. 
    /// @notice If this duration is over and fund didn't achieve its funding goal, 
    /// depositors will be able to get refunds for their deposits into the fund.
    function createFund (uint256 fundingGoal, uint256 fundDurationInSeconds) external {
        require(
            fundingGoal != 0 && fundDurationInSeconds != 0, 
            "Funding goal or duration cannot be zero"
        );

        if(fundDurationInSeconds > MAX_FUND_TIME) {
            fundDurationInSeconds = MAX_FUND_TIME;
        }

        currentFundId += 1;

        uint256 fundId = currentFundId;

        funding[fundId] = Funding(
            false,
            msg.sender,
            block.timestamp + fundDurationInSeconds,
            fundingGoal,
            0
        );

        emit FundCreated(msg.sender, fundId, fundingGoal);
    }

    /// @notice Function for the user to deposit tokens into a fund.
    /// @param fundId ID of the fund to deposit into.
    /// @param amount Amount of funds to be deposited.
    function depositIntoFund (uint256 fundId, uint256 amount) external fundExists(fundId) {
        require(funding[fundId].fundEndTime > block.timestamp, "fund already ended");

        fundingToken.safeTransferFrom(msg.sender, address(this), amount);
        funding[fundId].fundCollected += amount;
        userDeposits[msg.sender][fundId] += amount;

        emit UserDeposit(msg.sender, fundId, amount);
    }

    /// @notice Function to claim refund for a deposit.
    /// @notice Can only claim refund if the fund has ended & haven't fulfilled its funding goal.
    /// @notice Can only be claimed by the users who deposited into the fund.
    /// @param fundId ID of the fund to deposit into.
    function claimRefund (uint256 fundId) external {
        require(isEligibleForRefund(msg.sender, fundId), "ineligible for refund");
        uint256 userDeposit = userDeposits[msg.sender][fundId];
        userDeposits[msg.sender][fundId] = 0;

        fundingToken.safeTransfer(msg.sender, userDeposit);
        emit RefundProcessed(msg.sender, fundId, userDeposit);
    }

    /// @notice Function to check if a user is eligible for a refund for a deposit.
    /// @param fundId ID of the fund to deposit into.
    /// @return true if eligible, false for ineligible.
    function isEligibleForRefund (address user, uint256 fundId) public view fundExists(fundId) returns (bool) {
        Funding memory _funding = funding[fundId];

        return 
        (
            _funding.fundEndTime < block.timestamp && 
            _funding.fundCollected < _funding.fundingGoal &&  
            userDeposits[user][fundId] != 0
        );
    }

    /// @notice Function to withdraw funds from a fund which has ended.
    /// @notice Can only be claimed by the creator of the fund.
    /// @notice Can only be withdrawn if the isClaimed flag of the fund is false.
    /// @notice Can only withdraw if the fund has ended & has fulfilled its funding goal.
    /// @param fundId ID of the fund to deposit into.
    function withdrawFunds (uint256 fundId) external fundExists(fundId) {
        Funding memory _funding = funding[fundId];

        require(isEligibleForWithdrawal(fundId), "wait for the fund to end");
        require(msg.sender == _funding.creator, "only fund creator can withdraw");

        funding[fundId].isClaimed = true;
        fundingToken.safeTransfer(msg.sender, _funding.fundCollected);

        emit FundsWithdrawn(msg.sender, fundId, _funding.fundCollected);
    }

    /// @notice Function to check if a fund is eligible to be withdrawn from.
    /// @param fundId ID of the fund.
    /// @return true if eligible, false for ineligible.
    function isEligibleForWithdrawal (uint256 fundId) public fundExists(fundId) view returns (bool) {
        Funding memory _funding = funding[fundId];
        require(!_funding.isClaimed, "funds already claimed");

        return (_funding.fundCollected >= _funding.fundingGoal) && 
               (_funding.fundEndTime < block.timestamp);
    }
}
