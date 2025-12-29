///|
/// secp256k1 椭圆曲线参数
/// 这是比特币和以太坊使用的标准曲线
/// 曲线方程: y² = x³ + 7 (mod p)

///|
/// secp256k1 曲线参数
/// 来源: https://www.secg.org/sec2-v2.pdf

// 素数 p（定义有限域）
// p = 2^256 - 2^32 - 2^9 - 2^8 - 2^7 - 2^6 - 2^4 - 1
// p = FFFFFFFF FFFFFFFF FFFFFFFF FFFFFFFF FFFFFFFF FFFFFFFF FFFFFFFE FFFFFC2F
pub const CURVE_P : String = "fffffffffffffffffffffffffffffffffffffffffffffffffffffffefffffc2f"

// 曲线阶数 n（生成元 G 的阶）
// n = FFFFFFFF FFFFFFFF FFFFFFFF FFFFFFFE BAAEDCE6 AF48A03B BFD25E8C D0364141

///|
pub const CURVE_N : String = "fffffffffffffffffffffffffffffffebaaedce6af48a03bbfd25e8cd0364141"

// 基点 G 的 x 坐标
// Gx = 79BE667E F9DCBBAC 55A06295 CE870B07 029BFCDB 2DCE28D9 59F2815B 16F81798

///|
pub const GENERATOR_X : String = "79be667ef9dcbbac55a06295ce870b07029bfcdb2dce28d959f2815b16f81798"

// 基点 G 的 y 坐标
// Gy = 483ADA77 26A3C465 5DA4FBFC 0E1108A8 FD17B448 A6855419 9C47D08F FB10D4B8

///|
pub const GENERATOR_Y : String = "483ada7726a3c4655da4fbfc0e1108a8fd17b448a68554199c47d08ffb10d4b8"

// 曲线参数 a（在 secp256k1 中为 0）

///|
pub const CURVE_A : Int = 0

// 曲线参数 b（在 secp256k1 中为 7）

///|
pub const CURVE_B : Int = 7

///|
/// 曲线上的点
pub enum Point {
  Infinity // 无穷远点（单位元）
  Affine(FixedArray[Byte], FixedArray[Byte]) // (x, y) 仿射坐标
}

///|
pub fn Point::infinity() -> Point {
  Infinity
}

///|
pub fn Point::affine(x : FixedArray[Byte], y : FixedArray[Byte]) -> Point {
  Affine(x, y)
}

///|
pub fn Point::is_infinity(self : Point) -> Bool {
  match self {
    Infinity => true
    Affine(_, _) => false
  }
}

///|
pub fn Point::get_x(self : Point) -> FixedArray[Byte]? {
  match self {
    Infinity => None
    Affine(x, _) => Some(x)
  }
}

///|
pub fn Point::get_y(self : Point) -> FixedArray[Byte]? {
  match self {
    Infinity => None
    Affine(_, y) => Some(y)
  }
}

///|
/// secp256k1 配置结构
pub struct Secp256k1 {
  // TODO: 存储预计算的值以加速运算
  _dummy : Int // 占位字段
}

///|
pub fn Secp256k1::new() -> Secp256k1 {
  Secp256k1::{ _dummy: 0 }
}

///|
pub fn Secp256k1::generator(_self : Secp256k1) -> Point {
  // TODO: 从常量创建点
  // 临时返回无穷远点
  Point::infinity()
}

///|
pub fn Secp256k1::is_on_curve(_self : Secp256k1, point : Point) -> Bool {
  match point {
    Infinity => true
    Affine(_x, _y) =>
      // TODO: 实现曲线验证
      // y² mod p == (x³ + 7) mod p
      true
  }
}

///|
/// 常量：私钥的最小值（1）
pub const PRIVATE_KEY_MIN : Int = 1

///|
/// 常量：私钥的最大值（n - 1）
/// 实际应该是大整数，这里暂时用 String 表示
pub fn get_private_key_max() -> String {
  // n - 1
  CURVE_N
}

///|
/// 验证私钥是否在有效范围内
/// 私钥必须在 [1, n-1] 范围内
pub fn is_valid_private_key(key : FixedArray[Byte]) -> Bool {
  if key.length() != 32 {
    return false
  }

  // 检查不能全为零
  let mut all_zero = true
  for i = 0; i < 32; i = i + 1 {
    if key[i] != b'\x00' {
      all_zero = false
      break
    }
  }
  if all_zero {
    return false
  }

  // TODO: 检查 < n（需要大整数比较）
  // 目前只检查非零

  true
}
