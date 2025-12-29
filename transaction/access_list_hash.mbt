///|
/// EIP-2930 Access List 交易哈希计算
/// 根据 EIP-2930，交易哈希计算方式：
/// hash = Keccak256(0x01 || RLP([chainId, nonce, gasPrice, gasLimit, to, value, data, accessList]))

///|
/// 将 FixedArray[Byte] 转换为 Array[Byte]
fn fixed_array_to_array_fixed(fixed : FixedArray[Byte]) -> Array[Byte] {
  let arr : Array[Byte] = []
  for i = 0; i < fixed.length(); i = i + 1 {
    arr.push(fixed[i])
  }
  arr
}

///|
/// 将 Array[Byte] 转换为 FixedArray[Byte]
fn array_to_fixed_array_fixed(arr : Array[Byte], len : Int) -> FixedArray[Byte] {
  let fixed = FixedArray::make(len, b'\x00')
  for i = 0; i < len && i < arr.length(); i = i + 1 {
    fixed[i] = arr[i]
  }
  fixed
}

///|
/// 计算 Access List 交易哈希（用于签名）
/// 返回 32 字节的哈希值
/// 
/// 根据 EIP-2930：
/// hash = Keccak256(0x01 || RLP([chainId, nonce, gasPrice, gasLimit, to, value, data, accessList]))
pub fn access_list_transaction_hash(
  tx : AccessListTransaction,
) -> FixedArray[Byte] {
  // 编码未签名的交易（包含交易类型前缀 0x01）
  let encoded = encode_unsigned_access_list_transaction(tx)
  
  // 转换为 Array[Byte]
  let encoded_array = fixed_array_to_array_fixed(encoded)
  
  // 计算哈希
  let hash_array = @PingGuoMiaoMiao/LunarKeccak256/cmd/lib.keccak256(encoded_array)
  
  // 转换回 FixedArray[Byte]
  array_to_fixed_array_fixed(hash_array, 32)
}

///|
/// 计算已签名 Access List 交易的哈希
/// 用于验证交易
pub fn signed_access_list_transaction_hash(tx : AccessListTransaction) -> FixedArray[Byte] {
  let encoded = encode_access_list_transaction(tx)
  
  // 转换为 Array[Byte]
  let encoded_array = fixed_array_to_array_fixed(encoded)
  
  // 计算哈希
  let hash_array = @PingGuoMiaoMiao/LunarKeccak256/cmd/lib.keccak256(encoded_array)
  
  // 转换回 FixedArray[Byte]
  array_to_fixed_array_fixed(hash_array, 32)
}

