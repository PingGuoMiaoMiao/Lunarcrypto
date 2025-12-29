///|
/// ECDSA 公钥恢复实现（Native FFI）

///|
/// 解析可恢复签名
pub extern "C" fn secp256k1_ecdsa_recoverable_signature_parse_compact(
  ctx : Secp256k1Context,
  sig : FixedArray[Byte],
  input64 : FixedArray[Byte],
  recid : Int,
) -> Int = "secp256k1_ecdsa_recoverable_signature_parse_compact"

///|
/// 从签名恢复公钥
pub extern "C" fn secp256k1_ecdsa_recover(
  ctx : Secp256k1Context,
  pubkey : FixedArray[Byte],
  sig : FixedArray[Byte],
  msg32 : FixedArray[Byte],
) -> Int = "secp256k1_ecdsa_recover"

///|
/// 从签名恢复公钥（Native FFI 实现）
pub fn recover_public_key_native(
  message_hash : FixedArray[Byte],
  signature : Signature,
) -> ECDSAResult[PublicKey] {
  // 验证输入
  if message_hash.length() != 32 {
    return Err(InvalidSignature("Message hash must be 32 bytes"))
  }

  // 创建上下文
  let flags = 0x0301
  let ctx = secp256k1_context_create(flags)

  // 组装签名（r + s）
  let sig_bytes = FixedArray::make(64, b'\x00')
  for i = 0; i < 32; i = i + 1 {
    sig_bytes[i] = signature.r[i]
    sig_bytes[32 + i] = signature.s[i]
  }

  // 解析可恢复签名
  let sig_internal = FixedArray::make(65, b'\x00')
  let parse_result = secp256k1_ecdsa_recoverable_signature_parse_compact(
    ctx,
    sig_internal,
    sig_bytes,
    signature.v,
  )
  if parse_result != 1 {
    secp256k1_context_destroy(ctx)
    return Err(InvalidSignature("Failed to parse recoverable signature"))
  }

  // 恢复公钥（内部格式）
  let pubkey_internal = FixedArray::make(64, b'\x00')
  let recover_result = secp256k1_ecdsa_recover(
    ctx, pubkey_internal, sig_internal, message_hash,
  )
  if recover_result != 1 {
    secp256k1_context_destroy(ctx)
    return Err(PublicKeyRecoveryFailed)
  }

  // 序列化为未压缩格式（65字节）
  let output = FixedArray::make(65, b'\x00')
  let outputlen = FixedArray::make(1, 65U)
  let serialize_result = secp256k1_ec_pubkey_serialize(
    ctx, output, outputlen, pubkey_internal, 0x0002, // SECP256K1_EC_UNCOMPRESSED
  )
  secp256k1_context_destroy(ctx)
  if serialize_result != 1 {
    return Err(InvalidPublicKey("Failed to serialize public key"))
  }

  // 创建 PublicKey 对象
  PublicKey::from_bytes(output)
}

///|
test "recover public key native - basic" {
  // 创建测试私钥
  let seckey_bytes = FixedArray::make(32, b'\x01')
  let private_key = match PrivateKey::from_bytes(seckey_bytes) {
    Ok(pk) => pk
    Err(_) => return
  }

  // 派生原始公钥
  let original_pubkey = match derive_public_key(private_key) {
    Ok(pk) => pk
    Err(_) => return
  }

  // 创建测试消息哈希
  let message_hash = FixedArray::make(32, b'\x02')

  // 签名
  let signature = match sign_native(message_hash, private_key) {
    Ok(sig) => sig
    Err(_) => return
  }

  // 恢复公钥
  let recovered_pubkey = match
    recover_public_key_native(message_hash, signature) {
    Ok(pk) => pk
    Err(_) => return
  }

  // 验证恢复的公钥与原始公钥相同
  let original_bytes = original_pubkey.to_bytes()
  let recovered_bytes = recovered_pubkey.to_bytes()
  let mut equal = true
  if original_bytes.length() != recovered_bytes.length() {
    equal = false
  } else {
    for i = 0; i < original_bytes.length(); i = i + 1 {
      if original_bytes[i] != recovered_bytes[i] {
        equal = false
        break
      }
    }
  }
  inspect(equal, content="true")
}
