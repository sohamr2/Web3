pragma solidity ^0.8.0;

contract ProvenanceTracking {

  struct OrderDetail{
    address prevOwner;
    address newOwner;
    uint price;
  }

  struct OrderLedger{
    OrderDetail[] orderdetails;
  }


  struct User{
    string firstname;
    string lastname;
    string desc; 
    mapping(uint256 => uint) hold;
    uint[] productIds; 
  }


  
  mapping(address => User) public users; 

  // Struct to store the details of a luxury good
  struct LuxuryGood {
    uint256 productId;
    string url;
    string name;
    address manufacturer;
    mapping(uint => OrderDetail[]) ledgers; 
    uint totalSupply; 
  }

  mapping(uint256 => LuxuryGood) public luxuryGoods;

  uint[] public keysluxuryGoods;

  address[] public manufacturers; 
  
  
  function addManufacturer(address ad) public{
    manufacturers.push(ad);
  }

  struct BuyItem{
    uint256 productId;
    string url;
    string name;
    address manufacturer;
    string desc; 
    uint price;
  }

  struct SellItem{
    uint256 productId;
    string url;
    string name;
    address manufacturer;
    uint quantity; 
  }

  function viewInventory(address sender) public view returns(SellItem[] memory){
    uint maxSize = 0;
    for(uint i = 0 ; i < keysluxuryGoods.length ; i++){
      if(users[sender].hold[keysluxuryGoods[i]] > 0){
        maxSize += 1;
      }
    }
    uint index = 0;
    SellItem[] memory res = new SellItem[](maxSize);
    for(uint i = 0 ; i < keysluxuryGoods.length ; i++){
      LuxuryGood storage good = luxuryGoods[keysluxuryGoods[i]];
      if(users[sender].hold[keysluxuryGoods[i]] > 0){
        res[index] = SellItem(keysluxuryGoods[i],good.url,good.name,good.manufacturer,users[sender].hold[good.productId]);
        index += 1;
      }
    }
    return res;
  }

  // Function to add a new luxury good to the blockchainx
  function createByManufacturer(uint256 productId,uint256 quantity, string memory url ,string memory name, address manufacturer) public {
    bool flag = false;

    for(uint i = 0 ; i < manufacturers.length; i++){
      if(manufacturers[i] == manufacturer){
        flag = true;
      }
      break;
    }
    require(flag == true , "Manufacturer is not authorized ; ");

    LuxuryGood storage newGood = luxuryGoods[productId];
    newGood.productId = productId;
    newGood.url = url;
    newGood.name = name;
    newGood.manufacturer = manufacturer;
    newGood.totalSupply += quantity; 
    User storage user = users[manufacturer];
    if(user.hold[productId] != 0){
      for(uint i = user.hold[productId] ; i < user.hold[productId] + quantity ; i++){
        newGood.ledgers[i].push(OrderDetail(manufacturer,manufacturer,0));
      }
      user.hold[productId] = user.hold[productId] + quantity;
    }
    else{
      user.hold[productId] = quantity;
      for(uint i = 0 ; i < user.hold[productId] ; i++){
        newGood.ledgers[i].push(OrderDetail(manufacturer,manufacturer,0));
      }
      keysluxuryGoods.push(productId);
    }
  
  }


  function addToSell(uint256 productId, uint256 quantity,uint price) public{
    require(users[msg.sender].hold[productId] >= quantity , "You have insufficient funds to proceed with the transaction ! ");
    LuxuryGood storage good = luxuryGoods[productId];
    uint counter = 0; 
    for(uint i= 0 ; i < good.totalSupply ; i++ ){
      if(counter > quantity){
        break;
      }
      OrderDetail[] memory od = good.ledgers[i];
      if(od[od.length - 1].newOwner == msg.sender){
        good.ledgers[i].push(OrderDetail(msg.sender,0x0000000000000000000000000000000000000000,price));
        counter++;
      }
    }
    users[msg.sender].hold[productId] -= quantity;
  }


  function viewStock() public view returns (BuyItem[] memory) {
    uint itemCount = 0;
    for (uint i = 0; i < keysluxuryGoods.length; i++) {
        LuxuryGood storage good = luxuryGoods[keysluxuryGoods[i]];
        uint qty = good.totalSupply;
        for (uint j = 0; j < qty; j++) {
            OrderDetail[] memory od = good.ledgers[j];
            if (od[od.length - 1].newOwner == address(0)) {
                itemCount++;
            }
        }
    }

    BuyItem[] memory res = new BuyItem[](itemCount);
    itemCount = 0;
    for (uint i = 0; i < keysluxuryGoods.length; i++) {
        LuxuryGood storage good = luxuryGoods[keysluxuryGoods[i]];
        uint qty = good.totalSupply;
        for (uint j = 0; j < qty; j++) {
            OrderDetail[] memory od = good.ledgers[j];
            if (od[od.length - 1].newOwner == address(0)) {
                res[itemCount] = BuyItem(good.productId, good.url, good.name, od[od.length - 1].prevOwner, users[od[od.length - 1].prevOwner].desc, od[od.length - 1].price);
                itemCount++;
            }
        }
    }

    return res;
}


  function buyone(uint productId, uint priceInWei) public payable {
    require(msg.value >= priceInWei, "Not enough funds");

    LuxuryGood storage good = luxuryGoods[productId];
    for (uint i = 0; i < good.totalSupply; i++) {
        OrderDetail[] memory od = good.ledgers[i];
        if (od[od.length - 1].price == priceInWei && od[od.length - 1].newOwner == address(0)) {
            good.ledgers[i].push(OrderDetail(od[od.length-1].prevOwner, msg.sender, priceInWei));
            address payable prev = payable(od[od.length-2].prevOwner);
            prev.transfer(priceInWei);
            users[msg.sender].hold[productId] += 1;
            break;
        }
    }
  }

}
