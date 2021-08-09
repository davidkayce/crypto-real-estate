#
#  Panoramix v4 Oct 2019 
#  Decompiled source of 0x1d9a20E7E5a6Dd07ed9352555324F17940787C81
# 
#  Let's make the world open source 
# 

def storage:
  balanceOf is mapping of uint256 at storage 0
  allowance is mapping of uint256 at storage 1
  totalSupply is uint256 at storage 2
  name is array of struct at storage 3
  symbol is array of struct at storage 4
  owner is addr at storage 5 offset 8
  decimals is uint8 at storage 5
  heldOf is mapping of uint256 at storage 6

def name() payable: 
  return name[0 len name.length].field_0

def totalSupply() payable: 
  return totalSupply

def decimals() payable: 
  return decimals

def balanceOf(address _owner) payable: 
  require calldata.size - 4 >= 32
  return balanceOf[addr(_owner)]

def owner() payable: 
  return owner

def symbol() payable: 
  return symbol[0 len symbol.length].field_0

def heldOf(address _owner) payable: 
  require calldata.size - 4 >= 32
  if not _owner:
      revert with 0, 'address cannot be empty'
  return heldOf[addr(_owner)]

def allowance(address _owner, address _spender) payable: 
  require calldata.size - 4 >= 64
  return allowance[addr(_owner)][addr(_spender)]

#
#  Regular functions
#

def _fallback() payable: # default function
  stop

def isOwner() payable: 
  return (caller == owner)

def renounceOwnership() payable: 
  require caller == owner
  log OwnershipTransferred(
        address previousOwner=owner,
        address newOwner=0)
  owner = 0

def transferOwnership(address _newOwner) payable: 
  require calldata.size - 4 >= 32
  require caller == owner
  require _newOwner
  log OwnershipTransferred(
        address previousOwner=owner,
        address newOwner=_newOwner)
  owner = _newOwner

def unknownfd2d39c5(addr _param1) payable: 
  require calldata.size - 4 >= 32
  if not _param1:
      revert with 0, 'owner address cannot be empty'
  return balanceOf[addr(_param1)], heldOf[addr(_param1)]

def approve(address _spender, uint256 _value) payable: 
  require calldata.size - 4 >= 64
  require _spender
  allowance[caller][addr(_spender)] = _value
  log Approval(
        address owner=_value,
        address spender=caller,
        uint256 value=_spender)
  return 1

def burn(address _guy, uint256 _wad) payable: 
  require calldata.size - 4 >= 64
  require caller == owner
  require _guy
  require _wad <= totalSupply
  totalSupply -= _wad
  require _wad <= balanceOf[addr(_guy)]
  balanceOf[addr(_guy)] -= _wad
  log Transfer(
        address from=_wad,
        address to=_guy,
        uint256 value=0)

def decreaseAllowance(address _spender, uint256 _subtractedValue) payable: 
  require calldata.size - 4 >= 64
  require _spender
  require _subtractedValue <= allowance[caller][addr(_spender)]
  allowance[caller][addr(_spender)] -= _subtractedValue
  log Approval(
        address owner=allowance[caller][addr(_spender)],
        address spender=caller,
        uint256 value=_spender)
  return 1

def transfer(address _to, uint256 _value) payable: 
  require calldata.size - 4 >= 64
  require _to
  require _value <= balanceOf[caller]
  balanceOf[caller] -= _value
  require balanceOf[addr(_to)] + _value >= balanceOf[addr(_to)]
  balanceOf[addr(_to)] += _value
  log Transfer(
        address from=_value,
        address to=caller,
        uint256 value=_to)
  return 1

def increaseAllowance(address _spender, uint256 _addedValue) payable: 
  require calldata.size - 4 >= 64
  require _spender
  require allowance[caller][addr(_spender)] + _addedValue >= allowance[caller][addr(_spender)]
  allowance[caller][addr(_spender)] += _addedValue
  log Approval(
        address owner=allowance[caller][addr(_spender)],
        address spender=caller,
        uint256 value=_spender)
  return 1

def mint(address _to, uint256 _amount) payable: 
  require calldata.size - 4 >= 64
  require caller == owner
  require _to
  require totalSupply + _amount >= totalSupply
  totalSupply += _amount
  require balanceOf[addr(_to)] + _amount >= balanceOf[addr(_to)]
  balanceOf[addr(_to)] += _amount
  log Transfer(
        address from=_amount,
        address to=0,
        uint256 value=_to)
  return 1

def transferFrom(address _from, address _to, uint256 _value) payable: 
  require calldata.size - 4 >= 96
  require _value <= allowance[addr(_from)][caller]
  allowance[addr(_from)][caller] -= _value
  require _to
  require _value <= balanceOf[addr(_from)]
  balanceOf[addr(_from)] -= _value
  require balanceOf[addr(_to)] + _value >= balanceOf[addr(_to)]
  balanceOf[addr(_to)] += _value
  log Transfer(
        address from=_value,
        address to=_from,
        uint256 value=_to)
  log Approval(
        address owner=allowance[addr(_from)][caller],
        address spender=_from,
        uint256 value=caller)
  return 1

def hold(address _who, uint256 _quantity) payable: 
  require calldata.size - 4 >= 64
  require caller == owner
  if not _who:
      revert with 0x8c379a000000000000000000000000000000000000000000000000000000000, 
                  32,
                  34,
                  0x6c7468652074617267657420616464726573732068617320746f2062652076616c69,
                  mem[198 len 30]
  if balanceOf[addr(_who)] < _quantity:
      revert with 0x8c379a000000000000000000000000000000000000000000000000000000000, 
                  32,
                  39,
                  0x747573657220646f65736e2774206861766520656e6f75676820746f6b656e7320746f20686f6c,
                  mem[203 len 25]
  require _quantity <= balanceOf[addr(_who)]
  balanceOf[addr(_who)] -= _quantity
  require heldOf[addr(_who)] + _quantity >= heldOf[addr(_who)]
  heldOf[addr(_who)] += _quantity
  log 0x19f9e904: _quantity, _who

