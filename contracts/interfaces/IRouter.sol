// SPDX-License-Identifier: MIT

pragma solidity ^0.8.3;

interface IRouter {
    /**
    * @notice Returns the info for the order at the given index.
    * @dev Returns (0, 0, 0, 0) if the asset is not found or the order index is out of bounds.
    * @param _syntheticAsset Address of the synthetic asset.
    * @param _isBuy Whether to use the 'buy' version of the asset's orderbook.
    * @param _orderIndex Index of the order.
    * @return uint256, uint256, uint256, uint256 The order size, number of tokens filled, execution price, and timestamp at which the order was filled.
    */
    function getOrderInfo(address _syntheticAsset, bool _isBuy, uint256 _orderIndex) external view returns (uint256, uint256, uint256, uint256);

    /**
    * @notice Returns the order info for the given user's pending order.
    * @dev Returns (0, 0, 0, 0) if the asset is not found or the user does not have an order.
    * @param _syntheticAsset Address of the synthetic asset.
    * @param _isBuy Whether to use the 'buy' version of the asset's orderbook.
    * @param _user Address of the user.
    * @return uint256, uint256, uint256, uint256 The order size, number of tokens filled, execution price, and timestamp at which the order was filled.
    */
    function getPendingOrderInfo(address _syntheticAsset, bool _isBuy, address _user) external view returns (uint256, uint256, uint256, uint256);

    /**
    * @notice Returns the number of tokens that the given user can claim.
    * @dev Returns 0 if the asset is not found.
    * @param _syntheticAsset Address of the synthetic asset.
    * @param _isBuy Whether to use the 'buy' version of the asset's orderbook.
    * @param _user Address of the user.
    */
    function getAvailableTokens(address _syntheticAsset, bool _isBuy, address _user) external view returns (uint256);

    /**
    * @notice Returns the dollar value of the given user's available tokens.
    * @dev Returns 0 if the asset is not found.
    * @param _syntheticAsset Address of the synthetic asset.
    * @param _isBuy Whether to use the 'buy' version of the asset's orderbook.
    * @param _user Address of the user.
    */
    function getAvailableDollarAmount(address _syntheticAsset, bool _isBuy, address _user) external view returns (uint256);

    /**
    * @notice Returns the two orderbook addresses for the given asset.
    * @dev Returns (address(0), address(0)) if the asset is not found.
    * @param _syntheticAsset Address of the synthetic asset.
    * @return address, address The address of the 'buy' version of the orderbook and the address of the 'sell' version.
    */
    function getOrderbookAddresses(address _syntheticAsset) external view returns (address, address);

    /**
    * @notice Pauses trading for this asset.
    * @dev Only the operator of the Router contract can call this function.
    * @dev Pauses trading for both the 'buy' and 'sell' versions of the asset's orderbook.
    * @dev This function is meant to be used to protect the protocol from Black Swan events.
    * @param _pauseTrading Whether to pause trading. Set this value to false to resume trading.
    */
    function pauseTrading(address _syntheticAsset, bool _pauseTrading) external;

    /**
    * @notice Deploys the 'buy' and 'sell' version of the orderbook for the given asset.
    * @dev Only the SyntheticAssetTokenRegistry contract can call this function.
    * @dev Transaction will revert if the orderbooks have already been created for the asset.
    * @param _syntheticAsset Address of the asset.
    */
    function createOrderbooks(address _syntheticAsset) external;
}