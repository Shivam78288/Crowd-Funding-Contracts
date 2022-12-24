// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.10;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

/// @title Funding Token contract
/// @author Shivam Agrawal
contract FundingToken is ERC20 {
    constructor (string memory _name, string memory _symbol) ERC20(_name, _symbol) {}

    /// @notice Function to mint the ERC20 tokens for users (Just for testing purposes).
    /// @param recipient address of recipient of the tokens.
    /// @param amount amount of tokens to be minted to the recipient.
    function mint(address recipient, uint256 amount) external {
        _mint(recipient, amount);
    } 
}