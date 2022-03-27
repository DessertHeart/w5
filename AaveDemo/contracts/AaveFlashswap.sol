// SPDX-License-Identifier: MIT

pragma solidity ^0.8.13;


// AAVE
import './aave-v3-core/contracts/flashloan/base/FlashLoanReceiverBase.sol';
import './aave-v3-core/contracts/flashloan/base/FlashLoanSimpleReceiverBase.sol';
import './aave-v3-core/contracts/interfaces/IPool.sol';
// Others


contract AaveFlashswap is FlashLoanReceiverBase, FlashLoanSimpleReceiverBase {

    event SuccessEvent(string indexed message);
    event CatchStringError(string indexed message);
    event CatchDataError(bytes indexed data);

    address immutable pool;

    constructor(address _pool) public {
        pool = _pool;
    }

    receive() external payable {}

    // 调用swap执行闪电贷
    function flashSwapCall(uint amountAirToken) public {
        
        try IPool(pool).FlashLoan({
            target: ,
            initiator: ,
            asset: ,
            amount: ,
            //DataTypes.InterestRateMode
            interestRateMode: ,
            premium: ,
            referralCode:
        }) {
            emit SuccessEvent("FlashSwap Success!");
        } catch Error(string memory reason) {
            emit CatchStringError(reason);
        } catch (bytes memory data) {
            emit CatchDataError(data);
        }
    }

    // todo:闪电贷回调函数
    // _reserves, _reservesList, _eModeCategories, _usersConfig[onBehalfOf], flashParams
    function executeOperation() external override {
 
    }

}