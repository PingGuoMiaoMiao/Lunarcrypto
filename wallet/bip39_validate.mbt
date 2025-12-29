///|
/// BIP39 助记词验证和恢复
/// 实现助记词验证、熵恢复等功能

///|
/// 从助记词恢复索引
fn mnemonic_to_indices(
  mnemonic : Array[String],
  word_list : WordList,
) -> BIP39Result[Array[Int]] {
  let indices : Array[Int] = []
  
  match word_list {
    English => {
      for i = 0; i < mnemonic.length(); i = i + 1 {
        match find_word_index(mnemonic[i]) {
          None => return Err(InvalidWord("Word not found in word list: \{mnemonic[i]}"))
          Some(index) => indices.push(index)
        }
      }
    }
  }
  
  Ok(indices)
}

///|
/// 从索引恢复熵和校验和
/// 返回：(entropy, checksum_bits)
fn indices_to_entropy_and_checksum(
  indices : Array[Int],
  entropy_bits : Int,
) -> BIP39Result[(FixedArray[Byte], Int)] {
  let checksum_bits = entropy_bits / 32
  let total_bits = entropy_bits + checksum_bits
  let expected_word_count = total_bits / 11
  
      if indices.length() != expected_word_count {
        return Err(InvalidMnemonicLength)
      }
  
  // 1. 将索引转换为位序列
  let bits : Array[Int] = []
  for i = 0; i < indices.length(); i = i + 1 {
    let index = indices[i]
    // 每个索引是 11 位
    for j = 10; j >= 0; j = j - 1 {
      let bit = (index >> j) & 1
      bits.push(bit)
    }
  }
  
  // 2. 分离熵和校验和
  let entropy_bytes = entropy_bits / 8
  let entropy = FixedArray::make(entropy_bytes, b'\x00')
  
  // 提取熵位
  for i = 0; i < entropy_bytes; i = i + 1 {
    let mut byte_val = 0
    for j = 0; j < 8; j = j + 1 {
      let bit_index = i * 8 + j
      if bit_index < bits.length() {
        byte_val = (byte_val << 1) | bits[bit_index]
      }
    }
    entropy[i] = byte_val.to_byte()
  }
  
  // 提取校验和位
  let mut checksum_value = 0
  let checksum_start = entropy_bits
  for i = 0; i < checksum_bits; i = i + 1 {
    let bit_index = checksum_start + i
    if bit_index < bits.length() {
      checksum_value = (checksum_value << 1) | bits[bit_index]
    }
  }
  
  Ok((entropy, checksum_value))
}

///|
/// 从助记词恢复熵
pub fn mnemonic_to_entropy(
  mnemonic : Array[String],
  word_list : WordList,
) -> BIP39Result[FixedArray[Byte]] {
  // 1. 转换为索引
  match mnemonic_to_indices(mnemonic, word_list) {
    Err(e) => Err(e)
    Ok(indices) => {
      // 2. 从助记词数量推断熵长度
      match word_count_to_entropy(mnemonic.length()) {
        None => Err(InvalidMnemonicLength)
        Some(entropy_bits) => {
          // 3. 恢复熵和校验和
          match indices_to_entropy_and_checksum(indices, entropy_bits) {
            Err(e) => Err(e)
            Ok((entropy, checksum)) => {
              // 4. 验证校验和
              let calculated_checksum = calculate_checksum(entropy, entropy_bits)
              let checksum_bits = entropy_bits / 32
              let mask = (1 << checksum_bits) - 1
              let expected_checksum = (calculated_checksum >> (8 - checksum_bits)) & mask
              
              if checksum == expected_checksum {
                Ok(entropy)
              } else {
                Err(InvalidChecksum)
              }
            }
          }
        }
      }
    }
  }
}

///|
/// 验证助记词
pub fn validate_mnemonic(
  mnemonic : Array[String],
  word_list : WordList,
) -> Bool {
  match mnemonic_to_entropy(mnemonic, word_list) {
    Ok(_) => true
    Err(_) => false
  }
}

