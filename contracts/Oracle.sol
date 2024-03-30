// SPDX-License-Identifier: MIT

pragma solidity ^0.8.3;

// OpenZeppelin.
import "./openzeppelin-solidity/contracts/Ownable.sol";
import './openzeppelin-solidity/contracts/ERC20/SafeERC20.sol';

// Interfaces.
import './interfaces/IDataSource.sol';

// Inheritance.
import './interfaces/IOracle.sol';

contract Oracle is IOracle, Ownable {
    using SafeERC20 for IERC20;

    address public override dataSource;

    constructor(address _dataSource) Ownable() {
        dataSource = _dataSource;
    }

    /* ========== VIEWS ========== */

    /**
    * @notice Returns the latest price of the given asset.
    * @dev Calls the current data source to get the price.
    * @param _asset Address of the asset.
    * @return uint256 Latest price of the asset.
    */
    function getLatestPrice(address _asset) external override returns (uint256) {
        address feeToken;
        uint256 usageFee;
        (feeToken, usageFee) = IDataSource(dataSource).getUsageFeeInfo(_asset);

        IERC20(feeToken).safeTransferFrom(msg.sender, address(this), usageFee);
        IERC20(feeToken).approve(_asset, usageFee);

        return IDataSource(dataSource).getLatestPrice(_asset);
    }

    /* ========== RESTRICTED FUNCTIONS ========== */

    /**
    * @notice Updates the address of the data source.
    * @dev This function can only be called by the Oracle contract owner.
    * @param _dataSource Address of the DataSource contract.
    */
    function setDataSource(address _dataSource) external onlyOwner {
        dataSource = _dataSource;

        emit SetDataSource(_dataSource);
    }

    /* ========== EVENTS ========== */

    event SetDataSource(address newDataSource);
}