def unknown30e0914c(addr _param1, addr _param2, uint256 _param3) payable: 
  require calldata.size - 4 >= 96
  require caller == owner
  if not _param1:
      revert with 0, 'the from address has to be valid'
  if not _param2:
      revert with 0, 'the to address has to be valid'
  if heldOf[addr(_param1)] < _param3:
      revert with 0x8c379a000000000000000000000000000000000000000000000000000000000, 
                  32,
                  45,
                  0xfe7573657220646f65736e2774206861766520656e6f75676820696e20686f6c64696e6720746f20636f6d6d69,
                  mem[209 len 19]
  require _param3 <= heldOf[addr(_param1)]
  heldOf[addr(_param1)] -= _param3
  require balanceOf[addr(_param2)] + _param3 >= balanceOf[addr(_param2)]
  balanceOf[addr(_param2)] += _param3
  log Transfer(
        address from=_param3,
        address to=_param1,
        uint256 value=_param2)

def unknown41980d66(addr _param1, addr _param2, uint256 _param3) payable: 
  require calldata.size - 4 >= 96
  require caller == owner
  if not _param1:
      revert with 0, 'the from address has to be valid'
  if not _param2:
      revert with 0, 'the to address has to be valid'
  if balanceOf[addr(_param1)] < _param3:
      revert with 0x8c379a000000000000000000000000000000000000000000000000000000000, 
                  32,
                  46,
                  0x647573657220646f65736e2774206861766520656e6f75676820746f20737570706f727420746865207265766572,
                  mem[210 len 18]
  require _param3 <= balanceOf[addr(_param1)]
  balanceOf[addr(_param1)] -= _param3
  require heldOf[addr(_param2)] + _param3 >= heldOf[addr(_param2)]
  heldOf[addr(_param2)] += _param3
  log Transfer(
        address from=_param3,
        address to=_param1,
        uint256 value=_param2)

def release(address _address, uint256 _amount) payable: 
  require calldata.size - 4 >= 64
  require caller == owner
  if not _address:
      revert with 0x8c379a000000000000000000000000000000000000000000000000000000000, 
                  32,
                  34,
                  0x6c7468652074617267657420616464726573732068617320746f2062652076616c69,
                  mem[198 len 30]
  if heldOf[addr(_address)] < _amount:
      revert with 0x8c379a000000000000000000000000000000000000000000000000000000000, 
                  32,
                  45,
                  0x747573657220646f65736e2774206861766520656e6f75676820696e20686f6c64696e6720746f2063616e6365,
                  mem[209 len 19]
  require _amount <= heldOf[addr(_address)]
  heldOf[addr(_address)] -= _amount
  require balanceOf[addr(_address)] + _amount >= balanceOf[addr(_address)]
  balanceOf[addr(_address)] += _amount
  log Released(
        address owner=_amount,
        uint256 amount=_address)

def details() payable: 
  mem[96] = name.length
  mem[0] = 3
  mem[128] = uint256(name.field_0)
  idx = 128
  s = 0
  while name.length + 96 > idx:
      mem[idx + 32] = name[s].field_256
      idx = idx + 32
      s = s + 1
      continue 
  mem[64] = ceil32(name.length) + ceil32(symbol.length) + 160
  mem[ceil32(name.length) + 128] = symbol.length
  mem[ceil32(name.length) + 160] = uint256(symbol.field_0)
  idx = ceil32(name.length) + 160
  s = 0
  while ceil32(name.length) + symbol.length + 128 > idx:
      mem[idx + 32] = symbol[s].field_256
      idx = idx + 32
      s = s + 1
      continue 
  mem[ceil32(name.length) + ceil32(symbol.length) + 224] = decimals
  mem[ceil32(name.length) + ceil32(symbol.length) + 256] = totalSupply
  mem[ceil32(name.length) + ceil32(symbol.length) + 160] = 128
  mem[ceil32(name.length) + ceil32(symbol.length) + 288] = name.length
  mem[ceil32(name.length) + ceil32(symbol.length) + 320 len ceil32(name.length)] = mem[128 len ceil32(name.length)]
  mem[ceil32(name.length) + ceil32(symbol.length) + 192] = name.length + 160
  mem[name.length + ceil32(name.length) + ceil32(symbol.length) + 320] = symbol.length
  mem[name.length + ceil32(name.length) + ceil32(symbol.length) + 352 len ceil32(symbol.length)] = mem[ceil32(name.length) + 160 len ceil32(symbol.length)]
  if not symbol.length % 32:
      return Array(len=name.length, data=mem[128 len ceil32(name.length)], mem[(2 * ceil32(name.length)) + ceil32(symbol.length) + 320 len symbol.length + name.length + -ceil32(name.length) + 32]), 
             name.length + 160,
             decimals,
             totalSupply
  mem[floor32(symbol.length) + name.length + ceil32(name.length) + ceil32(symbol.length) + 352] = mem[floor32(symbol.length) + name.length + ceil32(name.length) + ceil32(symbol.length) + -symbol.length % 32 + 384 len symbol.length % 32]
  return Array(len=name.length, data=mem[128 len ceil32(name.length)], mem[(2 * ceil32(name.length)) + ceil32(symbol.length) + 320 len floor32(symbol.length) + name.length + -ceil32(name.length) + 64]), 
         name.length + 160,
         decimals,
         totalSupply