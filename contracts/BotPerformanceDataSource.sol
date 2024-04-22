// SPDX-License-Identifier: MIT

pragma solidity ^0.8.3;

// OpenZeppelin.
import "./openzeppelin-solidity/contracts/Ownable.sol";
import './openzeppelin-solidity/contracts/ERC20/SafeERC20.sol';

// Interfaces.
import './interfaces/external/IBotPerformanceDataFeedRegistry.sol';

// Inheritance.
import './interfaces/IDataSource.sol';

contract BotPerformanceDataSource is IDataSource, Ownable {
    using SafeERC20 for IERC20;

    IBotPerformanceDataFeedRegistry public registry;

    constructor(address _registry) Ownable() {
        registry = IBotPerformanceDataFeedRegistry(_registry);
    }

    /* ========== VIEWS ========== */

    /**
    * @notice Returns the info needed to pay the usage fee for the given asset.
    * @param _asset Address of the asset.
    * @return address, uint256 The address of the asset's usage fee token and the asset's usage fee.
    */
    function getUsageFeeInfo(address _asset) public view returns (address, uint256) {
        address feeToken = registry.usageFeeToken(_asset);
        uint256 usageFee = registry.usageFee(_asset);

        return (feeToken, usageFee);
    }

    /* ========== MUTATIVE FUNCTIONS ========== */

    /**
    * @notice Returns the latest price of the given asset.
    * @dev Calls the data feed associated with the asset to get the price.
    * @dev If the data feed does not exist, returns 0.
    * @dev This function assumes that msg.sender has approved the usage fee for the asset's fee token.
    * @param _asset Address of the asset.
    * @return uint256 Latest price of the asset.
    */
    function getLatestPrice(address _asset) external override returns (uint256) {
        address feeToken;
        uint256 usageFee;
        (feeToken, usageFee) = getUsageFeeInfo(_asset);

        IERC20(feeToken).safeTransferFrom(msg.sender, address(this), usageFee);
        IERC20(feeToken).approve(_asset, usageFee);

        return registry.getTokenPrice(_asset);
    }

    /* ========== RESTRICTED FUNCTIONS ========== */

    /**
    * @notice Updates the address of the registry.
    * @dev This function can only be called by the DataSource contract owner.
    * @param _registry Address of the BotPerformanceDataFeedRegistry contract.
    */
    function setRegistry(address _registry) external onlyOwner {
        registry = IBotPerformanceDataFeedRegistry(_registry);

        emit SetRegistry(_registry);
    }

    /* ========== EVENTS ========== */

    event SetRegistry(address newRegistry);
}