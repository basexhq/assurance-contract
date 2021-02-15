pragma solidity >=0.6.0;
import "../node_modules/@openzeppelin/contracts/math/SafeMath.sol";
import "../node_modules/@openzeppelin/contracts/access/Ownable.sol";
import "../node_modules/@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "../node_modules/@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "../node_modules/@openzeppelin/contracts/presets/ERC20PresetMinterPauser.sol";
import "../node_modules/@chainlink/contracts/src/v0.6/interfaces/AggregatorInterface.sol";

contract Assurance is Ownable {
    using SafeMath for uint256;

    AggregatorInterface public oracle;
    address payable public multisig; // MULTISIG. Ensure that there is enough m-of-n signatories and you are one of them to be extra sure (don't trust, verify)
    ERC20PresetMinterPauser public islandToken; // On Etherscan read contract and verify that `getRoleMemberCount` for MINTER_ROLE is exactly 1 (only this contract can mint)
    ERC20PresetMinterPauser public stakedToken; // Staked version so that it is easier to find in your wallet ERC20 balances
    uint public ONE_MILLION_DOLLARS_IN_CENTS = 100000000; // We use cents value. Related to how Chainlink oracle return ETH / USD data
    uint public TIMELOCK_DELAY; // Ideally hardcoded but in order to test passing as a constructor parameter

    event Deposit(address user, uint amount);
    event Withdrawal(address user, uint amount);
    event Stake(address user, uint amount);
    event Unstake(address user, uint amount);

    constructor(address oracleAddress, address islandTokenAddress, address stakedTokenAddress, address payable multisigAddress, uint timelockDelay) public {
        multisig = multisigAddress;
        islandToken = ERC20PresetMinterPauser(islandTokenAddress);
        stakedToken = ERC20PresetMinterPauser(stakedTokenAddress);
        oracle = AggregatorInterface(oracleAddress);
        TIMELOCK_DELAY = timelockDelay;
        transferOwnership(multisig); // in that way `onlyOwner` function will be called only by the multisig 
    }

    //////////////////////////////// DEPOSITS AND WITHDRAWALS
    receive() external payable { // Fallback function, sending directly to the contract
        deposit();
    }

    function deposit() public payable { // Depositing ETH, minting "Island ETH" token in 1:1 proportion
        islandToken.mint(msg.sender, msg.value);
        emit Deposit(msg.sender, msg.value);
    }

    function withdraw(uint amount) public { // Withdrawing is the exact opposite. Burning "Island ETH" and withdrawing ETH
        islandToken.burnFrom(msg.sender, amount);
        msg.sender.transfer(amount);
        emit Withdrawal(msg.sender, amount);
    }

    function stake(uint amount) public {
        islandToken.transferFrom(msg.sender, address(this), amount);
        stakedToken.mint(msg.sender, amount);
        emit Stake(msg.sender, amount);
    }

    function unstake(uint amount) public {
        stakedToken.burnFrom(msg.sender, amount);
        islandToken.transfer(msg.sender, amount);
        emit Unstake(msg.sender, amount);
    }

    //////////////////////////////// CHECKING HOW MUCH MONEY WE HAVE
    function getUSDValueOfWEI(uint WEI) public view returns (uint) {
        uint price = (uint)(oracle.latestAnswer());
        return WEI.mul(price).div(1000000000000000000000000); // Getting the right decimals, this is how ChainLink represents thedata
    }

    function currentValue() public view returns(uint) {
        return getUSDValueOfWEI(address(this).balance);
    }

    //////////////////////////////// INITIATING WITHDRAWALS
    uint public initiatedTime;
    bool public withdrawalInitiated;
    
    function initiateWithdrawal() public onlyOwner { // We do not want random dudes to initiate withdrawals when a proper island is not found yet
        require(currentValue() > ONE_MILLION_DOLLARS_IN_CENTS, "Funds must be over million dollars");
        require(withdrawalInitiated == false, "Withdrawal already initiated");
        initiatedTime = block.timestamp;
        withdrawalInitiated = true;
    }

    function finalizeWithdrawal() public onlyOwner {
        require(withdrawalInitiated == true, "Witdrawal must be initiated first"); 
        require(block.timestamp > initiatedTime + TIMELOCK_DELAY, "Need to wait 30 days"); // This is to give time for anyone to witdraw funds safely in case 
        if (currentValue() > ONE_MILLION_DOLLARS_IN_CENTS) {
            multisig.transfer(address(this).balance); // REMEMBER: if there are any ERC20 or NFT721 it might be worth rescuing them
        } else { // OUCH. It decreased. Maybe ETH price went down. Maybe some people bye bye. Back to the drawing board.
            withdrawalInitiated = false;
        }
    }
    
    //////////////////////////////// ACCEPTING ERC20 and NFT721. PROCESSING THEM MANUALLY
    function rescueERC20(address tokenAddress) public {
        IERC20 tokenContract = ERC20(tokenAddress);
        tokenContract.transfer(multisig, tokenContract.balanceOf(address(this)));
    }

    function rescueNFT721(address tokenAddress, uint tokenId) public {
        IERC721 tokenContract = IERC721(tokenAddress);
        tokenContract.transferFrom(address(this), multisig, tokenId);
    }

}