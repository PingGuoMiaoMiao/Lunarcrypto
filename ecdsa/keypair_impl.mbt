///|
/// 密钥对生成实现（使用 Native FFI）

///|
/// 从私钥派生公钥（Native FFI 实现）
pub fn derive_public_key_native(
  private_key : PrivateKey,
) -> ECDSAResult[PublicKey] {
  // 创建上下文
  let flags = 0x0301 // SIGN | VERIFY
  let ctx = secp256k1_context_create(flags)

  // 验证私钥
  let verify_result = secp256k1_ec_seckey_verify(ctx, private_key.to_bytes())
  if verify_result != 1 {
    secp256k1_context_destroy(ctx)
    return Err(InvalidPrivateKey("Private key is invalid"))
  }

  // 创建公钥结构（需要 64 字节的内部格式）
  // 注意：libsecp256k1 使用内部格式，需要序列化
  // 我们需要先创建一个临时的 pubkey 对象

  // TODO: 这里需要一个辅助函数来正确处理 secp256k1_pubkey 结构
  // 暂时返回错误，等待完整实现
  secp256k1_context_destroy(ctx)
  Err(InvalidPrivateKey("Public key derivation not fully implemented yet"))
}

///|
/// 辅助函数：从私钥创建公钥并序列化
/// 返回未压缩格式的公钥（65 字节）
fn create_and_serialize_pubkey(
  ctx : Secp256k1Context,
  seckey : FixedArray[Byte],
  compressed : Bool,
) -> ECDSAResult[FixedArray[Byte]] {
  // 这个函数需要处理 secp256k1_pubkey 结构
  // secp256k1_pubkey 在 C 中是 64 字节的内部表示

  // 步骤：
  // 1. 分配 secp256k1_pubkey 结构（64 字节）
  // 2. 调用 secp256k1_ec_pubkey_create
  // 3. 调用 secp256k1_ec_pubkey_serialize
  // 4. 返回序列化的字节

  Err(InvalidPrivateKey("Helper function not implemented"))
}

///|
test "derive public key native - verification" {
  // 测试私钥验证
  let flags = 0x0301
  let ctx = secp256k1_context_create(flags)

  // 创建测试私钥
  let seckey = FixedArray::make(32, b'\x01')
  let result = secp256k1_ec_seckey_verify(ctx, seckey)
  inspect(result == 1, content="true")
  secp256k1_context_destroy(ctx)
}
