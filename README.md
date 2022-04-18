# Decentralized-Lottery
A decentralized lottery using Chainlink VRF.

## Security Considerations
- `setWinner()` has a private visibility such as that the only caller that can set the winner is the `fulfillRandomWords()`.
- `withdrawal()` is a pull pattern which eliminates the chance of re-entrancy.
- This contract uses the ChainLink VRF as source of randomness because blockchain's deterministic property makes it impossible to use block properties as source of randomness.


## Gas Optimizations
- The contract was compiled with the runs parameter set at 200 as to make it cheaper to call the contract's function.
- The state variables are strategically placed such that the first group occupies one slot with 241 bits. The second group each variable occupies a slot on its own.
- `enterLottery()` and  `withdrawal()` have their visibility set to external making them cheaper to call then if they were public function. Plus, they were set as is because they will only ever be called outside the contract.</li>
- `enterLottery()` only allows to enter the lottery with the correct amount, thus it eliminates unnecessary code to tranfer the excess back to the caller.
- The second require in `withdrawal()` uses short-circuiting since it is most likely to be called by the winner.
