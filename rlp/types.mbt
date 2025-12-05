///|
/// RLP Item 类型定义
// RLP 支持两种基本类型：字节串和列表
pub enum RLPItem {
  Bytes(FixedArray[Byte])
  List(Array[RLPItem])
} derive(Show, Eq)

///|
/// RLP 错误类型
pub enum RLPError {
  InvalidInput(String)
  UnexpectedEnd
  InvalidLength
  NonCanonicalEncoding
} derive(Show, Eq)

///|
/// Result 类型别名
pub type RLPResult[T] = Result[T, RLPError]

///|
/// RLPItem 辅助构造函数
pub fn RLPItem::from_bytes(b : FixedArray[Byte]) -> RLPItem {
  Bytes(b)
}

///|
pub fn RLPItem::from_list(items : Array[RLPItem]) -> RLPItem {
  List(items)
}

///|
pub fn RLPItem::empty_bytes() -> RLPItem {
  Bytes(FixedArray::make(0, b'\x00'))
}

///|
pub fn RLPItem::empty_list() -> RLPItem {
  List([])
}

///|
/// RLPItem 辅助方法
pub fn RLPItem::is_bytes(self : RLPItem) -> Bool {
  match self {
    Bytes(_) => true
    List(_) => false
  }
}

///|
pub fn RLPItem::is_list(self : RLPItem) -> Bool {
  match self {
    Bytes(_) => false
    List(_) => true
  }
}

///|
pub fn RLPItem::as_bytes(self : RLPItem) -> RLPResult[FixedArray[Byte]] {
  match self {
    Bytes(b) => Ok(b)
    List(_) => Err(InvalidInput("Expected bytes, got list"))
  }
}

///|
pub fn RLPItem::as_list(self : RLPItem) -> RLPResult[Array[RLPItem]] {
  match self {
    Bytes(_) => Err(InvalidInput("Expected list, got bytes"))
    List(items) => Ok(items)
  }
}
