// SPDX-License-Identifier: MIT

pragma solidity ^0.8.3;

// OpenZeppelin.
import "./openzeppelin-solidity/contracts/Ownable.sol";

// Inheritance.
import './interfaces/IProtocolSettings.sol';

contract ProtocolSettings is IProtocolSettings, Ownable {
    uint256 public override maxDiscount;
    uint256 public override mintFee;
    uint256 public override minimumMinimumTimeUntilDiscountStarts;
    uint256 public override maximumMinimumTimeUntilDiscountStarts;
    uint256 public override minimumTimeUntilMaxDiscount;
    uint256 public override maximumTimeUntilMaxDiscount;

    constructor() Ownable() {}

    /* ========== RESTRICTED FUNCTIONS ========== */

    /**
    * @notice Updates the value of maxDiscount.
    * @dev This function can only be called by the ProtocolSettings contract owner.
    * @param _newMaxDiscount The new value for max discount.
    */
    function updateMaxDiscount(uint256 _newMaxDiscount) external onlyOwner {
        require(_newMaxDiscount > 0 && _newMaxDiscount < 10000, "ProtocolSettings: Max discount is out of bounds.");

        uint256 oldMaxDiscount = maxDiscount;
        maxDiscount = _newMaxDiscount;

        emit UpdateMaxDiscount(oldMaxDiscount, _newMaxDiscount);
    }

    /**
    * @notice Updates the value of mintFee.
    * @dev This function can only be called by the ProtocolSettings contract owner.
    * @param _newMintFee The new value for mint fee.
    */
    function updateMintFee(uint256 _newMintFee) external onlyOwner {
        require(_newMintFee > 0 && _newMintFee < 10000, "ProtocolSettings: Mint fee is out of bounds.");

        uint256 oldMintFee = mintFee;
        mintFee = _newMintFee;

        emit UpdateMintFee(oldMintFee, _newMintFee);
    }

    /**
    * @notice Sets minimumMinimumTimeUntilDiscountStarts to the given value.
    * @dev This function can only be called by the ProtocolSettings contract owner.
    */
    function updateMinimumMinimumTimeUntilDiscountStarts(uint256 _newValue) external onlyOwner {
        require(_newValue < maximumMinimumTimeUntilDiscountStarts, "ProtocolSettings: Minimum minimum time until discount starts must be smaller than the maximum value.");

        uint256 oldValue = minimumMinimumTimeUntilDiscountStarts;
        minimumMinimumTimeUntilDiscountStarts = _newValue;

        emit UpdateMinimumMinimumTimeUntilDiscountStarts(oldValue, _newValue);
    }

    /**
    * @notice Sets maximumMinimumTimeUntilDiscountStarts to the given value.
    * @dev This function can only be called by the ProtocolSettings contract owner.
    */
    function updateMaximumMinimumTimeUntilDiscountStarts(uint256 _newValue) external onlyOwner {
        require(_newValue > minimumMinimumTimeUntilDiscountStarts, "ProtocolSettings: Maximum minimum time until discount starts must be greater than the minimum value.");

        uint256 oldValue = maximumMinimumTimeUntilDiscountStarts;
        maximumMinimumTimeUntilDiscountStarts = _newValue;

        emit UpdateMaximumMinimumTimeUntilDiscountStarts(oldValue, _newValue);
    }

    /**
    * @notice Sets minimumTimeUntilMaxDiscount to the given value.
    * @dev This function can only be called by the ProtocolSettings contract owner.
    */
    function updateMinimumTimeUntilMaxDiscount(uint256 _newValue) external onlyOwner {
        require(_newValue < maximumTimeUntilMaxDiscount, "ProtocolSettings: Minimum time until max discount must be smaller than the maximum value.");

        uint256 oldValue = minimumTimeUntilMaxDiscount;
        minimumTimeUntilMaxDiscount = _newValue;

        emit UpdateMinimumTimeUntilMaxDiscount(oldValue, _newValue);
    }

    /**
    * @notice Sets maximumTimeUntilMaxDiscount to the given value.
    * @dev This function can only be called by the ProtocolSettings contract owner.
    */
    function updateMaximumTimeUntilMaxDiscount(uint256 _newValue) external onlyOwner {
        require(_newValue > minimumTimeUntilMaxDiscount, "ProtocolSettings: Maximum time until max discount must be greater than the minimum value.");

        uint256 oldValue = maximumTimeUntilMaxDiscount;
        maximumTimeUntilMaxDiscount = _newValue;

        emit UpdateMaximumTimeUntilMaxDiscount(oldValue, _newValue);
    }

    /* ========== EVENTS ========== */

    event UpdateMaxDiscount(uint256 oldMaxDiscount, uint256 newMaxDiscount);
    event UpdateMintFee(uint256 oldMintFee, uint256 newMintFee);
    event UpdateMinimumMinimumTimeUntilDiscountStarts(uint256 oldValue, uint256 newValue);
    event UpdateMaximumMinimumTimeUntilDiscountStarts(uint256 oldValue, uint256 newValue);
    event UpdateMinimumTimeUntilMaxDiscount(uint256 oldValue, uint256 newValue);
    event UpdateMaximumTimeUntilMaxDiscount(uint256 oldValue, uint256 newValue);
}