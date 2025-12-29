///|
/// EIP-2930 Access List 交易实现
/// 交易类型标识: 0x01
/// 参考: https://eips.ethereum.org/EIP-2930

///|
/// Storage Key 类型（32 字节）
pub type StorageKey = FixedArray[Byte] // 32 bytes

///|
/// Access Tuple 结构
/// 用于指定交易访问的地址和存储槽
pub struct AccessTuple {
  address : Address  // 20 bytes
  storage_keys : Array[StorageKey]  // 每个 32 bytes，表示存储槽的哈希
} derive(Eq, Show)

///|
/// 创建 Access Tuple
pub fn AccessTuple::new(
  address : Address,
  storage_keys : Array[StorageKey],
) -> AccessTuple {
  { address, storage_keys }
}

///|
/// EIP-2930 Access List 交易结构
/// 
/// RLP 编码格式：
/// 0x01 || RLP([chainId, nonce, gasPrice, gasLimit, to, value, data, accessList, signatureYParity, signatureR, signatureS])
/// 
/// 其中：
/// - signatureYParity: v 值，0 或 1
/// - signatureR, signatureS: 32 字节签名分量
pub struct AccessListTransaction {
  chain_id : UInt64
  nonce : UInt64
  gas_price : UInt64
  gas_limit : UInt64
  to : Option[Address]  // None 表示合约创建
  value : UInt64
  data : FixedArray[Byte]
  access_list : Array[AccessTuple]
  v : UInt64  // 恢复 ID: 0 或 1
  r : FixedArray[Byte]  // 32 bytes
  s : FixedArray[Byte]  // 32 bytes
} derive(Eq, Show)

///|
/// 创建未签名的 Access List 交易
pub fn AccessListTransaction::new(
  chain_id : UInt64,
  nonce : UInt64,
  gas_price : UInt64,
  gas_limit : UInt64,
  to : Option[Address],
  value : UInt64,
  data : FixedArray[Byte],
  access_list : Array[AccessTuple],
) -> AccessListTransaction {
  {
    chain_id,
    nonce,
    gas_price,
    gas_limit,
    to,
    value,
    data,
    access_list,
    v: 0UL,
    r: FixedArray::make(32, b'\x00'),
    s: FixedArray::make(32, b'\x00'),
  }
}

///|
/// 检查交易是否已签名
pub fn AccessListTransaction::is_signed(self : AccessListTransaction) -> Bool {
  let mut r_non_zero = false
  let mut s_non_zero = false
  for i = 0; i < 32; i = i + 1 {
    if self.r[i] != b'\x00' {
      r_non_zero = true
    }
    if self.s[i] != b'\x00' {
      s_non_zero = true
    }
  }
  r_non_zero && s_non_zero && self.v <= 1UL
}

