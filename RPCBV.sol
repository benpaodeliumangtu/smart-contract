pragma solidity ^0.4.26;

contract RPCBV {
    address sysOperator = 0xca35b7d915458ef540ade6068dfe2f44e8fa733c;
    uint endTime = 1700000000;
    address[] userAddress;
    uint[] userPrice;
    uint[] demand;
    address[] genAddress;
    uint[] genPrice;
    uint[] supply;
    uint refPrice;
    uint[] userQuantity;
    uint[] genQuantity;
    uint[] userPayment;
    uint[] genIncome;

    function userBid(uint _userPrice, uint _demand) public {
        require(now <= endTime);
        userAddress.push(msg.sender);
        userPrice.push(_userPrice);
        demand.push(_demand);
    }
    
    function genBid(uint _genPrice, uint _supply) public {
        require(now <= endTime);
        genAddress.push(msg.sender);
        genPrice.push(_genPrice);
        supply.push(_supply);
    }
    
    function sort() public {
        require(msg.sender == sysOperator);
        uint userLen = demand.length;
        uint genLen = supply.length;
        address temp1;
        uint temp2;
        uint temp3;
        uint i;
        uint j;
        for(i = 0; i < userLen - 1; i++) {
            for(j = i + 1; j < userLen; j++) {
                if(userPrice[i] < userPrice[j]) {
                    temp1 = userAddress[i];
                    temp2 = userPrice[i];
                    temp3 = demand[i];
                    userAddress[i] = userAddress[j];
                    userPrice[i] = userPrice[j];
                    demand[i] = demand[j];
                    userAddress[j] = temp1;
                    userPrice[j] = temp2;
                    demand[j] = temp3;
                }
            }
        }
        for(i = 0; i < genLen - 1; i++) {
            for(j = i + 1; j < genLen; j++) {
                if(genPrice[i] > genPrice[j]) {
                    temp1 = genAddress[i];
                    temp2 = genPrice[i];
                    temp3 = supply[i];
                    genAddress[i] = genAddress[j];
                    genPrice[i] = genPrice[j];
                    supply[i] = supply[j];
                    genAddress[j] = temp1;
                    genPrice[j] = temp2;
                    supply[j] = temp3;
                }
            }
        }
    }
    
    function setRefPrice(uint _refPrice) public {
        require(msg.sender == sysOperator);
        refPrice = _refPrice;
        uint userLen = demand.length;
        uint genLen = supply.length;
        for(uint i = 0; i < userLen; i++) {
            if(userPrice[i] < refPrice) {
                demand[i] = 0;
            }
        }
        for(uint j = 0; j < genLen; j++) {
            if(genPrice[j] > refPrice) {
                supply[j] = 0;
            }
        }
    }
    
    function clearing() public {
        require(msg.sender == sysOperator);
        uint userLen = demand.length;
        uint genLen = supply.length;
        uint[] memory demand1 = new uint[](userLen);
        uint[] memory supply1 = new uint[](genLen);
        uint min;
        for(uint i = 0; i < userLen; i++) {
            demand1[i] = demand[i];
            userQuantity.push(0);
        }
        for(uint j = 0; j < genLen; j++) {
            supply1[j] = supply[j];
            genQuantity.push(0);
        }
        for(i = 0; i < userLen; i++) {
            for(j = 0; j < genLen; j++){
                if(userPrice[i] >= genPrice[j]) {
                    min = demand1[i];
                    if(supply1[j] < demand1[i]) {
                        min = supply1[j];
                    }
                    demand1[i] -= min;
                    supply1[j] -= min;
                    userQuantity[i] += min;
                    genQuantity[j] += min;
                }
            }
        }
    }
    
    function userSettlement() public {
        require(msg.sender == sysOperator);
        uint userLen = demand.length;
        uint genLen = supply.length;
        uint[] memory genPrice1 = new uint[](genLen);
        uint[] memory demand1 = new uint[](userLen);
        uint[] memory supply1 = new uint[](genLen);
        uint[] memory userQuantity1 = new uint[](userLen);
        uint[] memory genQuantity1 = new uint[](genLen);
        uint min;
        uint sw = 0;
        uint sw1;
        for(uint i = 0; i < userLen; i++) {
            sw += userPrice[i] * userQuantity[i];
        }
        for(uint j = 0; j < genLen; j++) {
            sw -= refPrice * genQuantity[j];
        }
        for(j = 0; j < genLen; j++) {
            if(genPrice[j] <= refPrice) {
                genPrice1[j] = refPrice;
            }
            else {
                genPrice1[j] = genPrice[j];
            }
        }
        for(uint k = 0; k < userLen; k++) {
            userPayment.push(0);
        }
        for(k = 0; k < userLen; k++) {
            if(genQuantity[k] == 0) {
                break;
            }
            for(i = 0; i < userLen; i++) {
                userQuantity1[i] = 0;
            }
            for(j = 0; j < genLen; j++) {
                genQuantity1[j] = 0;
            }
            for(i = 0; i < userLen; i++) {
            demand1[i] = demand[i];
            }
            for(j = 0; j < genLen; j++) {
            supply1[j] = supply[j];
            }
            demand1[k] = 0;
            for(i = 0; i < userLen; i++) {
                for(j = 0; j < genLen; j++){
                    if(userPrice[i] >= genPrice1[j]) {
                        min = demand1[i];
                        if(supply1[j] < demand1[i]) {
                            min = supply1[j];
                        }
                        demand1[i] -= min;
                        supply1[j] -= min;
                        userQuantity1[i] += min;
                        genQuantity1[j] += min;
                    }
                }
            }
            sw1 = 0;
            for(i = 0; i < userLen; i++) {
                sw1 += userPrice[i] * userQuantity1[i];
            }
            for(j = 0; j < genLen; j++) {
                sw1 -= refPrice * genQuantity1[j];
            }
            userPayment[k] = userPrice[k] * userQuantity[k] - sw + sw1;
        }
    }
    
    function gensettlement() public {
        require(msg.sender == sysOperator);
        uint userLen = demand.length;
        uint genLen = supply.length;
        uint[] memory userPrice1 = new uint[](userLen);
        uint[] memory demand1 = new uint[](userLen);
        uint[] memory supply1 = new uint[](genLen);
        uint[] memory userQuantity1 = new uint[](userLen);
        uint[] memory genQuantity1 = new uint[](genLen);
        uint min;
        uint sw = 0;
        uint sw1;        
        for(uint i = 0; i < userLen; i++) {
            sw += refPrice * userQuantity[i];
        }
        for(uint j = 0; j < genLen; j++) {
            sw -= genPrice[j] * genQuantity[j];
        }
        for(i = 0; i < userLen; i++) {
            if(userPrice[i] >= refPrice) {
                userPrice1[i] = refPrice;
            }
            else {
                userPrice1[i] = userPrice[i];
            }
        }
        for(uint k = 0; k < genLen; k++) {
            genIncome.push(0);
        }
        for(k = 0; k < genLen; k++) {
            if(genQuantity[k] == 0) {
                break;
            }
            for(i = 0; i < userLen; i++) {
                userQuantity1[i] = 0;
            }
            for(j = 0; j < genLen; j++) {
                genQuantity1[j] = 0;
            }
            for(i = 0; i < userLen; i++) {
            demand1[i] = demand[i];
            }
            for(j = 0; j < genLen; j++) {
            supply1[j] = supply[j];
            }
            supply1[k] = 0;
            for(i = 0; i < userLen; i++) {
                for(j = 0; j < genLen; j++){
                    if(userPrice1[i] >= genPrice[j]) {
                        min = demand1[i];
                        if(supply1[j] < demand1[i]) {
                            min = supply1[j];
                        }
                        demand1[i] -= min;
                        supply1[j] -= min;
                        userQuantity1[i] += min;
                        genQuantity1[j] += min;
                    }
                }
            }
            sw1 = 0;
            for(i = 0; i < userLen; i++) {
                sw1 += refPrice * userQuantity1[i];
            }
            for(j = 0; j < genLen; j++) {
                sw1 -= genPrice[j] * genQuantity1[j];
            }
            genIncome[k] = genPrice[k] * genQuantity[k] + sw - sw1;
        }
    }
    
    function query(address _address) public view returns(uint, uint) {
        uint userLen = demand.length;
        uint genLen = supply.length;
        for(uint i = 0; i < userLen; i++) {
            if (userAddress[i] == _address)
            return(userQuantity[i], userPayment[i]);
        }
        for(uint j = 0; j < genLen; j++) {
            if(genAddress[j] == _address)
            return(genQuantity[j], genIncome[j]);
        }
    }
    
    function payment(address _address) public payable {
        _address.transfer(msg.value);
    }
    
}
