# Crowd-Funding Smart Contract

1. Any user can come and create a fund by providing two parameters, the funding goal and the duration of funding.
2. Any user can come and deposit funds into any funding that is currently running.
3. After a funding has ended, if the amount of funds collected is less than the funding goal, each user who deposited into the fund gets a refund which they can claim. If the amount of funds collected is equal to or greater that the funding goal, the creator of the fund can withdraw it from the contract.

## To try out:

1. Clone this repository.
2. Run `npm install` inside the directory of the project.
3. Run `truffle develop`. A truffle develop CLI will open in the terminal. You will get 10 addresses pre-filled with 100 ETH each. Copy the address of the first account. This is going to be your account for the testing.
4. Deploy contracts using `deploy`.
5. Create instance of the token using the following command in the truffle develop CLI.

```node
let token = {};
token = FundingToken.deployed().then((_token) => (token = _token));
```

6. Create instance of the crowd funding contract using the following command in the truffle develop CLI.

```node
let crowdFunding = {};
crowdFunding = CrowdFundingUpgradeable.deployed().then(
  (_crowdFunding) => (crowdFunding = _crowdFunding)
);
```

7. Mint yourself some token using the following command:

```node
token.mint("your address", "amount of tokens you want");
```

8. Approve the crowd funding contract to deduct your tokens so that you are able to deposit.

```node
token.approve(crowdFunding.address, "10000000000000000000000000");
```

9. Create a fund on the crowd funding contract using

```node
crowdFunding.createFund("fundingGoal", "duration of fund in seconds");
```

10. Deposit funds into the fund using the following command:

```node
crowdFunding.depositIntoFund("fund ID");
```

11. The fund ID will be 1 for first fund created, 2 for second and so on. 11. Wait for the fund to end. 12. If the amount you deposited is greater than or equal to the funding goal, the eligibility to get refund will be false and that of withdrawal of funds will be true. In the other case, this order will reverse. Verify using:

```node
// Should return true if funding is unsuccessful and false if funding is successful
crowdFunding.isEligibleForRefund("your address", "fund ID");

// Should return false if funding is unsuccessful and true if funding is successful
crowdFunding.isEligibleForWithdrawal("Fund ID");
```

12. If the case is of getting refund, try ti get your refund. Otherwise, try to withdraw the funds from the fund if the funding is successful using:

```node
// In the case of refund
crowdFunding.claimRefund("fund ID");

// In the case of successful completion of funding
crowdFunding.withdrawFunds("fund ID");
```

Hope you like the project!!
