// SPDX-License-Identifier: MIT

pragma solidity =0.6.6;

import './uniswap-v2-core-master/contracts/interfaces/IUniswapV2Pair';
import './uniswap-v2-core-master/contracts/interfaces/IUniswapV2Callee.sol';
import './uniswap-v2-periphery-master/contracts/interfaces/IUniswapV2Router01.sol';

import './uniswap-v2-periphery-master/contracts/interfaces/V3/IUniswapV3Factory.sol';
import './uniswap-v2-periphery-master/contracts/interfaces/V3/ISwapRouter.sol';

import './uniswap-v2-periphery-master/contracts/interfaces/IERC20.sol';
import './uniswap-v2-periphery-master/contracts/libraries/UniswapV2Library.sol';

import './uniswap-v2-periphery-master/contracts/libraries/TransferHelper.sol';


contract UniswapV2Flashswap is IUniswapV2Callee {

    event SuccessEvent(string indexed message);
    event CatchStringError(string indexed message);
    event CatchDataError(bytes indexed data);

    address immutable factoryV3;
    address immutable factoryV2;
    address immutable routerV2;
    address immutable airToken;
    address immutable flyToken;

    constructor(address _factoryV2, address _factoryV3, address _router, address _airToken, address _flyToken) public {
        factoryV3 = _factoryV3;
        factoryV2 = _factoryV2;
        airToken = _airToken;
        routerV2 = _router;
        flyToken = _flyToken;
    }

    receive() external payable {}

    // 调用swap执行闪电贷
    function flashSwapCall(uint amountAirToken) public {
        try IUniswapV2Pair(Pair).swap(amountAirToken, 0, address(this), 0x01) {
            emit SuccessEvent("FlashSwap Success!");
        } catch Error(string memory reason) {
            emit CatchStringError(reason);
        } catch (bytes memory data) {
            emit CatchDataError(data);
        }
    }

    // 闪电贷回调函数：V2借到TokenA， TokenA注入V3，得到TokenB，还TokenB给V2
    function uniswapV2Call(address sender, uint amount0, uint amount1, bytes calldata data) external override {
        address[] memory path = new address[](2);
        uint amountAirToken;
        uint amountFlyToken;

        // scope for token{0,1}, avoids stack too deep errors
        { 
        // 获取当前池中交易对token地址
        address token0 = IUniswapV2Pair(msg.sender).token0();
        address token1 = IUniswapV2Pair(msg.sender).token1();
        // 检查是不是V2-pair
        assert(msg.sender == UniswapV2Library.pairFor(factoryV2, token0, token1)); 

        // 只能用一个买另一个，!=0的为要买的，即path[1]
        assert(amount0 == 0 || amount1 == 0); 
        path[0] = amount0 == 0 ? token0 : token1;
        path[1] = amount0 == 0 ? token1 : token0;

        // 记录期望AirToken的数量
        amountAirToken = token0 == flyToken ? amount1 : amount0;
        // 记录期望FlyToken的数量
        amountFlyToken = token0 == flyToken ? amount0 : amount1;
        }

        // 把要获得的token地址给token
        IERC20 token = IERC20(path[0] == flyToken ? path[1] : path[0]);

        if (amountAirToken > 0) {
            // 授权RouterV3
            token.approve(address(swapRouterV3), amountAirToken);

            // todo: V3借贷
            uint amountReceived = ISwapRouter(swapRouterV3).uniswapV3SwapCallback(int256 amount0Delta, int256 amount1Delta, bytes calldata _data);
            // 需还款的path[0]金额
            uint amountRequired = UniswapV2Library.getAmountsIn(factory, amountAirToken, path)[0];

            // 如果倒手得到的币不足以还款，回滚
            assert(amountReceived > amountRequired); 

            // 归还借出的部分
            assert(IERC20(flyToken).safeTransfer(msg.sender, amountRequired)); 

            // 套利（如果有）
            assert(IERC20(flyToken).safeTransfer(msg.sender, amountReceived - amountRequired)); 

        } else {
            // todo: 要购买的是FlyToken
        }
    }
    }

   
}