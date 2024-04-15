// SPDX-License-Identifier: MIT

pragma solidity ^0.8.3;

interface IProtocolSettings {
    /**
    * @notice Returns the maximum discount at which a market maker can fill an order.
    * @dev This value is expressed as a percentage with two decimals. Ex) A 20% discount would have the value 2000.
    */
    function maxDiscount() external view returns (uint256);

    /**
    * @notice Returns the fee for minting a synthetic asset.
    * @dev The fee is a percentage of the dollar value of the user's order.
    * @dev This value is expressed in two decimals. Ex) A 0.3% mint fee would have the value 30.
    */
    function mintFee() external view returns (uint256);

    /**
    * @notice Returns the minimum value that a user can set for their minimumTimeUntilDiscountStarts setting.
    */
    function minimumMinimumTimeUntilDiscountStarts() external view returns (uint256);

    /**
    * @notice Returns the maximum value that a user can set for their minimumTimeUntilDiscountStarts setting.
    */
    function maximumMinimumTimeUntilDiscountStarts() external view returns (uint256);

    /**
    * @notice Returns the minimum value that a user can set for their timeUntilMaxDiscount setting.
    */
    function minimumTimeUntilMaxDiscount() external view returns (uint256);

    /**
    * @notice Returns the maximum value that a user can set for their timeUntilMaxDiscount setting.
    */
    function maximumTimeUntilMaxDiscount() external view returns (uint256);
}