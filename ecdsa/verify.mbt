///|
/// ECDSA 签名验证实现（占位符版本）
/// 等待 FFI 支持后实现

///|
/// 验证 ECDSA 签名
/// 
/// message_hash: 32 字节的消息哈希
/// signature: ECDSA 签名
/// public_key: 公钥
/// 
/// 返回: true 表示签名有效，false 表示无效
pub fn verify(
  message_hash : FixedArray[Byte],
  signature : Signature,
  public_key : PublicKey,
) -> Bool {
  verify_native(message_hash, signature, public_key)
}

///|
/// 验证签名并返回详细结果
pub fn verify_detailed(
  _message_hash : FixedArray[Byte],
  _signature : Signature,
  _public_key : PublicKey,
) -> ECDSAResult[Unit] {
  Err(SignatureVerificationFailed)
}
