///|
/// EIP-1559 Dynamic Fee 交易哈希计算
/// 根据 EIP-1559，交易哈希计算方式：
/// hash = Keccak256(0x02 || RLP([chainId, nonce, maxPriorityFeePerGas, maxFeePerGas, gasLimit, to, value, data, accessList]))

///|
/// 复用 access_list_hash.mbt 中的转换函数
/// 注意：这些函数已经在 access_list_hash.mbt 中定义，为了避免重复定义，我们使用不同的名称

///|
/// 将 FixedArray[Byte] 转换为 Array[Byte]
fn fixed_array_to_array_1559(fixed : FixedArray[Byte]) -> Array[Byte] {
  let arr : Array[Byte] = []
  for i = 0; i < fixed.length(); i = i + 1 {
    arr.push(fixed[i])
  }
  arr
}

///|
/// 将 Array[Byte] 转换为 FixedArray[Byte]
fn array_to_fixed_array_1559(arr : Array[Byte], len : Int) -> FixedArray[Byte] {
  let fixed = FixedArray::make(len, b'\x00')
  for i = 0; i < len && i < arr.length(); i = i + 1 {
    fixed[i] = arr[i]
  }
  fixed
}

///|
/// 计算 EIP-1559 交易哈希（用于签名）
/// 返回 32 字节的哈希值
/// 
/// 根据 EIP-1559：
/// hash = Keccak256(0x02 || RLP([chainId, nonce, maxPriorityFeePerGas, maxFeePerGas, gasLimit, to, value, data, accessList]))
pub fn eip1559_transaction_hash(
  tx : EIP1559Transaction,
) -> FixedArray[Byte] {
  // 编码未签名的交易（包含交易类型前缀 0x02）
  let encoded = encode_unsigned_eip1559_transaction(tx)
  
  // 转换为 Array[Byte]
  let encoded_array = fixed_array_to_array_1559(encoded)
  
  // 计算哈希
  let hash_array = @PingGuoMiaoMiao/LunarKeccak256/cmd/lib.keccak256(encoded_array)
  
  // 转换回 FixedArray[Byte]
  array_to_fixed_array_1559(hash_array, 32)
}

///|
/// 计算已签名 EIP-1559 交易的哈希
/// 用于验证交易
pub fn signed_eip1559_transaction_hash(tx : EIP1559Transaction) -> FixedArray[Byte] {
  let encoded = encode_eip1559_transaction(tx)
  
  // 转换为 Array[Byte]
  let encoded_array = fixed_array_to_array_1559(encoded)
  
  // 计算哈希
  let hash_array = @PingGuoMiaoMiao/LunarKeccak256/cmd/lib.keccak256(encoded_array)
  
  // 转换回 FixedArray[Byte]
  array_to_fixed_array_1559(hash_array, 32)
}

