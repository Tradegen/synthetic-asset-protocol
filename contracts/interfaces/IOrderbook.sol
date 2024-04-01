// SPDX-License-Identifier: MIT

pragma solidity ^0.8.3;

interface IOrderbook {
    /**
    * @notice Returns the info for the order at the given index.
    * @param _orderIndex Index of the order.
    * @return uint256, uint256, uint256, uint256 The order size, number of tokens filled, execution price, and timestamp at which the order was filled.
    */
    function getOrderInfo(uint256 _orderIndex) external view returns (uint256, uint256, uint256, uint256);

    /**
    * @notice Returns the order info for the given user's pending order.
    * @dev Returns (0, 0, 0, 0) if the user does not have an order.
    * @param _user Address of the user.
    * @return uint256, uint256, uint256, uint256 The order size, number of tokens filled, execution price, and timestamp at which the order was filled.
    */
    function getPendingOrderInfo(address _user) external view returns (uint256, uint256, uint256, uint256);

    /**
    * @notice Returns the number of tokens that the given user can claim.
    * @param _user Address of the user.
    */
    function getAvailableTokens(address _user) external view returns (uint256);

    /**
    * @notice Returns the dollar value of the given user's available tokens.
    * @param _user Address of the user.
    */
    function getAvailableDollarAmount(address _user) external view returns (uint256);

    /**
    * @notice Places an order for the given number of tokens.
    * @dev Transaction will revert if _numberOfTokens exceeds msg.sender's balance.
    * @param _numberOfTokens The number of tokens to buy/sell.
    */
    function placeOrder(uint256 _numberOfTokens) external;

    /**
    * @notice Cancels the pending order for msg.sender.
    * @dev If _cancelFullOrder is set to true, _numberOfTokens is ignored.
    * @dev This function also claims all available tokens for msg.sender.
    * @dev Transaction will revert if _numberOfTokens exceeds msg.sender's order size.
    * @param _numberOfTokens The number of tokens to cancel.
    * @param _cancelFullOrder Whether to fully cancel the order.
    */
    function cancelOrder(uint256 _numberOfTokens, bool _cancelFullOrder) external;

    /**
    * @notice Claims all available tokens for msg.sender.
    */
    function claimTokens() external;

    /**
    * @notice Pauses trading for this asset.
    * @dev Only the operator of the Router contract can call this function.
    * @dev This function is meant to be used to protect the protocol from Black Swan events.
    * @param _pauseTrading Whether to pause trading. Set this value to false to resume trading.
    */
    function pauseTrading(bool _pauseTrading) external;
}