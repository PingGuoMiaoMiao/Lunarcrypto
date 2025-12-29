///|
/// BIP39 类型定义
/// 参考: https://github.com/bitcoin/bips/blob/master/bip-0039.mediawiki

///|
/// BIP39 错误类型
pub enum BIP39Error {
  InvalidEntropyLength(String)
  InvalidMnemonicLength
  InvalidWord(String)
  InvalidChecksum
  InvalidPassphrase
} derive(Eq, Show)

///|
/// Result 类型别名
pub type BIP39Result[T] = Result[T, BIP39Error]

///|
/// 单词列表类型
pub enum WordList {
  English  // 2048 words
  // TODO: 支持更多语言
  // ChineseSimplified
  // ChineseTraditional
  // Japanese
  // Spanish
  // etc.
} derive(Eq, Show)

///|
/// 支持的熵长度（位）
/// 对应的助记词长度：
/// - 128 bits -> 12 words
/// - 160 bits -> 15 words
/// - 192 bits -> 18 words
/// - 224 bits -> 21 words
/// - 256 bits -> 24 words
pub const ENTROPY_128_BITS : Int = 128
pub const ENTROPY_160_BITS : Int = 160
pub const ENTROPY_192_BITS : Int = 192
pub const ENTROPY_224_BITS : Int = 224
pub const ENTROPY_256_BITS : Int = 256

///|
/// 验证熵长度是否有效
pub fn is_valid_entropy_length(bits : Int) -> Bool {
  bits == ENTROPY_128_BITS || 
  bits == ENTROPY_160_BITS || 
  bits == ENTROPY_192_BITS || 
  bits == ENTROPY_224_BITS || 
  bits == ENTROPY_256_BITS
}

///|
/// 从熵长度计算助记词长度
pub fn entropy_to_word_count(bits : Int) -> Int {
  // 助记词数量 = (熵长度 + 校验和长度) / 11
  // 校验和长度 = 熵长度 / 32
  let checksum_bits = bits / 32
  (bits + checksum_bits) / 11
}

///|
/// 从助记词数量计算熵长度
pub fn word_count_to_entropy(word_count : Int) -> Option[Int] {
  // 反向计算：word_count * 11 = entropy_bits + checksum_bits
  // checksum_bits = entropy_bits / 32
  // word_count * 11 = entropy_bits * (1 + 1/32) = entropy_bits * 33/32
  // entropy_bits = (word_count * 11 * 32) / 33
  let total_bits = word_count * 11
  if total_bits % 33 != 0 {
    None
  } else {
    let entropy_bits = (total_bits * 32) / 33
    if is_valid_entropy_length(entropy_bits) {
      Some(entropy_bits)
    } else {
      None
    }
  }
}


