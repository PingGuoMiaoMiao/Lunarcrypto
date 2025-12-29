///|
/// Legacy 交易哈希计算
/// 根据 EIP-155，未签名交易的哈希计算方式：
/// hash = Keccak256(RLP([nonce, gasPrice, gasLimit, to, value, data, chainId, 0, 0]))

///|
/// 将 Array[Byte] 转换为 FixedArray[Byte]
fn array_to_fixed_array(arr : Array[Byte], len : Int) -> FixedArray[Byte] {
  let fixed = FixedArray::make(len, b'\x00')
  for i = 0; i < len && i < arr.length(); i = i + 1 {
    fixed[i] = arr[i]
  }
  fixed
}

///|
/// 将 FixedArray[Byte] 转换为 Array[Byte]
fn fixed_array_to_array(fixed : FixedArray[Byte]) -> Array[Byte] {
  let arr : Array[Byte] = []
  for i = 0; i < fixed.length(); i = i + 1 {
    arr.push(fixed[i])
  }
  arr
}

///|
/// 计算 Legacy 交易哈希（用于签名）
/// 返回 32 字节的哈希值
/// 
/// 使用 LunarKeccak256 包计算哈希
/// 包别名需要通过编译命令确定，可能需要使用 @PingGuoMiaoMiao/LunarKeccak256/cmd/lib
pub fn legacy_transaction_hash(
  tx : LegacyTransaction,
  chain_id : UInt64,
) -> FixedArray[Byte] {
  // 编码未签名的交易（EIP-155 格式）
  let encoded = encode_unsigned_legacy_transaction(tx, chain_id)
  
  // 转换为 Array[Byte] 以便调用 keccak256
  let encoded_array = fixed_array_to_array(encoded)
  
  // 调用 LunarKeccak256 的 keccak256 函数
  // 注意：需要确认包别名，可能是 keccak256 或其他
  let hash_array = @PingGuoMiaoMiao/LunarKeccak256/cmd/lib.keccak256(encoded_array)
  
  // 转换回 FixedArray[Byte]
  array_to_fixed_array(hash_array, 32)
}

///|
/// 计算已签名 Legacy 交易的哈希
/// 用于验证交易
pub fn signed_legacy_transaction_hash(tx : LegacyTransaction) -> FixedArray[Byte] {
  let encoded = encode_legacy_transaction(tx)
  
  // 转换为 Array[Byte]
  let encoded_array = fixed_array_to_array(encoded)
  
  // 计算哈希
  let hash_array = @PingGuoMiaoMiao/LunarKeccak256/cmd/lib.keccak256(encoded_array)
  
  // 转换回 FixedArray[Byte]
  array_to_fixed_array(hash_array, 32)
}

