///|
/// BIP39 助记词生成
/// 实现熵生成、校验和计算和助记词生成

///|
/// 使用 Keccak256 计算 SHA256（用于校验和）
/// 注意：我们需要 SHA256，但当前只有 Keccak256
/// TODO: 需要实现 SHA256 或使用外部库
/// 
/// 临时方案：使用 Keccak256 作为占位符（不正确，但可以先让代码编译）
fn sha256_for_checksum(data : FixedArray[Byte]) -> FixedArray[Byte] {
  // TODO: 实现真正的 SHA256
  // 当前使用 Keccak256 作为占位符（这不是正确的实现）
  let arr : Array[Byte] = []
  for i = 0; i < data.length(); i = i + 1 {
    arr.push(data[i])
  }
  let hash_array = @PingGuoMiaoMiao/LunarKeccak256/cmd/lib.keccak256(arr)
  
  // 转换为 FixedArray[Byte]（只取前 32 字节）
  let result = FixedArray::make(32, b'\x00')
  for i = 0; i < 32 && i < hash_array.length(); i = i + 1 {
    result[i] = hash_array[i]
  }
  result
}

///|
/// 计算校验和
/// checksum = SHA256(entropy) 的前 (entropy_bits / 32) 位
fn calculate_checksum(entropy : FixedArray[Byte], entropy_bits : Int) -> Int {
  // 计算 SHA256 哈希
  let hash = sha256_for_checksum(entropy)
  
  // 校验和位数 = 熵位数 / 32
  let checksum_bits = entropy_bits / 32
  
  // 取哈希的第一个字节的前 checksum_bits 位
  if checksum_bits <= 8 {
    let first_byte = hash[0].to_int()
    // 提取前 checksum_bits 位
    let mask = (1 << checksum_bits) - 1
    (first_byte >> (8 - checksum_bits)) & mask
  } else {
    // 如果校验和超过 8 位（不应该发生），只返回前 8 位
    hash[0].to_int() >> (8 - checksum_bits)
  }
}

///|
/// 生成指定长度的熵（字节数组）
/// 
/// 注意：实际应用中应该使用密码学安全的随机数生成器
/// 当前使用 ecdsa 模块的随机数生成（如果可用）
pub fn generate_entropy(entropy_bits : Int) -> BIP39Result[FixedArray[Byte]] {
  if !is_valid_entropy_length(entropy_bits) {
    return Err(InvalidEntropyLength("Entropy length must be 128, 160, 192, 224, or 256 bits"))
  }
  
  let entropy_bytes = entropy_bits / 8
  // TODO: 使用密码学安全的随机数生成器
  // 当前使用 ecdsa 模块的随机数生成（临时方案）
  let entropy = @ecdsa.generate_random_bytes(entropy_bytes)
  
  // 转换为 FixedArray[Byte]
  let fixed_entropy = FixedArray::make(entropy_bytes, b'\x00')
  for i = 0; i < entropy_bytes && i < entropy.length(); i = i + 1 {
    fixed_entropy[i] = entropy[i]
  }
  
  Ok(fixed_entropy)
}

///|
/// 将熵和校验和组合为完整的位序列
/// 返回：Array[Int]，每个元素是 11 位的索引（0-2047）
fn entropy_to_indices(entropy : FixedArray[Byte], entropy_bits : Int) -> Array[Int] {
  // 计算校验和
  let checksum = calculate_checksum(entropy, entropy_bits)
  let checksum_bits = entropy_bits / 32
  
  // 计算总位数和助记词数量
  let total_bits = entropy_bits + checksum_bits
  let word_count = total_bits / 11
  
  // 构建完整的位序列
  let bits : Array[Int] = []
  
  // 1. 添加熵的所有位
  for i = 0; i < entropy.length(); i = i + 1 {
    let byte_val = entropy[i].to_int()
    for j = 7; j >= 0; j = j - 1 {
      let bit = (byte_val >> j) & 1
      bits.push(bit)
    }
  }
  
  // 2. 添加校验和位
  for i = checksum_bits - 1; i >= 0; i = i - 1 {
    let bit = (checksum >> i) & 1
    bits.push(bit)
  }
  
  // 3. 将位序列转换为 11 位索引
  let indices : Array[Int] = []
  let mut i = 0
  while i < bits.length() {
    let mut index = 0
    for j = 0; j < 11 && i + j < bits.length(); j = j + 1 {
      index = (index << 1) | bits[i + j]
    }
    indices.push(index)
    i = i + 11
  }
  
  indices
}

///|
/// 从熵生成助记词
pub fn generate_mnemonic(
  entropy_bits : Int,
  word_list : WordList,
) -> BIP39Result[Array[String]] {
  // 1. 生成熵
  match generate_entropy(entropy_bits) {
    Err(e) => Err(e)
    Ok(entropy) => {
      // 2. 转换为索引
      let indices = entropy_to_indices(entropy, entropy_bits)
      
      // 3. 根据单词列表获取单词
      let mnemonic : Array[String] = []
      
      match word_list {
        English => {
          for i = 0; i < indices.length(); i = i + 1 {
            match get_word_at_index(indices[i]) {
              None => return Err(InvalidWord("Word index out of range"))
              Some(word) => mnemonic.push(word)
            }
          }
        }
      }
      
      Ok(mnemonic)
    }
  }
}

///|
/// 使用指定的熵生成助记词（用于测试）
pub fn mnemonic_from_entropy(
  entropy : FixedArray[Byte],
  entropy_bits : Int,
  word_list : WordList,
) -> BIP39Result[Array[String]] {
  if !is_valid_entropy_length(entropy_bits) {
    return Err(InvalidEntropyLength("Invalid entropy length"))
  }
  
  let expected_bytes = entropy_bits / 8
  if entropy.length() != expected_bytes {
    return Err(InvalidEntropyLength("Entropy length mismatch"))
  }
  
  // 转换为索引
  let indices = entropy_to_indices(entropy, entropy_bits)
  
  // 根据单词列表获取单词
  let mnemonic : Array[String] = []
  
  match word_list {
    English => {
      for i = 0; i < indices.length(); i = i + 1 {
        match get_word_at_index(indices[i]) {
          None => return Err(InvalidWord("Word index out of range"))
          Some(word) => mnemonic.push(word)
        }
      }
    }
  }
  
  Ok(mnemonic)
}

