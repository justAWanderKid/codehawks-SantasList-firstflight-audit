
Santa's List is the main contract that stores the list of naughty and nice people.
It doubles as an NFT contract that people can collect if they are `NICE` or `EXTRA_NICE`.
In order for someone to be considered `NICE` or `EXTRA_NICE` they *must* be first "checked twice" by Santa.

Once they are checked twice, `NICE` users can collect their NFT, and `EXTRA_NICE` users can collect their NFT **and** they are given `SantaToken`s.
The `SantaToken` is an ERC20 that can be used to buy the NFT for their `NAUGHTY` or `UNKNOWN` friends.

#### List Checking

In this contract **Only Santa** to take the following actions:

* `checkList`: A function that changes an `address` to a new `Status` of `NICE`, `EXTRA_NICE`, `NAUGHTY`, or `UNKNOWN` on the *original* `s_theListCheckedOnce` list.
* `checkTwice`: A function that changes an `address` to a new `Status` of `NICE`, `EXTRA_NICE`, `NAUGHTY`, or `UNKNOWN` on the *new* `s_theListCheckedTwice` list **only** if someone has already been marked on the `s_theListCheckedOnce`.


------------------------------------------------------------------------------------------------------------------------------------------------------------------
### Attack Vectors

- Can Someone that is not `NICE` collect an NFT?
- Can Someone That is Considered as `NICE` collect NFT Plus `SantaToken`s?
- Can We Buy NFT Without `SantaToken`s?
  
- Can Non-Santa User Call `checkList` function to Get `NICE`, `EXTRA_NICE`, `NAUGHTY`, or `UNKNOWN` Status?
- Can Non-Santa User Call `checkTwice` function to Get `NICE`, `EXTRA_NICE`, `NAUGHTY`, or `UNKNOWN` Status?



#################################################################################################################################################################
The following functions are meant to be called by people, but only those marked `NICE` or `EXTRA_NICE` can benefit from them.

* `collectNFT`: A function that allows a `NICE` or `EXTRA_NICE` user to collect their NFT. `EXTRA_NICE` users also receive `SantaToken` which is used to purchase an additional NFTs. An address is only allowed to collect 1 NFT per address, there is a check in the codebase to prevent someone from minting duplicate NFTs.
* `buyPresent`: A function that trades `2e18` of `SantaToken` for an NFT. This function can be called by anyone.


------------------------------------------------------------------------------------------------------------------------------------------------------------------
### Attack Vectors

- can Someone That is Not `NICE` or `EXTRA_NICE` benefit from `collectNFT` or `buyPresent` function?
- can someone that is `NICE`, do something that also receives `SantaToken`s?
- can someone that has less than `2e18 SantaToken` trade it for an NFT?
- can someone that has no `SantaToken` trade it for an NFT?
  
------------------------------------------------------------------------------------------------------------------------------------------------------------------