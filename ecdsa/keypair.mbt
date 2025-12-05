///|
/// 密钥对生成和管理

///|
/// 密钥对结构
pub struct KeyPair {
  private_key : PrivateKey
  public_key : PublicKey
}

///|
pub fn KeyPair::new(
  private_key : PrivateKey,
  public_key : PublicKey,
) -> KeyPair {
  KeyPair::{ private_key, public_key }
}

///|
pub fn KeyPair::get_private_key(self : KeyPair) -> PrivateKey {
  self.private_key
}

///|
pub fn KeyPair::get_public_key(self : KeyPair) -> PublicKey {
  self.public_key
}

///|
pub fn KeyPair::from_private_key(
  private_key : PrivateKey,
) -> ECDSAResult[KeyPair] {
  match derive_public_key(private_key) {
    Ok(public_key) => Ok(KeyPair::new(private_key, public_key))
    Err(e) => Err(e)
  }
}

///|
/// 生成新的随机密钥对
pub fn generate_keypair() -> ECDSAResult[KeyPair] {
  match generate_private_key() {
    Ok(private_key) =>
      match derive_public_key(private_key) {
        Ok(public_key) => Ok(KeyPair::new(private_key, public_key))
        Err(e) => Err(e)
      }
    Err(e) => Err(e)
  }
}

///|
/// 从私钥派生公钥
/// 使用 libsecp256k1 通过 Native FFI
pub fn derive_public_key(private_key : PrivateKey) -> ECDSAResult[PublicKey] {
  // 创建上下文
  let flags = 0x0301 // SIGN | VERIFY
  let ctx = secp256k1_context_create(flags)

  // 验证私钥
  let verify_result = secp256k1_ec_seckey_verify(ctx, private_key.to_bytes())
  if verify_result != 1 {
    secp256k1_context_destroy(ctx)
    return Err(InvalidPrivateKey("Private key is invalid"))
  }

  // 创建公钥（内部格式，64字节）
  let pubkey_internal = FixedArray::make(64, b'\x00')
  let create_result = secp256k1_ec_pubkey_create(
    ctx,
    pubkey_internal,
    private_key.to_bytes(),
  )
  if create_result != 1 {
    secp256k1_context_destroy(ctx)
    return Err(InvalidPrivateKey("Failed to create public key"))
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
/// 验证密钥对是否匹配
/// 检查公钥是否正确对应私钥
pub fn verify_keypair(keypair : KeyPair) -> Bool {
  // 重新从私钥派生公钥并比较
  match derive_public_key(keypair.private_key) {
    Ok(derived_pubkey) => derived_pubkey == keypair.public_key
    Err(_) => false
  }
}
