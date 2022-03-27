// SPDX-License-Identifier: MIT

pragma solidity =0.6.6;

import './uniswap-v2-core-master/contracts/interfaces/IUniswapV2Pair.sol';
import './uniswap-v2-core-master/contracts/interfaces/IUniswapV2Callee.sol';
import './uniswap-v2-periphery-master/contracts/interfaces/IUniswapV2Router01.sol';

import './uniswap-v3-core/interfaces/IUniswapV3Factory.sol';
import './uniswap-v3-periphery/interfaces/ISwapRouter.sol';

import './uniswap-v2-periphery-master/contracts/interfaces/IERC20.sol';
import './uniswap-v2-periphery-master/contracts/libraries/UniswapV2Library.sol';
import './uniswap-v2-periphery-master/contracts/libraries/TransferHelper.sol';


contract UniswapV2Flashswap is IUniswapV2Callee {

    event SuccessEvent(string indexed message);
    event CatchStringError(string indexed message);
    event CatchDataError(bytes indexed data);

    address immutable factoryV3;
    address immutable factoryV2;
    address immutable piarV2;
    address immutable airToken;
    address immutable flyToken;
    address immutable swapRouterV3;

    // V3参数
    uint24 constant private POOL_FEE = 3000;

    constructor(address _factoryV2, address _factoryV3, address _piarV2, address _airToken, address _flyToken, address _swapRouterV3) public {
        factoryV3 = _factoryV3;
        factoryV2 = _factoryV2;
        airToken = _airToken;
        piarV2 = _piarV2;
        flyToken = _flyToken;
        swapRouterV3 = _swapRouterV3;
    }

    receive() external payable {}

    // 调用swap执行闪电贷
    function flashSwapCall(uint amountAirToken) public {
        address Pair = UniswapV2Library.pairFor(factoryV2, airToken, flyToken);
        airToken.safeApprove(address(piarV2), type(uint).max);
        flyToken.safeApprove(address(piarV2), type(uint).max);

        try IUniswapV2Pair(Pair).swap(amountAirToken, 0, address(this), 0x01) {
            emit SuccessEvent("FlashSwap Success!");
        } catch Error(string memory reason) {
            emit CatchStringError(reason);
        } catch (bytes memory data) {
            emit CatchDataError(data);
        }
    }

    // 闪电贷回调函数：V2借到AirToken， AirToken注入V3，得到FlyToken，还FlyToken给V2
    function uniswapV2Call(address sender, uint amount0, uint amount1, bytes calldata data) external override {
        address[] memory path = new address[](2);
        uint amountAirToken;
        uint amountFlyToken;

        // scope for token{0,1}, avoids stack too deep errors
        { 
        // 获取当前池中交易对token地址
        address token0 = airToken;
        address token1 = flyToken;
        // 检查是不是V2-pair
        assert(msg.sender == UniswapV2Library.pairFor(factoryV2, token0, token1)); 
        // 买token1
        assert(amount0 == 0 || amount1 == 0); 
        path[0] = token0;
        path[1] = token1;
        // 记录买到的AirToken的数量
        amountAirToken = amount1 == 0 ? amount0 : amount0;
        }

        if (amountAirToken > 0) {
            // 授权RouterV3
            airToken.safeApprove(address(swapRouterV3), 100_000);
            flyToken.safeApprove(address(swapRouterV3), 100_000);
            // todo: V3借贷
            uint amountReceived = ISwapRouter(swapRouterV3).exactInputSingle(
                ISwapRouter.ExactInputSingleParams({
                    tokenIn: path[0],
                    tokenOut: path[1],
                    fee: POOL_FEE,
                    recipient: address(this),
                    //deadline:
                    amountIn: amountAirToken.add(1000),
                    amountOutMinimum: 0,
                    sqrtPriceLimitX96: 0
                })
            );
            // 需还款的flyToken金额
            uint amountRequired = UniswapV2Library.getAmountsIn(factoryV2, amountAirToken, path)[0];

            // 如果倒手得到的币不足以还款，回滚
            assert(amountReceived > amountRequired); 

            // 归还借出的部分
            assert(IERC20(flyToken).safeTransfer(msg.sender, amountRequired)); 

            // 套利（如果有）
            assert(IERC20(flyToken).safeTransfer(msg.sender, amountReceived - amountRequired)); 
        } 
    }

}