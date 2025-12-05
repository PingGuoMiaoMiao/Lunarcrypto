///|
/// 密码学安全的随机数生成
/// 用于生成私钥

///|
/// 生成密码学安全的随机字节
/// 注意：这需要系统级的随机数源（/dev/urandom 或 CryptGenRandom）
pub fn generate_random_bytes(length : Int) -> FixedArray[Byte] {
  // TODO: 实现真正的密码学安全随机数生成
  // 选项 1: FFI 到系统 API
  // 选项 2: 使用 MoonBit 的随机数库（如果有）

  // 临时实现：返回全零（仅用于测试，不安全！）
  let result = FixedArray::make(length, b'\x00')

  // WARNING: 这不安全！仅用于开发测试
  // 生产环境必须使用真正的随机源

  result
}

///|
/// 生成一个有效的 secp256k1 私钥
/// 私钥必须在 [1, n-1] 范围内
pub fn generate_private_key() -> ECDSAResult[PrivateKey] {
  // 生成 32 字节随机数
  let mut attempts = 0
  let max_attempts = 100
  while attempts < max_attempts {
    let bytes = generate_random_bytes(32)

    // 验证是否在有效范围内
    if is_valid_private_key(bytes) {
      return PrivateKey::from_bytes(bytes)
    }
    attempts = attempts + 1
  }
  Err(
    InvalidPrivateKey(
      "Failed to generate valid private key after \{max_attempts} attempts",
    ),
  )
}

///|
/// 从种子生成确定性私钥
/// 用于测试或从助记词派生密钥
pub fn private_key_from_seed(
  seed : FixedArray[Byte],
) -> ECDSAResult[PrivateKey] {
  // TODO: 使用 HKDF 或类似的 KDF 从种子派生私钥
  if seed.length() < 32 {
    return Err(InvalidPrivateKey("Seed too short"))
  }
  let key_bytes = FixedArray::make(32, b'\x00')
  for i = 0; i < 32; i = i + 1 {
    key_bytes[i] = seed[i]
  }
  PrivateKey::from_bytes(key_bytes)
}
