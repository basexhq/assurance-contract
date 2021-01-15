# Island DAO



### Tokenomics

1,000,000,000 Total Supply




17% suppliers, contractors, services (during the fundraise)

17% during the build

40% community crowdfunding

5% ecosystem development fund

5% airdrop

1% Ross Ulbrich legal fund

5% reserve, contingencies, rainy day



### Development
Running tests

`truffle test`

```
    ✓ Can deposit ETH and mint tokens (63ms)
    ✓ Can withdraw ETH by burning tokens (139ms)
    ✓ Can calculate money invested in ETH (114ms)
    ✓ Calculate price in WEI correctly (50ms)
    ✓ Does not allow to initiate withdrawal initially
    ✓ Allows to initiate withdrawal after $1m in deposits (168ms)
    ✓ Allows to to finalize after 30 days (201ms)
    ✓ Can rescue ERC20 (209ms)
    ✓ Can rescue NFT721 (234ms)
```


### Verifying on Etherscan

`truffle run verify IslandToken StakedToken Assurance --network rinkeby`