/*
 *  The Nuka Token contract complies with the ERC20 standard (see https://github.com/ethereum/EIPs/issues/20).
 *  All tokens not being sold during the crowdsale but the reserved token
 *  for tournaments future financing are burned.
 */
 
pragma solidity ^0.4.20;

library SafeMath {
    function mul(uint256 a, uint256 b) internal returns (uint256) {
        uint256 c = a * b;
        assert(a == 0 || c / a == b);
        return c;
    }

    function sub(uint256 a, uint256 b) internal returns (uint256) {
        assert(b <= a);
        return a - b;
    }

    function add(uint256 a, uint256 b) internal returns (uint256) {
        uint256 c = a + b;
        assert(c >= a && c >= b);
        return c;
    }
}

contract NukaToken {
    using SafeMath for uint256;
	
    // Public variables of the token
    string constant public standard = "ERC20";
    string constant public name = "Nuka tokens";
    string constant public symbol = "NKT";
    uint8 constant public decimals = 18;
	
    uint _totalSupply = 0;
	uint _totalContribution = 0;
    uint _totalBonusTokensIssued = 0;
	
	uint _price = 70000;
	uint _priceBonus = 700;
	uint _percentBonus = 100;
	uint _paymentCount = 0;
	
    address public ownerAddr;
    address public etherAddress;
	bool public purchasingAllowed = true;

    // Array with all balances
    mapping (address => uint256) balances;
    mapping (address => mapping (address => uint256)) allowed;

    // Public event on the blockchain that will notify clients
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed _owner, address indexed spender, uint256 value);

    // Initializes contract with initial supply tokens to the creator of the contract
    function NukaToken(address _ownerAddr) {
        ownerAddr = msg.sender;//_ownerAddr;
        etherAddress = _ownerAddr;
    }

    // Get the total token supply
    function totalSupply() constant returns (uint256 totalSupply) {
        return _totalSupply;
    }
	
    // What is the balance of a particular account?
    function balanceOf(address _owner) constant returns (uint256 balance) {
        return balances[_owner];
    }
	
    // Send some of your tokens to a given address
    function transfer(address _to, uint256 _value) returns(bool success) {
		require(
			balances[msg.sender] >= _value 
			&& _value > 0
		);
        balances[msg.sender] = balances[msg.sender].sub(_value); // Subtract from the sender
        balances[_to] = balances[_to].add(_value); // Add the same to the recipient
        Transfer(msg.sender, _to, _value); // Notify anyone listening that this transfer took place
        return true;
    }
	
    // A contract or person attempts to get the tokens of somebody else.
    // This is only allowed if the token holder approved.
    function transferFrom(address _from, address _to, uint256 _value) returns (bool success) {
		require(
			allowed[_from][msg.sender] >= _value 
			&& balances[_from] >= _value 
			&& _value > 0
		);
        var _allowed = allowed[_from][msg.sender];
        balances[_from] = balances[_from].sub(_value); // Subtract from the sender
        balances[_to] = balances[_to].add(_value); // Add the same to the recipient
        allowed[_from][msg.sender] = _allowed.sub(_value);
        Transfer(_from, _to, _value);
        return true;
    }
	
    // Approve the passed address to spend the specified amount of tokens
    // on behalf of msg.sender.
    function approve(address _spender, uint256 _value) returns (bool success) {
        //require((_value == 0) || (allowed[msg.sender][_spender] == 0));
        allowed[msg.sender][_spender] = _value;
        Approval(msg.sender, _spender, _value);
        return true;
    }

    // Returns the amount which _spender is still allowed to withdraw from _owner
    function allowance(address _owner, address _spender) constant returns (uint256 remaining) {
        return allowed[_owner][_spender];
    }
	
	// Enable the crowdsale
	function enablePurchasing() {
        if (msg.sender == ownerAddr) { 
			purchasingAllowed = true;
		}
    }

	// Disable the crowdsale
    function disablePurchasing() {
        if (msg.sender == ownerAddr) {
			purchasingAllowed = false;
		} 
    }
	
	//Public stats
	function getStats() constant returns (uint256, uint256, uint256, bool) {
        return (_totalContribution, _totalSupply, _totalBonusTokensIssued, purchasingAllowed);
    }
	
	function() payable {		
        if (msg.sender != etherAddress) // Do not trigger exchange if the wallet is returning the funds
			require(purchasingAllowed);
			require(msg.value > 0);
            exchange();
    }
	
	function exchange() payable {
        uint256 _amount = msg.value;
        uint256 _numTokens = _amount.mul(_price);
		uint256 _numBonusTokens = 0;
		
		if(_percentBonus > 0){
		    _numBonusTokens = calculateBonus(_amount);
		}
		_numTokens = _numTokens.add(_numBonusTokens);
		
        etherAddress.transfer(msg.value);
        balances[msg.sender] = balances[msg.sender].add(_numTokens);
        
        // Calculate how much raised and tokens sold
        _totalContribution = _totalContribution.add(_amount);
		_totalSupply = _totalSupply.add(_numTokens);
		_totalBonusTokensIssued = _totalBonusTokensIssued.add(_numBonusTokens);

        Transfer(address(this), msg.sender, _numTokens);
    }
	
	//Calculate Bonus Token to add at _numTokens
	function calculateBonus(uint256 _value) returns (uint256){
		if(_paymentCount < 5){
			_paymentCount = _paymentCount.add(1);
		}else{
			_paymentCount = 0;
			_percentBonus = _percentBonus.sub(1);
		}
		
		uint256 _totalEth = _value.mul(_priceBonus);
		uint256 _totalTokenBonus = _totalEth.mul(_percentBonus);
		
		return _totalTokenBonus;
	}
}