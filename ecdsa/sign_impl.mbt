///|
/// ECDSA 签名实现（Native FFI）

///|
/// 添加签名相关的 FFI 绑定
pub extern "C" fn secp256k1_ecdsa_sign_recoverable(
  ctx : Secp256k1Context,
  sig : FixedArray[Byte],
  msg32 : FixedArray[Byte],
  seckey : FixedArray[Byte],
  noncefp : Int,
  ndata : Int,
) -> Int = "secp256k1_ecdsa_sign_recoverable"

///|
pub extern "C" fn secp256k1_ecdsa_recoverable_signature_serialize_compact(
  ctx : Secp256k1Context,
  output64 : FixedArray[Byte],
  recid : FixedArray[Int],
  sig : FixedArray[Byte],
) -> Int = "secp256k1_ecdsa_recoverable_signature_serialize_compact"

///|
/// 对消息哈希进行 ECDSA 签名（Native FFI 实现）
pub fn sign_native(
  message_hash : FixedArray[Byte],
  private_key : PrivateKey,
) -> ECDSAResult[Signature] {
  // 验证输入
  if message_hash.length() != 32 {
    return Err(InvalidSignature("Message hash must be 32 bytes"))
  }

  // 创建上下文
  let flags = 0x0301
  let ctx = secp256k1_context_create(flags)

  // 验证私钥
  let verify_result = secp256k1_ec_seckey_verify(ctx, private_key.to_bytes())
  if verify_result != 1 {
    secp256k1_context_destroy(ctx)
    return Err(InvalidPrivateKey("Private key is invalid"))
  }

  // 创建可恢复签名（65字节内部格式）
  let sig_internal = FixedArray::make(65, b'\x00')

  // 调用 libsecp256k1 签名（使用 RFC 6979 确定性 nonce）
  let sign_result = secp256k1_ecdsa_sign_recoverable(
    ctx,
    sig_internal,
    message_hash,
    private_key.to_bytes(),
    0, // NULL: 使用 RFC 6979
    0, // NULL: 无额外数据
  )
  if sign_result != 1 {
    secp256k1_context_destroy(ctx)
    return Err(InvalidSignature("Failed to create signature"))
  }

  // 序列化签名为紧凑格式
  let output64 = FixedArray::make(64, b'\x00')
  let recid_array = FixedArray::make(1, 0)
  let serialize_result = secp256k1_ecdsa_recoverable_signature_serialize_compact(
    ctx, output64, recid_array, sig_internal,
  )
  secp256k1_context_destroy(ctx)
  if serialize_result != 1 {
    return Err(InvalidSignature("Failed to serialize signature"))
  }

  // 提取 r, s, v
  let r = FixedArray::make(32, b'\x00')
  let s = FixedArray::make(32, b'\x00')
  for i = 0; i < 32; i = i + 1 {
    r[i] = output64[i]
    s[i] = output64[32 + i]
  }
  let v = recid_array[0]

  // 创建签名对象
  Signature::new(r, s, v)
}

///|
test "sign native - basic" {
  // 创建测试私钥
  let seckey_bytes = FixedArray::make(32, b'\x01')
  let private_key = match PrivateKey::from_bytes(seckey_bytes) {
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

  // 验证签名格式
  inspect(signature.r.length() == 32, content="true")
  inspect(signature.s.length() == 32, content="true")
  inspect(signature.v >= 0 && signature.v <= 3, content="true")
}
