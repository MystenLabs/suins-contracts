#### All possible scenarios of an auction for a domain name:

- No bids are submitted: The auction ends without a winner and the domain name remains unsold. This auction can be started again.
- There are bids that were submitted, but none of them is valid: The auction ends without a winner and the item remains unsold. This auction can be started again.
- Only one valid bid is submitted: The bidder who submitted the bid wins the auction and pays his/her actual bid amount.
- Multiple valid bids are submitted, and only one bidder has his/her bid amount equal to the highest value: The bidder who submitted the highest valid bid wins the auction and 
  pays the second-highest bid amount.
- Multiple valid bids are submitted, but some of them have their bid amount equal to the highest value: The bidder who submitted the first valid bid wins the auction 
  and pays the second-highest bid amount.
- Multiple valid bids are submitted, but some of them have their bid amount equal to the highest value and their bids made in the same epoch: The bidder who revealed the first valid bid wins the auction and pays the second-highest bid amount.

#### State diagram of an auction for a domain name
##### The following diagram shows the behaviour of an auction when being auctioned

```mermaid
stateDiagram-v2
  [*] --> Unavailable
  Unavailable --> Open : if current date is between start and end date
  Open --> Unavailable : if current date is after end date
  Open --> Pending : if start_auction() is triggered
  Pending --> Bidding : next date
  note left of Bidding  
	  during this state, any call to `new_bid` 
	  with a proper sealed bid  is valid
  end note
  Bidding --> Reveal : 3 days later
  Reveal --> Finalizing : 3 days later and there is any unseal_bid() that matches a valid new_bid() is called
  Reveal --> Reopened : 3 days later and there is no valid unseal_bid() is called
  Reopened --> Pending : if start_auction() is triggered
  Reopened --> Unavailable : if current date is after end date
  Finalizing --> Owned : if finalize_auction() is called within current date and 30 days after end date by the winner
  note right of Owned  
	  a NFT is sent to the winner
  end note
```

#### Sequence diagram for interaction of the whole system
##### This diagram shows all the interaction between `Bidder`, `Smart contract` and `Admin`
Note: The admin needs to set `open` and `close` dates at the very start of the contract deployment.
If these values are not set, the attackers can register these domains via Controller.

```mermaid
sequenceDiagram
    participant Bidder
    participant Smart
    participant Admin
	Admin->>Smart: Set open and close dates

opt current date is between start and end dates
	opt auction for the name hasn't been started and bidder wants to start it
		Bidder->>+Smart: call start_an_auction()
		Smart->>-Smart: State of this auction changes from Open to Pending
    Note right of Smart: State automatically changes to Bidding 1 day later, then changes to Reveal 3 days after that
    end
    
    Bidder->>+Smart: call place_bid()
	opt Bid mask is greater than or equals to the minimum allowed value
	    Smart->>-Smart: Create a new bid detail record
	end

    Bidder->>Smart: call reveal_bid()
	opt auction's state is Reveal and the parameters match a sealed_bid
		alt the sealed bid and bid detail are valid
		Note right of Smart: Sealed bid is valid if place_bid() was called in Bidding state
		Smart->>Smart: Update metadata of this auction if this bid's value is high enough to affect the auction result, also update metadata of the bid detail
		else sealed bid or bid detail is invalid
		Smart->>Smart: Update metadata of this bid detail
		end
	end
    
	Note right of Smart: This is called when current date is between start and end dates
    Bidder->>Smart: call finalize_auction()
	opt auction's state is Finalizing, Reopened or Open and the parameters match a sealed_bid
		Smart->>Smart: Remove all of his/her bids on this auction
		alt the bidder is the winner
		Smart->>Smart: Update metadata of this auction
	    Note right of Smart: Auction's state changes to Owned
	    
		Smart->>Bidder: Transfer a NFT representing ownership of this name
		Smart->>Bidder: Refund the extra payment of the winning bid
		Note right of Smart: A bidder can place multiple bids on the same auction
		Smart->>Bidder: Refund payments of his/her other bids on this auction
		
		else the bidder isn't the winner
		Smart->>Bidder: Refund payments of his/her bids on this auction
		end
	end 
end

opt current date is between end date and end date + extra time period
Bidder->>Smart: call finalize_auction()
	opt bidder is the winner
		Smart->>Smart: Remove all of his/her bids on this auction
		Smart->>Smart: Update metadata of this auction
		Note right of Smart: Auction's state changes to Owned
		Smart->>Bidder: Transfer a NFT representing ownership of this name
		Smart->>Bidder: Refund the extra payment of the winning bid
		Note right of Smart: A bidder can place multiple bids on the same auction
		Smart->>Bidder: Refund payments of his/her other bids on this auction
	end
end

opt current date is after (end date + extra time period)
Bidder->>Smart: call withdraw()
	Smart->>Smart: Remove all of his/her bids on this auction
	Smart->>Bidder: Refund payments of his/her bids on this auction
end

```
