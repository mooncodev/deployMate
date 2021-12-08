// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

import "./Token/BEP20/BEP20.sol";
import "./uniswap/interfaces/IUniswapV2Router02.sol";
import "./uniswap/interfaces/IUniswapV2Factory.sol";
import "./LanaCakeDividendTracker.sol";

contract LanaCakeToken is BEP20 {
    uint256 public totalSupply = 10000 * 10**18;

    IUniswapV2Router02 public uniswapV2Router;
    address public immutable uniswapV2Pair;

    address public _dividendToken = 0xbb4CdB9CBd36B01bD1cBaEBF2De08d9173bc095c;
    address public immutable deadAddress =
    0x000000000000000000000000000000000000dEaD;

    bool private swapping;
    bool public tradingIsEnabled = false;
    bool public buyBackEnabled = false;
    bool public buyBackRandomEnabled = true;

    LanaCakeDividendTracker public dividendTracker;

    address public buyBackWallet = 0x10792451bedB657E4edE615C635080f3781F3952; // Need to change

    uint256 public maxBuyTranscationAmount = totalSupply;
    uint256 public maxSellTransactionAmount = totalSupply;
    uint256 public swapTokensAtAmount = totalSupply / 100000;
    uint256 public maxWalletToken = totalSupply;

    uint256 public dividendRewardsFee;
    uint256 public marketingFee;
    uint256 public immutable totalFees;

    // sells have fees of 12 and 6 (10 * 1.2 and 5 * 1.2)
    uint256 public sellFeeIncreaseFactor = 130;

    uint256 public marketingDivisor = 30;

    uint256 public _buyBackMultiplier = 100;

    // use by default 300,000 gas to process auto-claiming dividends
    uint256 public gasForProcessing = 300000;

    address public presaleAddress = address(0);

    // exlcude from fees and max transaction amount
    mapping(address => bool) private _isExcludedFromFees;
    mapping(address => bool) public _isExcludedMaxSellTFransactionAmount;

    // store addresses that a automatic market maker pairs. Any transfer *to* these addresses
    // could be subject to a maximum transfer amount
    mapping(address => bool) public automatedMarketMakerPairs;
    mapping(address => bool) _blacklist;

    event BlacklistUpdated(address indexed user, bool value);
    event UpdateDividendTracker(
        address indexed newAddress,
        address indexed oldAddress
    );

    event UpdateUniswapV2Router(
        address indexed newAddress,
        address indexed oldAddress
    );

    event BuyBackEnabledUpdated(bool enabled);
    event BuyBackRandomEnabledUpdated(bool enabled);
    event SwapAndLiquifyEnabledUpdated(bool enabled);

    event ExcludeFromFees(address indexed account, bool isExcluded);
    event ExcludeMultipleAccountsFromFees(address[] accounts, bool isExcluded);
    event ExcludedMaxSellTransactionAmount(
        address indexed account,
        bool isExcluded
    );

    event SetAutomatedMarketMakerPair(address indexed pair, bool indexed value);

    event BuyBackWalletUpdated(
        address indexed newLiquidityWallet,
        address indexed oldLiquidityWallet
    );

    event GasForProcessingUpdated(
        uint256 indexed newValue,
        uint256 indexed oldValue
    );

    event SwapAndLiquify(
        uint256 tokensSwapped,
        uint256 bnbReceived,
        uint256 tokensIntoLiqudity
    );

    event SendDividends(uint256 tokensSwapped, uint256 amount);

    event SwapBNBForTokens(uint256 amountIn, address[] path);

    event ProcessedDividendTracker(
        uint256 iterations,
        uint256 claims,
        uint256 lastProcessedIndex,
        bool indexed automatic,
        uint256 gas,
        address indexed processor
    );

    constructor() BEP20("LanaCake", "LANA") {
        IUniswapV2Router02 _uniswapV2Router = IUniswapV2Router02(
            0x10ED43C718714eb63d5aA57B78B54704E256024E
        ); //0x9Ac64Cc6e4415144C455BD8E4837Fea55603e5c3
        // Create a uniswap pair for this new token
        address _uniswapV2Pair = IUniswapV2Factory(_uniswapV2Router.factory())
        .createPair(address(this), _uniswapV2Router.WBNB());

        uniswapV2Router = _uniswapV2Router;
        uniswapV2Pair = _uniswapV2Pair;

        _setAutomatedMarketMakerPair(_uniswapV2Pair, true);

        // exclude from paying fees or having max transaction amount
        excludeFromFees(buyBackWallet, true);
        excludeFromFees(address(this), true);

        /*
        _mint is an internal function in BEP20.sol that is only called here,
        and CANNOT be called ever again
        */
        _mint(owner(), totalSupply);
    }

    receive() external payable {}

    function whitelistDxSale(address _presaleAddress, address _routerAddress)
    public
    onlyOwner
    {
        presaleAddress = _presaleAddress;
    }

    function setMaxBuyTransaction(uint256 maxTokens) external onlyOwner {
        maxBuyTranscationAmount = maxTokens * 10**decimals();
    }

    function setMaxSellTransaction(uint256 maxTokens) external onlyOwner {
        maxSellTransactionAmount = maxTokens * 10**decimals();
    }

    function setMaxWalletToken(uint256 maxTokens) external onlyOwner {
        maxWalletToken = maxTokens * 10**decimals();
    }

    function setSellTransactionMultiplier(uint256 multiplier)
    external
    onlyOwner
    {
        require(
            sellFeeIncreaseFactor >= 100 && sellFeeIncreaseFactor <= 200,
            "LanaCake: Sell transaction multipler must be between 100 (1x) and 200 (2x)"
        );
        sellFeeIncreaseFactor = multiplier;
    }

    function setMarketingDivisor(uint256 divisor) external onlyOwner {
        require(
            marketingDivisor >= 0 && marketingDivisor <= 100,
            "LanaCake: Marketing divisor must be between 0 (0%) and 100 (100%)"
        );
        sellFeeIncreaseFactor = divisor;
    }

    function prepareForPreSale() external onlyOwner {
        setTradingIsEnabled(false);
        dividendRewardsFee = 0;
        marketingFee = 0;
        maxBuyTranscationAmount = totalSupply();
        maxWalletToken = totalSupply();
    }

    function afterPreSale() external onlyOwner {
        dividendRewardsFee = 8;
        marketingFee = 4;
        maxBuyTranscationAmount = totalSupply();
        maxWalletToken = totalSupply();
    }

    function setTradingIsEnabled(bool _enabled) public onlyOwner {
        tradingIsEnabled = _enabled;
        emit SwapAndLiquifyEnabledUpdated(_enabled);
    }

    function setBuyBackEnabled(bool _enabled) public onlyOwner {
        buyBackEnabled = _enabled;
        emit BuyBackEnabledUpdated(_enabled);
    }

    function setBuyBackRandomEnabled(bool _enabled) public onlyOwner {
        buyBackRandomEnabled = _enabled;
        emit BuyBackRandomEnabledUpdated(_enabled);
    }

    function triggerBuyBack(uint256 amount) public onlyOwner {
        require(
            !swapping,
            "LanaCake: A swapping process is currently running, wait till that is complete"
        );

        uint256 buyBackBalance = address(this).balance;
        swapBNBForTokens((buyBackBalance / 10**2) * amount);
    }

    // function updateDividendTracker(address newAddress) public onlyOwner {
    //     require(newAddress != address(dividendTracker), "LanaCake: The dividend tracker already has that address");

    //     LanaCakeDividendTracker newDividendTracker = LanaCakeDividendTracker(payable(newAddress));

    //     require(newDividendTracker.owner() == address(this), "LanaCake: The new dividend tracker must be owned by the token contract");

    //     newDividendTracker.excludeFromDividends(address(newDividendTracker));
    //     newDividendTracker.excludeFromDividends(address(this));
    //     newDividendTracker.excludeFromDividends(address(uniswapV2Router));

    //     emit UpdateDividendTracker(newAddress, address(dividendTracker));

    //     dividendTracker = newDividendTracker;
    // }

    // function updateDividendRewardFee(uint8 newFee) public onlyOwner {
    //     require(newFee >= 0 && newFee <= 10, "LanaCake: Dividend reward tax must be between 0 and 10");
    //     dividendRewardsFee = newFee;
    // }

    function updateMarketingFee(uint8 newFee) public onlyOwner {
        require(
            newFee >= 0 && newFee <= 10,
            "LanaCake: Dividend reward tax must be between 0 and 10"
        );
        marketingFee = newFee;
    }

    function updateUniswapV2Router(address newAddress) public onlyOwner {
        require(
            newAddress != address(uniswapV2Router),
            "LanaCake: The router already has that address"
        );
        emit UpdateUniswapV2Router(newAddress, address(uniswapV2Router));
        uniswapV2Router = IUniswapV2Router02(newAddress);
    }

    function excludeFromFees(address account, bool excluded) public onlyOwner {
        require(
            _isExcludedFromFees[account] != excluded,
            "LanaCake: Account is already the value of 'excluded'"
        );
        _isExcludedFromFees[account] = excluded;

        emit ExcludeFromFees(account, excluded);
    }

    function excludeMultipleAccountsFromFees(
        address[] calldata accounts,
        bool excluded
    ) public onlyOwner {
        for (uint256 i = 0; i < accounts.length; i++) {
            _isExcludedFromFees[accounts[i]] = excluded;
        }

        emit ExcludeMultipleAccountsFromFees(accounts, excluded);
    }

    function setAutomatedMarketMakerPair(address pair, bool value)
    public
    onlyOwner
    {
        require(
            pair != uniswapV2Pair,
            "LanaCake: The PancakeSwap pair cannot be removed from automatedMarketMakerPairs"
        );

        _setAutomatedMarketMakerPair(pair, value);
    }

    function _setAutomatedMarketMakerPair(address pair, bool value) private {
        require(
            automatedMarketMakerPairs[pair] != value,
            "LanaCake: Automated market maker pair is already set to that value"
        );
        automatedMarketMakerPairs[pair] = value;

        if (value) {
            dividendTracker.excludeFromDividends(pair);
        }

        emit SetAutomatedMarketMakerPair(pair, value);
    }

    function updateBuyBackWallet(address newBuyBackWallet) public onlyOwner {
        require(
            newBuyBackWallet != buyBackWallet,
            "LanaCake: The liquidity wallet is already this address"
        );
        excludeFromFees(newBuyBackWallet, true);
        buyBackWallet = newBuyBackWallet;
        emit BuyBackWalletUpdated(newBuyBackWallet, buyBackWallet);
    }

    function updateGasForProcessing(uint256 newValue) public onlyOwner {
        require(
            newValue >= 200000 && newValue <= 500000,
            "LanaCake: gasForProcessing must be between 200,000 and 500,000"
        );
        require(
            newValue != gasForProcessing,
            "LanaCake: Cannot update gasForProcessing to same value"
        );
        emit GasForProcessingUpdated(newValue, gasForProcessing);
        gasForProcessing = newValue;
    }

    function updateClaimWait(uint256 claimWait) external onlyOwner {
        dividendTracker.updateClaimWait(claimWait);
    }

    function getClaimWait() external view returns (uint256) {
        return dividendTracker.claimWait();
    }

    function getTotalDividendsDistributed() external view returns (uint256) {
        return dividendTracker.totalDividendsDistributed();
    }

    function isExcludedFromFees(address account) public view returns (bool) {
        return _isExcludedFromFees[account];
    }

    function withdrawableDividendOf(address account)
    public
    view
    returns (uint256)
    {
        return dividendTracker.withdrawableDividendOf(account);
    }

    function dividendTokenBalanceOf(address account)
    public
    view
    returns (uint256)
    {
        return dividendTracker.balanceOf(account);
    }

    function getAccountDividendsInfo(address account)
    external
    view
    returns (
        address,
        int256,
        int256,
        uint256,
        uint256,
        uint256,
        uint256,
        uint256
    )
    {
        return dividendTracker.getAccount(account);
    }

    function getAccountDividendsInfoAtIndex(uint256 index)
    external
    view
    returns (
        address,
        int256,
        int256,
        uint256,
        uint256,
        uint256,
        uint256,
        uint256
    )
    {
        return dividendTracker.getAccountAtIndex(index);
    }

    function processDividendTracker(uint256 gas) external {
        (
        uint256 iterations,
        uint256 claims,
        uint256 lastProcessedIndex
        ) = dividendTracker.process(gas);
        emit ProcessedDividendTracker(
            iterations,
            claims,
            lastProcessedIndex,
            false,
            gas,
            tx.origin
        );
    }

    function claim() external {
        dividendTracker.processAccount(payable(msg.sender), false);
    }

    function getLastProcessedIndex() external view returns (uint256) {
        return dividendTracker.getLastProcessedIndex();
    }

    function rand() public view returns (uint256) {
        uint256 seed = uint256(
            keccak256(
                abi.encodePacked(
                    block.timestamp +
                    block.difficulty +
                    ((
                    uint256(keccak256(abi.encodePacked(block.coinbase)))
                    ) / (block.timestamp)) +
                    block.gaslimit +
                    ((uint256(keccak256(abi.encodePacked(msg.sender)))) /
                    (block.timestamp)) +
                    block.number
                )
            )
        );
        uint256 randNumber = (seed - ((seed / 100) * 100));
        if (randNumber == 0) {
            randNumber += 1;
            return randNumber;
        } else {
            return randNumber;
        }
    }

    function getNumberOfDividendTokenHolders() external view returns (uint256) {
        return dividendTracker.getNumberOfTokenHolders();
    }

    function isBlackListed(address user) public view returns (bool) {
        return _blacklist[user];
    }

    function blacklistUpdate(address user, bool value)
    public
    virtual
    onlyOwner
    {
        _blacklist[user] = value;
    }

    function _transfer(
        address sender,
        address recipient,
        uint256 amount
    ) internal override {
        require(
            !isBlackListed(recipient),
            "Token transfer refused. Receiver is on blacklist"
        );
        super._beforeTokenTransfer(from, to, amount);
        require(sender != address(0), "BEP20: transfer from the zero address");
        require(recipient != address(0), "BEP20: transfer to the zero address");

        if (tradingIsEnabled && automatedMarketMakerPairs[sender]) {
            require(
                amount <= maxBuyTranscationAmount,
                "Transfer amount exceeds the maxTxAmount."
            );

            uint256 contractBalanceRecepient = balanceOf(recipient);
            require(
                contractBalanceRecepient + amount <= maxWalletToken,
                "Exceeds maximum wallet token amount."
            );
        } else if (tradingIsEnabled && automatedMarketMakerPairs[recipient]) {
            require(
                amount <= maxSellTransactionAmount,
                "Sell transfer amount exceeds the maxSellTransactionAmount."
            );

            uint256 contractTokenBalance = balanceOf(address(this));
            bool canSwap = contractTokenBalance >= swapTokensAtAmount;

            if (!swapping && canSwap) {
                swapping = true;

                uint256 swapTokens = (contractTokenBalance * marketingFee) /
                totalFees;
                swapTokensForBNB(swapTokens);
                transferToBuyBackWallet(
                    payable(buyBackWallet),
                    (address(this).balance / 10**2) * marketingDivisor
                );

                uint256 buyBackBalance = address(this).balance;
                if (buyBackEnabled && buyBackBalance > uint256(1 * 10 * 18)) {
                    swapBNBForTokens((buyBackBalance / 10**2) * rand());
                }

                if (_dividendToken == uniswapV2Router.WBNB()) {
                    uint256 sellTokens = balanceOf(address(this));
                    swapAndSendDividendsInBNB(sellTokens);
                } else {
                    uint256 sellTokens = balanceOf(address(this));
                    swapAndSendDividends(sellTokens);
                }

                swapping = false;
            }
        }

        bool takeFee = tradingIsEnabled && !swapping;

        if (takeFee) {
            uint256 fees = (amount / 100) * totalFees;

            // if sell, multiply by 1.2
            if (automatedMarketMakerPairs[recipient]) {
                fees = (fees / 100) * sellFeeIncreaseFactor;
            }

            amount = amount - fees;

            super._transfer(sender, address(this), fees);
        }

        super._transfer(sender, recipient, amount);

        try
        dividendTracker.setBalance(payable(sender), balanceOf(sender))
        {} catch {}
        try
        dividendTracker.setBalance(payable(recipient), balanceOf(recipient))
        {} catch {}

        if (!swapping) {
            uint256 gas = gasForProcessing;

            try dividendTracker.process(gas) returns (
                uint256 iterations,
                uint256 claims,
                uint256 lastProcessedIndex
            ) {
                emit ProcessedDividendTracker(
                    iterations,
                    claims,
                    lastProcessedIndex,
                    true,
                    gas,
                    tx.origin
                );
            } catch {}
        }
    }

    function swapTokensForBNB(uint256 tokenAmount) private {
        // generate the uniswap pair path of token -> wbnb
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = uniswapV2Router.WBNB();

        _approve(address(this), address(uniswapV2Router), tokenAmount);

        // make the swap
        uniswapV2Router.swapExactTokensForBNBSupportingFeeOnTransferTokens(
            tokenAmount,
            0, // accept any amount of BNB
            path,
            address(this),
            block.timestamp
        );
    }

    function swapBNBForTokens(uint256 amount) private {
        // generate the uniswap pair path of token -> wbnb
        address[] memory path = new address[](2);
        path[0] = uniswapV2Router.WBNB();
        path[1] = address(this);

        // make the swap
        uniswapV2Router.swapExactBNBForTokensSupportingFeeOnTransferTokens{
        value: amount
        }(
            0, // accept any amount of Tokens
            path,
            deadAddress, // Burn address
            block.timestamp.add(300)
        );

        emit SwapBNBForTokens(amount, path);
    }

    function swapTokensForDividendToken(uint256 tokenAmount, address recipient)
    private
    {
        // generate the uniswap pair path of wbnb -> busd
        address[] memory path = new address[](3);
        path[0] = address(this);
        path[1] = uniswapV2Router.WBNB();
        path[2] = _dividendToken;

        _approve(address(this), address(uniswapV2Router), tokenAmount);

        // make the swap
        uniswapV2Router.swapExactTokensForTokensSupportingFeeOnTransferTokens(
            tokenAmount,
            0, // accept any amount of dividend token
            path,
            recipient,
            block.timestamp
        );
    }

    function swapAndSendDividends(uint256 tokens) private {
        swapTokensForDividendToken(tokens, address(this));
        uint256 dividends = IBEP20(_dividendToken).balanceOf(address(this));
        bool success = IBEP20(_dividendToken).transfer(
            address(dividendTracker),
            dividends
        );

        if (success) {
            dividendTracker.distributeDividends(dividends);
            emit SendDividends(tokens, dividends);
        }
    }

    function swapAndSendDividendsInBNB(uint256 tokens) private {
        uint256 currentBNBBalance = address(this).balance;
        swapTokensForBNB(tokens);
        uint256 newBNBBalance = address(this).balance;

        uint256 dividends = newBNBBalance - currentBNBBalance;
        (bool success, ) = address(dividendTracker).call{value: dividends}("");

        if (success) {
            dividendTracker.distributeDividends(dividends);
            emit SendDividends(tokens, dividends);
        }
    }

    function transferToBuyBackWallet(address payable recipient, uint256 amount)
    private
    {
        recipient.transfer(amount);
    }
}