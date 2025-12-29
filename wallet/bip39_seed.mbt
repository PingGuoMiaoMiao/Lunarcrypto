///|
/// BIP39 助记词到种子转换
/// 使用 PBKDF2-HMAC-SHA512
/// 参考: BIP39 规范

///|
/// BIP39 标准参数
pub const PBKDF2_ITERATIONS : Int = 2048
pub const SEED_LENGTH : Int = 64  // 512 bits

///|
/// 将助记词转换为种子
/// 
/// 算法：
/// seed = PBKDF2-HMAC-SHA512(
///   password = mnemonic (UTF-8),
///   salt = "mnemonic" + passphrase (UTF-8),
///   iterations = 2048,
///   key_length = 64 bytes
/// )
pub fn mnemonic_to_seed(
  mnemonic : Array[String],
  passphrase : String,
) -> BIP39Result[FixedArray[Byte]] {
  // 1. 验证助记词（假设使用英文单词列表）
  if !validate_mnemonic(mnemonic, English) {
    return Err(InvalidMnemonicLength)
  }
  
  // 2. 将助记词转换为字符串（空格分隔）
  let mut mnemonic_str = ""
  for i = 0; i < mnemonic.length(); i = i + 1 {
    if i > 0 {
      mnemonic_str = mnemonic_str + " "
    }
    mnemonic_str = mnemonic_str + mnemonic[i]
  }
  
  // 3. 构建 salt: "mnemonic" + passphrase
  let salt = "mnemonic" + passphrase
  
  // 4. 使用 PBKDF2 生成种子
  // TODO: 等待 PBKDF2 实现完成
  let seed = pbkdf2_hmac_sha512(
    mnemonic_str,
    salt,
    PBKDF2_ITERATIONS,
    SEED_LENGTH,
  )
  
  Ok(seed)
}

///|
/// 将助记词转换为种子（无密码短语）
pub fn mnemonic_to_seed_no_passphrase(
  mnemonic : Array[String],
) -> BIP39Result[FixedArray[Byte]] {
  mnemonic_to_seed(mnemonic, "")
}


