// SPDX-License-Identifier: MIT

pragma solidity 0.8.10;

// UniswapV3
import './uniswap-v3-periphery/interfaces/ISwapRouter.sol';
// UniswapV2
import './uniswap-v2-periphery-master/contracts/interfaces/IUniswapV2Router02.sol';
// AAVE
import {FlashLoanSimpleReceiverBase} from './aave-v3-core/contracts/flashloan/base/FlashLoanSimpleReceiverBase.sol';
import {IPoolAddressesProvider} from './aave-v3-core/contracts/interfaces/IPoolAddressesProvider.sol';
// Others
import {IERC20} from './aave-v3-core/contracts/dependencies/openzeppelin/contracts/IERC20.sol';
import './uniswap-v3-core/libraries/TransferHelper.sol';


contract AaveFlashswap is FlashLoanSimpleReceiverBase {

    //rinkeby address

    address private constant WETH = 0xc778417E063141139Fce010982780140Aa0cD5Ab;
    address private constant ATOKEN =0x784c47Ba17A32e9C636cf917c9034c0aD1E87d41;
    address private constant UNISWAP_V2_ROUTER =0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D;
    address private constant SWAPROUTER =0xE592427A0AEce92De3Edee1F18E0157C05861564;
    //V3池费
    uint24 private constant  poolFee = 3000;
    
    // AAVE.pool合约地址
    address private constant DEVADDRESS =0x6aCB38f47C14594F58614B89Aac493e1Ab3B4C34;

    event SuccessEvent(string indexed message);
    event CatchStringError(string indexed message);
    event CatchDataError(bytes indexed data);

    // IPoolAddressesProvider?
    constructor(IPoolAddressesProvider _provider) FlashLoanSimpleReceiverBase(_provider) public {}

    // 调用swap执行闪电贷
    function flashSwapCall(address _asset, uint _amount) public {
        bytes memory params = "";
        uint16 referralCode = 0;

        // POOL 来自FlashLoanReceiverBase.
        try POOL.flashLoanSimple({
            receiverAddress: address(this),
            asset: _asset,
            amount: _amount,
            params: params,
            referralCode: referralCode
        }) {
            emit SuccessEvent("FlashSwap Success!");
        } catch Error(string memory reason) {
            emit CatchStringError(reason);
        } catch (bytes memory data) {
            emit CatchDataError(data);
        }
    }

    // todo:闪电贷回调函数
    function executeOperation(
        address _asset,
        uint256 _amount,
        uint256 _fees,
        address _sender,
        bytes memory _params
    ) public override returns(bool){

        address[] memory path = new address[](2);
        path[0] = WETH;
        path[1] = ATOKEN;
        //AAVE借来的WETH，V2买ATOKEN
        IUniswapV2Router02(UNISWAP_V2_ROUTER).swapExactETHForTokens(
            0,
            path,
            address(this),
            block.timestamp
        );
        // V2买到的ATOKEN
        uint256 amountToken = IERC20(ATOKEN).balanceOf(address(this));

        //V3通过ATOKEN买WETH
        IERC20(ATOKEN).approve(address(SWAPROUTER), amountToken);
        ISwapRouter.ExactInputSingleParams memory params = ISwapRouter
            .ExactInputSingleParams({
                tokenIn: ATOKEN,
                tokenOut: WETH,
                fee: poolFee,
                recipient: address(this),
                deadline: block.timestamp,
                amountIn: amountToken,
                amountOutMinimum: 0,
                sqrtPriceLimitX96: 0
            });
        // V3获得的WETH
        uint256 amountOut = ISwapRouter(SWAPROUTER).exactInputSingle(params);

        // 还款AAVE
        uint256 amountRequired = _amount + _fees;
        IERC20(_asset).approve(address(POOL), amountRequired);
        TransferHelper.safeTransfer(_asset, address(POOL), amountRequired);

        // todo:套利amountOut - amountRequired

        return true;
    }

}