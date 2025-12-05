///|
/// RLP 编码常量定义
/// 根据 Ethereum Yellow Paper 定义的 RLP 前缀规则

// ===== 字节串编码前缀 =====

///|
/// 单字节值的最大值（无需额外前缀）
/// 单字节 [0x00, 0x7f] 直接作为自身编码
pub const OFFSET_SINGLE_BYTE : Int = 0x7F

///|
/// 短字符串前缀基数
/// 字符串长度 0-55: prefix = 0x80 + length
pub const OFFSET_SHORT_STRING : Int = 0x80

///|
/// 长字符串前缀基数
/// 字符串长度 > 55: prefix = 0xb7 + len(length_bytes)
pub const OFFSET_LONG_STRING : Int = 0xB7

///|
/// 短字符串的最大长度（字节）
/// 超过此长度需要使用长编码
pub const MAX_SHORT_STRING_LENGTH : Int = 55

// ===== 列表编码前缀 =====

///|
/// 短列表前缀基数
/// 列表 payload 长度 0-55: prefix = 0xc0 + payload_length
pub const OFFSET_SHORT_LIST : Int = 0xC0

///|
/// 长列表前缀基数
/// 列表 payload 长度 > 55: prefix = 0xf7 + len(payload_length_bytes)
pub const OFFSET_LONG_LIST : Int = 0xF7

///|
/// 短列表的最大 payload 长度（字节）
/// 超过此长度需要使用长编码
pub const MAX_SHORT_LIST_LENGTH : Int = 55

// ===== 解码边界值 =====

///|
/// 短字符串编码的上界
/// [0x80, 0xb7] 范围表示短字符串
pub const BOUND_SHORT_STRING : Int = 0xB7

///|
/// 长字符串编码的上界
/// [0xb8, 0xbf] 范围表示长字符串
pub const BOUND_LONG_STRING : Int = 0xBF

///|
/// 短列表编码的上界
/// [0xc0, 0xf7] 范围表示短列表
pub const BOUND_SHORT_LIST : Int = 0xF7

///|
/// 长列表编码的上界（最大前缀值）
/// [0xf8, 0xff] 范围表示长列表
pub const BOUND_LONG_LIST : Int = 0xFF

// ===== 特殊值 =====

///|
/// 空字符串的 RLP 编码
/// "" -> 0x80
pub const EMPTY_STRING_ENCODING : Byte = b'\x80'

///|
/// 空列表的 RLP 编码
/// [] -> 0xc0
pub const EMPTY_LIST_ENCODING : Byte = b'\xc0'

// ===== 文档注释 =====

/// RLP 编码规则总结：
///
/// 1. 单字节 [0x00, 0x7f]
///    - 直接编码为该字节本身
///
/// 2. 字符串长度 0-55
///    - prefix = 0x80 + length
///    - 编码 = [prefix, ...bytes]
///
/// 3. 字符串长度 > 55
///    - len_of_length = byte_length(length)
///    - prefix = 0xb7 + len_of_length
///    - 编码 = [prefix, ...length_bytes (big-endian), ...bytes]
///
/// 4. 列表 payload 长度 0-55
///    - prefix = 0xc0 + payload_length
///    - 编码 = [prefix, ...encoded_items]
///
/// 5. 列表 payload 长度 > 55
///    - len_of_length = byte_length(payload_length)
///    - prefix = 0xf7 + len_of_length
///    - 编码 = [prefix, ...payload_length_bytes (big-endian), ...encoded_items]
///
/// 关键原则：
/// - 所有长度必须使用最小的大端字节表示（无前导零）
/// - 解码时必须拒绝非规范编码
/// - 整数 0 编码为空字符串（0x80）
