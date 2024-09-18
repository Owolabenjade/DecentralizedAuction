# Auction Smart Contract

## Overview

This project implements a robust and flexible auction system as a smart contract using Clarity, the smart contract language for the Stacks blockchain. The contract allows for the creation and management of English auctions, where participants can place bids on an item, and the highest bidder at the end of the auction wins.

## Features

- **Auction Initialization**: Set up an auction with a specified duration, item name, and reserve price.
- **Bidding System**: Allow participants to place bids that must exceed the current highest bid by a set increment.
- **Reserve Price**: Ensure that the final sale price meets or exceeds a predefined minimum value.
- **Automatic Refunds**: Automatically refund outbid participants.
- **Auction Conclusion**: Securely transfer funds to the auction owner upon successful conclusion.
- **Auction Cancellation**: Allow the owner to cancel the auction if no bids have been placed.
- **Status Queries**: Provide functions to check the current status and details of the auction.

## Contract Functions

### Public Functions

1. `initialize-auction (duration uint) (name (string-ascii 50)) (min-price uint)`
   - Starts a new auction with the given duration (in blocks), item name, and reserve price.
   - Can only be called by the contract owner.

2. `submit-bid (offer uint)`
   - Allows a user to place a bid on the auction.
   - The bid must be higher than the current highest bid plus the bid increment, or the reserve price if no bids have been placed.

3. `conclude-auction`
   - Ends the auction and transfers the winning bid to the owner.
   - Can only be called after the auction end time has passed.

4. `cancel-auction`
   - Allows the owner to cancel the auction if no bids have been placed.

### Read-Only Functions

1. `query-top-bid`
   - Returns the current highest bid.

2. `query-top-bidder`
   - Returns the address of the current highest bidder.

3. `query-auction-end`
   - Returns the block height at which the auction will end.

4. `query-item-name`
   - Returns the name of the item being auctioned.

5. `query-reserve-price`
   - Returns the reserve price of the auction.

6. `query-auction-status`
   - Returns the current status of the auction: "Not started", "In progress", or "Ended".

## Error Codes

The contract uses the following error codes:

- `ERR-NOT-AUTHORIZED (u100)`: The caller is not authorized to perform this action.
- `ERR-AUCTION-ALREADY-STARTED (u101)`: Attempt to start an auction that has already begun.
- `ERR-AUCTION-NOT-STARTED (u102)`: Attempt to interact with an auction that hasn't started.
- `ERR-AUCTION-ENDED (u103)`: Attempt to bid on an auction that has ended.
- `ERR-BID-TOO-LOW (u104)`: The bid is lower than the minimum required bid.
- `ERR-TRANSFER-FAILED (u105)`: STX transfer failed.
- `ERR-AUCTION-NOT-ENDED (u106)`: Attempt to conclude an auction that hasn't ended.
- `ERR-NO-BIDS (u107)`: No bids have been placed on the auction.

## Usage

To use this smart contract:

1. Deploy the contract to the Stacks blockchain.
2. Call `initialize-auction` to start a new auction, specifying the duration, item name, and reserve price.
3. Participants can call `submit-bid` to place bids.
4. Once the auction end time has passed, anyone can call `conclude-auction` to end the auction and transfer funds to the owner.
5. Use the read-only functions at any time to query the current state of the auction.

## Security Considerations

- The contract includes checks to prevent unauthorized access to owner-only functions.
- Bid refunds are processed automatically to ensure fairness.
- The contract prevents bids after the auction has ended.
- A reserve price mechanism is implemented to protect the seller's interests.

## Future Improvements

Potential enhancements for future versions:
- Implement a dutch auction variant.
- Add support for NFT auctions.
- Implement a time extension mechanism for last-minute bids.
- Add events for important state changes to facilitate off-chain tracking.

## Contributing

We welcome contributions to improve this smart contract. Please submit issues and pull requests on our GitHub repository.

## Disclaimer

This smart contract is provided as-is. Users should thoroughly review and test the contract before using it in any production environment. The authors are not responsible for any losses incurred through the use of this contract.