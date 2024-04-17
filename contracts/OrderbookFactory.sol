// SPDX-License-Identifier: MIT

pragma solidity ^0.8.3;

// OpenZeppelin.
import "./openzeppelin-solidity/contracts/Ownable.sol";

// Internal references.
import './Orderbook.sol';

// Inheritance.
import './interfaces/IOrderbookFactory.sol';

contract OrderbookFactory is IOrderbookFactory, Ownable {
    address public immutable oracle;
    address public immutable protocolSettings;
    address public immutable userSettings;
    address public immutable stablecoin;
    address public router;

    constructor(address _oracle, address _protocolSettings, address _userSettings, address _stablecoin) Ownable() {
        oracle = _oracle;
        protocolSettings = _protocolSettings;
        userSettings = _userSettings;
        stablecoin = _stablecoin;
    }

    /* ========== MUTATIVE FUNCTIONS ========== */

    /**
    * @notice Deploys an Orderbook contract and returns the contract's address.
    * @dev This function can only be called by the Router contract.
    * @param _syntheticAsset Address of the synthetic asset.
    * @param _representsBuyOrders Whether this is the 'buy' version of the orderbook.
    * @return address Address of the deployed Orderbook contract.
    */
    function createOrderbook(address _syntheticAsset, bool _representsBuyOrders) external override onlyRouter returns (address) {
        address orderbook = address(new Orderbook(router, oracle, protocolSettings, userSettings, stablecoin, _syntheticAsset, _representsBuyOrders));

        emit CreatedOrderbook(_syntheticAsset, _representsBuyOrders, orderbook);

        return orderbook;
    }

    /* ========== RESTRICTED FUNCTIONS ========== */

    /**
    * @notice Sets the address of the Router contract.
    * @dev The address is initialized outside of the constructor to avoid a circular dependency with Router.
    * @dev This function can only be called by the OrderbookFactory owner.
    * @param _router Address of the Router contract.
    */
    function initializeContract(address _router) external onlyOwner {
        router = _router;

        emit InitializedContract(_router);
    }

    /* ========== MODIFIERS ========== */

    modifier onlyRouter() {
        require(msg.sender == router,
                "OrderbookFactory: Only the Router contract can call this function.");
        _;
    }

    /* ========== EVENTS ========== */

    event CreatedOrderbook(address syntheticAsset, bool representsBuyOrders, address orderbook);
    event InitializedContract(address routerAddress);
}