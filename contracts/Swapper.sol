// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;


import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";
import "@openzeppelin/contracts/utils/math/SafeCast.sol";
import "@openzeppelin/contracts/interfaces/IERC20.sol";
import "@openzeppelin/contracts/metatx/ERC2771Context.sol";
import "@openzeppelin/contracts/metatx/MinimalForwarder.sol";

contract Swapper is ERC2771Context {
     using SafeCast for int256;
    AggregatorV3Interface internal DAIusdpriceFeed;
    AggregatorV3Interface internal LINKusdpriceFeed;
    IERC20 DAI;
    IERC20 LINK;
mapping(address => uint) DAIliquidityProvider;
address[] DAIliquidityProviders;

mapping(address => uint) LINKliquidityProvider;
address[] LINKliquidityProviders;

constructor(MinimalForwarder forwarder)  ERC2771Context(address(forwarder)) {

   
    DAI = IERC20(0x6B175474E89094C44Da98b954EedeAC495271d0F);  //18 decimals
    LINK = IERC20(0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48); //18 decimals

DAIusdpriceFeed = AggregatorV3Interface(0x0d79df66BE487753B02D015Fb622DED7f0E9798d); 
LINKusdpriceFeed = AggregatorV3Interface(0xAb5c49580294Aff77670F839ea425f5b78ab3Ae7); 
}

function AddDAILiquidity(uint _amount)external  {
    address sender = _msgSender();
    DAI.transferFrom(sender, address(this), _amount);
    DAIliquidityProvider[_msgSender()] += _amount;
    DAIliquidityProviders.push(_msgSender());
}

function removeDAIliquidity() public {
    uint liq = DAIliquidityProvider[_msgSender()];
    require(liq != 0, "no balance");
    DAI.transferFrom(address(this), _msgSender(), liq);
}

function removeLINKliquidity() public {
    uint liq = LINKliquidityProvider[_msgSender()];
    require(liq != 0, "no balance");
    LINK.transferFrom(address(this), _msgSender(), liq);
}


function AddLINKLiquidity(uint _amount)external {
    LINK.transferFrom(_msgSender(), address(this), (_amount));
    LINKliquidityProvider[_msgSender()] += _amount;
    LINKliquidityProviders.push(_msgSender());
}


function getDAIUSDPrice() public view returns (uint) {
        ( , int price, , , ) = DAIusdpriceFeed.latestRoundData();
        return price.toUint256();
    }
function getLINKUSDPrice() public view returns (uint) {
        ( , int price, , , ) = LINKusdpriceFeed.latestRoundData();
        return (price * 1e18).toUint256();
    }

function swapLINKforDai(uint LINK_amount) public {
    address receiver = _msgSender();
    LINK.transferFrom(_msgSender(), address(this), LINK_amount);
    uint LINKPrice = getLINKUSDPrice();
    uint daiPrice = getDAIUSDPrice();
    uint swappedAmount = (LINKPrice * LINK_amount)/daiPrice ;
    uint balance = DAI.balanceOf(address(this));
    require(balance >= swappedAmount, "not enough liquidity, check back");
    DAI.transferFrom(address(this), receiver, swappedAmount);

}

function swapDAIforLINK(uint dai_amount) external {
    address receiver = _msgSender();
    DAI.transferFrom(_msgSender(), address(this), dai_amount);
    uint LINKPrice = getLINKUSDPrice();
    uint daiPrice = getDAIUSDPrice();
    uint swappedAmount = (daiPrice * dai_amount)/LINKPrice;
    uint balance = LINK.balanceOf(address(this));
    require(balance >= swappedAmount, "not enough liquidity, check back");
    LINK.transferFrom(address(this), receiver, swappedAmount);
}



}