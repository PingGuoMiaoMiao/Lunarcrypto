///|
/// ECDSA 签名验证实现（Native FFI）

///|
/// 解析公钥
pub extern "C" fn secp256k1_ec_pubkey_parse(
  ctx : Secp256k1Context,
  pubkey : FixedArray[Byte],
  input : FixedArray[Byte],
  inputlen : UInt,
) -> Int = "secp256k1_ec_pubkey_parse"

///|
/// 解析 DER 格式签名
pub extern "C" fn secp256k1_ecdsa_signature_parse_compact(
  ctx : Secp256k1Context,
  sig : FixedArray[Byte],
  input64 : FixedArray[Byte],
) -> Int = "secp256k1_ecdsa_signature_parse_compact"

///|
/// 验证签名
pub extern "C" fn secp256k1_ecdsa_verify(
  ctx : Secp256k1Context,
  sig : FixedArray[Byte],
  msg32 : FixedArray[Byte],
  pubkey : FixedArray[Byte],
) -> Int = "secp256k1_ecdsa_verify"

///|
/// 验证 ECDSA 签名（Native FFI 实现）
pub fn verify_native(
  message_hash : FixedArray[Byte],
  signature : Signature,
  public_key : PublicKey,
) -> Bool {
  // 验证输入
  if message_hash.length() != 32 {
    return false
  }

  // 创建上下文
  let flags = 0x0301
  let ctx = secp256k1_context_create(flags)

  // 解析公钥
  let pubkey_bytes = public_key.to_bytes()
  let pubkey_internal = FixedArray::make(64, b'\x00')
  let parse_pubkey_result = secp256k1_ec_pubkey_parse(
    ctx,
    pubkey_internal,
    pubkey_bytes,
    pubkey_bytes.length().to_uint(),
  )
  if parse_pubkey_result != 1 {
    secp256k1_context_destroy(ctx)
    return false
  }

  // 组装签名（r + s）
  let sig_bytes = FixedArray::make(64, b'\x00')
  for i = 0; i < 32; i = i + 1 {
    sig_bytes[i] = signature.r[i]
    sig_bytes[32 + i] = signature.s[i]
  }

  // 解析签名
  let sig_internal = FixedArray::make(64, b'\x00')
  let parse_sig_result = secp256k1_ecdsa_signature_parse_compact(
    ctx, sig_internal, sig_bytes,
  )
  if parse_sig_result != 1 {
    secp256k1_context_destroy(ctx)
    return false
  }

  // 验证签名
  let verify_result = secp256k1_ecdsa_verify(
    ctx, sig_internal, message_hash, pubkey_internal,
  )
  secp256k1_context_destroy(ctx)
  verify_result == 1
}

///|
test "verify native - basic" {
  // 创建测试私钥
  let seckey_bytes = FixedArray::make(32, b'\x01')
  let private_key = match PrivateKey::from_bytes(seckey_bytes) {
    Ok(pk) => pk
    Err(_) => return
  }

  // 派生公钥
  let public_key = match derive_public_key(private_key) {
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

  // 验证签名
  let is_valid = verify_native(message_hash, signature, public_key)
  inspect(is_valid, content="true")
}
