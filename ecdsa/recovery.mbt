///|
/// 公钥恢复实现（占位符版本）
/// 等待 FFI 支持后实现

///|
/// 从签名和消息哈希恢复公钥
/// 
/// message_hash: 32 字节的消息哈希
/// signature: ECDSA 签名（必须包含恢复 ID）
/// 
/// 返回: 恢复的公钥（未压缩格式）
pub fn recover_public_key(
  message_hash : FixedArray[Byte],
  signature : Signature,
) -> ECDSAResult[PublicKey] {
  recover_public_key_native(message_hash, signature)
}

// recover_ethereum_address 等函数已移至 ethereum.mbt
