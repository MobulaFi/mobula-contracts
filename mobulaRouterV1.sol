// SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;

/*
  Mobula Router v1

  Website:  https://mobula.fi/
  Telegram: https://t.me/MobulaFi
*/


interface IPair {
    function balanceOf(address owner) external view returns (uint);
    function transfer(address to, uint value) external returns (bool);
    function transferFrom(address from, address to, uint value) external returns (bool);

    event Swap(
        address indexed sender,
        uint amount0In,
        uint amount1In,
        uint amount0Out,
        uint amount1Out,
        address indexed to
    );

    function factory() external view returns (address);
    function token0() external view returns (address);
    function getReserves() external view returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);
    function swap(uint amount0Out, uint amount1Out, address to, bytes calldata data) external;

}

interface IFactory {
    function getPair(address tokenA, address tokenB) external view returns (address pair);

}

interface IERC20 {
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address _owner, address spender) external view returns (uint256);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
}

interface IWETH {
    function deposit() external payable;
    function transfer(address to, uint value) external returns (bool);
    function withdraw(uint) external;
}

contract MobulaRouterV1 {

    mapping (address => bool) admins;
    address public ETH = 0x0d500B1d8E8eF31E21C99d1Db9A6444d3ADf1270;
    address mobulaTreasury = 0x7189384C1a46DBc5265bd0bd040E06F76761Ef24;

    //address public ETH = 0xbb4CdB9CBd36B01bD1cBaEBF2De08d9173bc095c; BSC


    constructor() {
        admins[msg.sender] = true;
    }

    event swap(address indexed from);

    IERC20 WETH = IERC20(ETH);
    uint256 fee = 9970;
    uint256 mobulaFee = 10;

    receive() external payable {}
    fallback() external payable {}

    function setAdmin(address _admin, bool _status) public {
        require(admins[msg.sender]);
        admins[_admin] = _status;
    }

    function takeMobulaFeeETH(uint256 amountBeforeFee) internal returns (uint256) {

        uint256 feeAmount = amountBeforeFee * mobulaFee / 10000;
        IERC20(WETH).transfer(mobulaTreasury, feeAmount);
        return amountBeforeFee - feeAmount;

    }

    function takeMobulaFeeToken(address tokenAddr,uint256 amountBeforeFee) internal returns (uint256) {

        uint256 feeAmount = amountBeforeFee * mobulaFee / 10000;
        IERC20(tokenAddr).transferFrom(msg.sender,mobulaTreasury, feeAmount);
        return amountBeforeFee - feeAmount;

    }

    function wrapEther(uint256 amount) external payable {

        require(msg.value == amount);
        IWETH(ETH).deposit{value: amount}();
        WETH.transfer(msg.sender, amount);
    }

    function unwrapEther(uint256 amount) external payable {

        require(WETH.allowance(msg.sender, address(this)) >= amount, "Allowance too low");

        WETH.transferFrom(msg.sender,address(this),amount);
        IWETH(ETH).withdraw(amount);
        (bool sent,) = payable(address(msg.sender)).call{value: amount}("");
        require(sent, "Failed to send Ether back");
    }


    function mobulaSwap(address factory, uint[] memory amounts,address[] memory path,address to) internal {

        for(uint256 i = 0; i < path.length - 1; i++){
        
            IPair pair = IPair(IFactory(factory).getPair(path[i],path[i+1]));

            uint256 amountInput;
            {
                (uint256 reserve0,uint256 reserve1,) = pair.getReserves();
                (uint256 reserveInput,) = pair.token0() == path[i] ? (reserve0, reserve1) : (reserve1, reserve0);
                amountInput = IERC20(path[i]).balanceOf(address(pair)) - reserveInput;
            }
            (uint256 amount0Out, uint256 amount1Out) = pair.token0() == path[i] ? (uint256(0), amounts[i + 1]) : (amounts[i + 1], uint256(0));
            address localTo = i < path.length - 2 ? IFactory(factory).getPair(path[i+1],path[i+2]) : to;
            pair.swap(amount0Out, amount1Out, localTo, new bytes(0));

        }

    }

    function mobulaSwapSupportingFee(address factory,address[] memory path,address to) internal {

        for(uint256 i = 0; i < path.length - 1; i++){
        
            IPair pair = IPair(IFactory(factory).getPair(path[i],path[i+1]));
            uint amountInput;
            uint amountOutput;
            {
            (uint reserve0, uint reserve1,) = pair.getReserves();
            (uint reserveInput, uint reserveOutput) = pair.token0() == path[i] ? (reserve0, reserve1) : (reserve1, reserve0);
            amountInput = IERC20(path[i]).balanceOf(address(pair)) - reserveInput;
            amountOutput = getAmountOut(amountInput, reserveInput, reserveOutput);
            }
            (uint amount0Out, uint amount1Out) = pair.token0() == path[i] ? (uint(0), amountOutput) : (amountOutput, uint(0));
            address localTo = i < path.length - 2 ? IFactory(factory).getPair(path[i+1],path[i+2]) : to;
            pair.swap(amount0Out, amount1Out, localTo, new bytes(0));

        }

    }

    function multiSwapExactTokensForTokensSupportingFee(
        address factory,
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint256 newFee,
        uint deadline
    ) external {
        require(block.timestamp <= deadline, "MobulaRouter: EXPIRED");
        fee = newFee;
        uint256 swapAmountIn = takeMobulaFeeToken(path[0],amountIn);
        uint256 userBalanceBefore = IERC20(path[path.length - 1]).balanceOf(to);
        IERC20(path[0]).transferFrom(msg.sender,IFactory(factory).getPair(path[0],path[1]),swapAmountIn);

        mobulaSwapSupportingFee(factory,path, to);
        require(IERC20(path[path.length - 1]).balanceOf(to) - userBalanceBefore >= amountOutMin, "MobulaRouter: Slippage too low");
        emit swap(msg.sender);
    }

    function multiSwapExactETHForTokensSupportingFee(
        address factory,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint256 newFee,
        uint deadline
    ) external payable{
        require(block.timestamp <= deadline, "MobulaRouter: EXPIRED");
        fee = newFee;
        uint256 userBalanceBefore = IERC20(path[path.length - 1]).balanceOf(to);
        IWETH(ETH).deposit{value: msg.value}();
        uint256 swapAmountIn = takeMobulaFeeETH(msg.value);
        WETH.transfer(IFactory(factory).getPair(path[0],path[1]),swapAmountIn);

        mobulaSwapSupportingFee(factory,path, to);
        require(IERC20(path[path.length - 1]).balanceOf(to) - userBalanceBefore >= amountOutMin, "MobulaRouter: Slippage too low.");
        emit swap(msg.sender);
    }

    function multiSwapExactTokensForETHSupportingFee(address factory,uint256 amountIn,uint256 amountOutMin,address[] calldata path,address to, uint256 newFee,uint256 deadline) external payable {

        require(block.timestamp <= deadline, "MobulaRouter: EXPIRED");
        fee = newFee;

        uint256 swapAmountIn = takeMobulaFeeToken(path[0],amountIn);
        uint256 userBalanceBefore = to.balance;
        uint256 contractBalanceBefore = address(this).balance;

        require(IERC20(path[0]).allowance(msg.sender, address(this)) >= amountIn, "MobulaRouter: Allowance too low.");

        IERC20(path[0]).transferFrom(msg.sender,IFactory(factory).getPair(path[0],path[1]),swapAmountIn);
        mobulaSwapSupportingFee(factory,path,address(this));


        IWETH(ETH).withdraw(WETH.balanceOf(address(this)));
        (bool sent,) = payable(to).call{value: address(this).balance - contractBalanceBefore}("");
        require(sent, "MobulaRouter: Failed to send Ether back");

        require(to.balance - userBalanceBefore >= amountOutMin, "MobulaRouter: Slippage too low.");
        emit swap(msg.sender);
    }

    function multiSwapExactTokensForTokens(address factory,uint256 amountIn, uint256 amountOutMin, address[] calldata path,address to, uint256 newFee,uint256 deadline) external {
        require(block.timestamp <= deadline, "MobulaRouter: EXPIRED");
        fee = newFee;

        require(IERC20(path[0]).allowance(msg.sender, address(this)) >= amountIn, "MobulaRouter: Allowance too low.");

        uint256 swapAmountIn = takeMobulaFeeToken(path[0],amountIn);
        uint256 userBalanceBefore = IERC20(path[path.length - 1]).balanceOf(to);

        uint[] memory amounts = getAmountsOut(factory,swapAmountIn,path);
        IERC20(path[0]).transferFrom(msg.sender,IFactory(factory).getPair(path[0],path[1]),amounts[0]);
        mobulaSwap(factory,amounts,path,to);

        require(IERC20(path[path.length - 1]).balanceOf(to) - userBalanceBefore >= amountOutMin, "MobulaRouter: Slippage too low.");
        emit swap(msg.sender);
    }

    function multiSwapTokensForExactTokens(address factory,uint256 amountOut,uint256 amountInMax, address[] calldata path, address to, uint256 newFee,uint256 deadline) external {
        require(block.timestamp <= deadline, "MobulaRouter: EXPIRED");
        fee = newFee;
        
        uint[] memory amounts = getAmountsIn(factory,amountOut,path);
        uint256 _specialInput = specialInput(factory,amountOut,path);
        require(_specialInput <= amountInMax,"MobulaRouter: Slippage too low");
        require(IERC20(path[0]).allowance(msg.sender, address(this)) >= _specialInput, "MobulaRouter: Allowance too low.");
        IERC20(path[0]).transferFrom(msg.sender,mobulaTreasury,_specialInput - amounts[0]);
        
        IERC20(path[0]).transferFrom(msg.sender,IFactory(factory).getPair(path[0],path[1]),amounts[0]);
        mobulaSwap(factory,amounts,path,to);
        emit swap(msg.sender);

    }

    function multiSwapExactTokensForETH(address factory,uint256 amountIn,uint256 amountOutMin,address[] calldata path,address to, uint256 newFee,uint256 deadline) external payable {

        require(block.timestamp <= deadline, "MobulaRouter: EXPIRED");
        fee = newFee;

        uint256 swapAmountIn = takeMobulaFeeToken(path[0],amountIn);
        uint256 userBalanceBefore = to.balance;
        uint256 contractBalanceBefore = address(this).balance;

        require(IERC20(path[0]).allowance(msg.sender, address(this)) >= amountIn, "MobulaRouter: Allowance too low.");
        uint[] memory amounts = getAmountsOut(factory,swapAmountIn,path);

        IERC20(path[0]).transferFrom(msg.sender,IFactory(factory).getPair(path[0],path[1]),amounts[0]);
        mobulaSwap(factory,amounts,path,address(this));

        
        IWETH(ETH).withdraw(WETH.balanceOf(address(this)));
        (bool sent,) = payable(to).call{value: address(this).balance - contractBalanceBefore}("");
        require(sent, "MobulaRouter: Failed to send Ether back");

        require(to.balance - userBalanceBefore >= amountOutMin, "MobulaRouter: Slippage too low.");
        emit swap(msg.sender);
    }

    function multiSwapTokensForExactETH(address factory,uint256 amountOut,uint256 amountInMax,address[] calldata path,address to, uint256 newFee,uint256 deadline) external payable {

        require(block.timestamp <= deadline, "MobulaRouter: EXPIRED");
        fee = newFee;
        uint256 contractBalanceBefore = address(this).balance;
        uint[] memory amounts = getAmountsIn(factory,amountOut,path);
        uint256 _specialInput = specialInput(factory,amountOut,path);
        require(_specialInput <= amountInMax,"MobulaRouter: Slippage too low");

        require(IERC20(path[0]).allowance(msg.sender, address(this)) >= _specialInput, "MobulaRouter: Allowance too low.");

        IERC20(path[0]).transferFrom(msg.sender,mobulaTreasury,_specialInput - amounts[0]);
        IERC20(path[0]).transferFrom(msg.sender,IFactory(factory).getPair(path[0],path[1]),amounts[0]);
        mobulaSwap(factory,amounts,path,address(this));

        IWETH(ETH).withdraw(WETH.balanceOf(address(this)));
        (bool sent,) = payable(to).call{value: address(this).balance - contractBalanceBefore}("");
        require(sent, "MobulaRouter: Failed to send Ether back");
        emit swap(msg.sender);

    }

    function multiSwapExactETHForTokens(address factory,uint256 amountOutMin,address[] calldata path,address to, uint256 newFee,uint256 deadline) external payable {

        require(block.timestamp <= deadline, "MobulaRouter: EXPIRED");
        fee = newFee;
        uint256 userBalanceBefore = IERC20(path[path.length - 1]).balanceOf(to);
        IWETH(ETH).deposit{value: msg.value}();
        uint256 swapAmountIn = takeMobulaFeeETH(msg.value);
        uint[] memory amounts = getAmountsOut(factory,swapAmountIn,path);
        require(swapAmountIn >= amounts[0], "MobulaRouter: Deposited ether amount too low.");

        
        WETH.transfer(IFactory(factory).getPair(path[0],path[1]),amounts[0]);
        mobulaSwap(factory, amounts, path, to);

        
        require(IERC20(path[path.length - 1]).balanceOf(to) - userBalanceBefore >= amountOutMin, "MobulaRouter: Slippage too low.");
        
        emit swap(msg.sender);
        
        
    }

    function multiSwapETHForExactTokens(address factory, uint256 amountOut,address[] calldata path,address to, uint256 newFee,uint256 deadline) external payable {

        require(block.timestamp <= deadline, "MobulaRouter: EXPIRED");
        fee = newFee;
        uint[] memory amounts = getAmountsIn(factory,amountOut,path);
        uint256 _specialInput = specialInput(factory,amountOut,path);
        require(_specialInput <= msg.value,"MobulaRouter: Slippage too low");
        IWETH(ETH).deposit{value: _specialInput}();

        WETH.transfer(mobulaTreasury,_specialInput - amounts[0]);
        WETH.transfer(IFactory(factory).getPair(path[0],path[1]),amounts[0]);
        mobulaSwap(factory, amounts, path, to);

        if (msg.value > _specialInput){
            (bool sent,) = msg.sender.call{value:msg.value - _specialInput}("");
            require(sent, 'MobulaRouter: Failed to send Ether back');
        }
        
        emit swap(msg.sender);

    }

    function rescueETH() external payable {
        require(admins[msg.sender],"MobulaRouter: Not admin");
        (bool sent,) = payable(address(msg.sender)).call{value: address(this).balance}("");
        require(sent, "MobulaRouter: Failed to send Ether back");
    }

    function rescueERC20(address tokenAddr) external {
        require(admins[msg.sender],"MobulaRouter: Not admin");
        IERC20 token = IERC20(tokenAddr);
        token.transfer(msg.sender, token.balanceOf(address(this)));

    }


    function getAmountOut(uint amountIn,uint reserveIn, uint reserveOut) public view returns (uint amountOut) {

        uint amountInWithFee = amountIn * fee;
        uint numerator = amountInWithFee * reserveOut;
        uint denominator = reserveIn * 10000 + amountInWithFee;
        amountOut = numerator / denominator;
    }

    function getAmountIn(uint amountOut, uint reserveIn, uint reserveOut) internal view returns (uint amountIn) {
        require(amountOut > 0, 'MobulaRouter: INSUFFICIENT_OUTPUT_AMOUNT');
        require(reserveIn > 0 && reserveOut > 0, 'MobulaRouter: INSUFFICIENT_LIQUIDITY');
        uint numerator = reserveIn * amountOut * 10000;
        uint denominator = (reserveOut - amountOut) * fee;
        amountIn = (numerator / denominator) + 1;
    }

    function getAmountsIn(address factory, uint amountOut, address[] memory path) public view returns (uint[] memory amounts) {
        require(path.length >= 2, 'MobulaRouter: INVALID_PATH');
        amounts = new uint[](path.length);
        amounts[amounts.length - 1] = amountOut;
        for (uint i = path.length - 1; i > 0; i--) {
            (uint reserveIn, uint reserveOut) = getReserves(factory, path[i - 1], path[i]);
            amounts[i - 1] = getAmountIn(amounts[i], reserveIn, reserveOut);
        }
    }

    function specialInput(address factory, uint amountOut, address[] memory path) public view returns (uint256) {
        require(path.length >= 2, 'MobulaRouter: INVALID_PATH');
        uint[] memory amounts = new uint[](path.length);
        amounts[amounts.length - 1] = amountOut;
        for (uint i = path.length - 1; i > 0; i--) {
            (uint reserveIn, uint reserveOut) = getReserves(factory, path[i - 1], path[i]);
            amounts[i - 1] = i == 1 ? getAmountIn(amounts[i], reserveIn, reserveOut) + getAmountIn(amounts[i], reserveIn, reserveOut) * mobulaFee / 10000 : getAmountIn(amounts[i], reserveIn, reserveOut);
        }

        return amounts[0];
    }

    function getAmountsOut(address factory, uint amountIn, address[] memory path) public view returns (uint[] memory amounts) {
        require(path.length >= 2, 'MobulaRouter: INVALID_PATH');
        amounts = new uint[](path.length);
        amounts[0] = amountIn;
        for (uint i; i < path.length - 1; i++) {
            (uint reserveIn, uint reserveOut) = getReserves(factory, path[i], path[i + 1]);
            amounts[i + 1] = getAmountOut(amounts[i], reserveIn, reserveOut);
        }
    }

    function getReserves(address factory, address tokenA, address tokenB) internal view returns (uint reserveA, uint reserveB) {
        (address token0,) = sortTokens(tokenA, tokenB);
        (uint reserve0, uint reserve1,) = IPair(IFactory(factory).getPair(tokenA,tokenB)).getReserves();
        (reserveA, reserveB) = tokenA == token0 ? (reserve0, reserve1) : (reserve1, reserve0);
    }

    function sortTokens(address tokenA, address tokenB) internal pure returns (address token0, address token1) {
        require(tokenA != tokenB, 'MobulaRouter: IDENTICAL_ADDRESSES');
        (token0, token1) = tokenA < tokenB ? (tokenA, tokenB) : (tokenB, tokenA);
        require(token0 != address(0), 'MobulaRouter: ZERO_ADDRESS');
    }

}