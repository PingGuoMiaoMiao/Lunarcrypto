///|
/// ECDSA 签名实现（占位符版本）
/// 等待 FFI 支持后实现

///|
/// 对消息哈希进行 ECDSA 签名
/// 
/// message_hash: 32 字节的消息哈希（通常是 Keccak256 或 SHA256）
/// private_key: 私钥
/// 
/// 返回: 签名（包含 r, s, v）
pub fn sign(
  message_hash : FixedArray[Byte],
  private_key : PrivateKey,
) -> ECDSAResult[Signature] {
  sign_native(message_hash, private_key)
}

// sign_message 和 sign_ethereum_message 已移至 ethereum.mbt
