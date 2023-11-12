// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";

import "./base/OrchestratedUpgradeable.sol";
import "./pacakeSwap/IPancakeRouter02.sol";
import "./IPancakeSwapUtil.sol";


contract FaManage is OrchestratedUpgradeable, PausableUpgradeable {
    using SafeMath for uint;
    using SafeERC20 for IERC20;

    bool private inSwapAndLiquify;


    IPancakeRouter02 public uniswapV2Router;
    IERC20 public usdtToken;
    IERC20 public faToken;
    IPancakeSwapUtil public swapUtil;

    bool public useSwapPrice;
    uint public faPrice;

    uint public swapTotal;

    function initialize(
        address _uniswapV2Router,
        address _usdtToken,
        address _faToken,
        address _swapUtil
    ) initializer public {
        __Pausable_init();
        __Ownable_init_unchained();
        __Orchestrated_init_unchained();

        uniswapV2Router = IPancakeRouter02(_uniswapV2Router);
        usdtToken = IERC20(_usdtToken);
        faToken = IERC20(_faToken);
        swapUtil = IPancakeSwapUtil(_swapUtil);

        faPrice = 2*1e17;
    }

    function setAllAuth(address account) public onlyAdmin {
        orchestrate(account, 0xcc169ff2);
        orchestrate(account, 0xe1267a71);
        orchestrate(account, 0x1618e130);
        orchestrate(account, 0xca480089);
    }

    function setFaPrice(uint value) public onlyAdmin {
        faPrice = value;
    }

    function setUseSwapPrice(bool value) public onlyAdmin {
        useSwapPrice = value;
    }

    function getFaPrice() public view returns(uint) {
        if(useSwapPrice) {
            return swapUtil.tokenAConvertTokenB(faToken, usdtToken, 1e18);
        }
        return faPrice;
    }

    //0xcc169ff2
    function swapFa(address account, uint usdtAmount) public onlyOrchestrated("onlyOrchestrated: swapFa") returns(uint){
        uint faAmount = 0;
        if(useSwapPrice) {
            swapTotal = swapTotal.add(usdtAmount);
            uint beforeBalance = faToken.balanceOf(address(this));
            swapTokenAForTokenB(usdtToken, faToken, usdtAmount, address(this));
            uint afterBalance = faToken.balanceOf(address(this));
            faAmount = afterBalance.sub(beforeBalance);
        } else {
            faAmount = usdtAmount.mul(1e18).div(faPrice);
        }
        faToken.transfer(account, faAmount);
        return faAmount;
    }

    //0xe1267a71
    function swapETHForToken(uint256 bnbAmount, uint amountOutMin) public onlyOrchestrated("onlyOrchestrated: swapETHForToken"){
        _swapETHForToken(address(usdtToken), bnbAmount, amountOutMin);
    }

    //0x1618e130
    function swapTokenForETH(uint256 tokenAmount, uint amountOutMin) public onlyOrchestrated("onlyOrchestrated: swapTokenForETH"){
        _swapTokenForETH(address(usdtToken), tokenAmount, amountOutMin);
    }

    function swapAndLiquify(uint256 tokenAAmountToAddLiquify, IERC20 tokenA, IERC20 tokenB, address ) private lockTheSwap {
        // 把tokenA分成2份
        uint256 half = tokenAAmountToAddLiquify.div(2);
        uint256 otherHalf = tokenAAmountToAddLiquify.sub(half);

        uint256 initialTokenBBalance = tokenB.balanceOf(address(this));

        // swap TokenA for TokenB
        swapTokenAForTokenB(tokenA, tokenB, half, address(this));

        // how much Token did we just swap into?
        uint256 swapTokenBAmount = tokenB.balanceOf(address(this)).sub(initialTokenBBalance);

        // add liquidity to uniswap
        addLiquidity(otherHalf, swapTokenBAmount, tokenA, tokenB);

        emit SwapAndLiquify(address(tokenA), address(tokenB), half, swapTokenBAmount, otherHalf);
    }

    modifier lockTheSwap {
        inSwapAndLiquify = true;
        _;
        inSwapAndLiquify = false;
    }

    function swapTokenAForTokenB(IERC20 tokenA, IERC20 tokenB, uint256 tokenAAmount, address tokenBAccount) private {
        // generate the uniswap pair path of token -> weth
        address[] memory path = new address[](2);
        path[0] = address(tokenA);
        path[1] = address(tokenB);

        tokenA.approve(address(uniswapV2Router), tokenAAmount);

        // make the swap
        uniswapV2Router.swapExactTokensForTokensSupportingFeeOnTransferTokens(
            tokenAAmount,
            0, // accept any amount of token
            path,
            tokenBAccount,
            block.timestamp
        );
    }

    function addLiquidity(uint256 tokenAAmount, uint256 tokenBAmount, IERC20 tokenA, IERC20 tokenB) private {
        tokenA.approve(address(uniswapV2Router), tokenAAmount);
        tokenB.approve(address(uniswapV2Router), tokenBAmount);

        uniswapV2Router.addLiquidity(
            address(tokenA),
            address(tokenB),
            tokenAAmount,
            tokenBAmount,
            0, // slippage is unavoidable
            0, // slippage is unavoidable
            address(this),
            block.timestamp
        );
    }

    function _swapETHForToken(address tokenB, uint256 bnbAmount, uint amountOutMin) private {
        // generate the uniswap pair path of token -> weth
        address[] memory path = new address[](2);
        path[0] = address(uniswapV2Router.WETH());
        path[1] = tokenB;

        require(address(this).balance >= bnbAmount, "bnb insufficient");

        // make the swap
        uniswapV2Router.swapExactETHForTokensSupportingFeeOnTransferTokens{ value: bnbAmount }(
            amountOutMin,
            path,
            address(this),
            block.timestamp
        );
    }

    function _swapTokenForETH(address tokenA, uint256 tokenAmount, uint amountOutMin) private {
        // generate the uniswap pair path of token -> weth
        address[] memory path = new address[](2);
        path[0] = tokenA;
        path[1] = uniswapV2Router.WETH();

        IERC20(tokenA).approve(address(uniswapV2Router), tokenAmount);

        // make the swap
        uniswapV2Router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            tokenAmount,
            amountOutMin, // accept any amount of ETH
            path,
            address(this),
            block.timestamp
        );
    }


    fallback() external payable {}
    receive() external payable {}

    event SwapAndLiquify(address tokenA, address tokenB, uint256 usdtIntoSwap, uint256 tokenReceived, uint256 usdtIntoLiqudity);

}
