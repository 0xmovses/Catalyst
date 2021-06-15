<h1>Contracts are currently being re-done to match the new architecture</h1>
<p>Previous repo can be found <a href="https://github.com/properly-finance">here</a> </p>
<h2>User Story Draft Below</h2>

<p class="p1">Step 1. A proposal is being made to create synthetic index token. Input token name, symbol and oracle contract.</p>
<p class="p1">Step 2. A proposal is being voted on and if passed execution send over to the &ldquo;timelock&rdquo;.</p>
<p class="p1">Step 3. When the timelock execution happens, a new ERC20 token is being created and stored in pair with the oracle contract to the &ldquo;Index Token Storage&rdquo; contract.</p>
<p class="p1">Step 4. The user deposits collateral though the protocol interface. The &ldquo;collateral logic contract&rdquo; takes note of the user deposit amount and stores the values. In the meantime the collateral that is being deposited is rerouted to Aave to earn interest.</p>
<p class="p1">Step 5. When user tries to mint the synthetic index tokens though the &ldquo;index token controller&rdquo; smart contract it first checks the user collateral-health. If user is minting within the collateral limits, the user receives the index token. The accounting for who and what was minted is tracked in the mint accounting storage contract.</p>
<p class="p1">Step 6. User goes to the exchange and provides liquidity and in return receives LP token.</p>
<p class="p1">Step 7. User goes to the pool deposits LP tokens to earn rewards for participating in the LP pools.</p>
<p class="p1">Step 8 if user collateral health is not in check other users can do a liquidation call by returning the minted asset on behalf of the user and using liquidate function</p>
<p class="p1">Step 9. When the user returns the minted index token, he will be able to withdraw the deposited collateral.</p>
