// SPDX-License-Identifier: MIT

pragma solidity ^0.8.3;

interface IDataSource {
    /**
    * @notice Returns the latest price of the given asset.
    * @dev Calls the data feed associated with the asset to get the price.
    * @dev If the data feed does not exist, returns 0.
    * @param _asset Address of the asset.
    * @return uint256 Latest price of the asset.
    */
    function getLatestPrice(address _asset) external returns (uint256);

    /**
    * @notice Returns the info needed to pay the usage fee for the given asset.
    * @param _asset Address of the asset.
    * @return address, uint256 The address of the asset's usage fee token and the asset's usage fee.
    */
    function getUsageFeeInfo(address _asset) external view returns (address, uint256);
}