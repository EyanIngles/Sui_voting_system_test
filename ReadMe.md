# Firstly!
This folder is going to be used for flashloans so with that we need to learn how pools are created, dealt with and swapped or flashloan with.

## Step 1:
create a pool and a few functions to utilise the pools and fetching the data. 
the below will be dot points on what i have learnt.

**OrderInfo** is created one a order is being placed, This order will check to see if there is any existing orders that match to do the swap desired and goes under the **Fill** process.

The **State** stores **Governance**, **History** and **Account**. It processes all requests, updating at least one of these stored structs.




# Smart voting system , asking permission by the holders to avoid scamming.
## Thoughts
What if we were to create a smart contract for our protocol and for us to fund or withdraw money from a treasury or liquidity pool, we need to ask the community for permission and then they are the ones to decide yes, no or how much...

**things to allow** should only have one proposal at a time, this means that the current proposal should be finalised and accepted, rejected or changed in terms of amount.
