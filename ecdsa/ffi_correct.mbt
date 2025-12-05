///|
/// libsecp256k1 FFI 绑定（正确语法）
/// 
/// 参考: https://docs.moonbitlang.com/en/latest/language/ffi.html

///|
/// 外部类型：secp256k1 上下文（对应 C 的 secp256k1_context*）
#external
pub type Secp256k1Context

///|
/// 外部类型：secp256k1 公钥（对应 C 的 secp256k1_pubkey）
#external
pub type Secp256k1Pubkey

///|
/// 外部类型：可恢复签名（对应 C 的 secp256k1_ecdsa_recoverable_signature）
#external
pub type Secp256k1RecoverableSignature

///|
/// 创建 secp256k1 上下文
/// flags: SECP256K1_CONTEXT_SIGN (0x0201) | SECP256K1_CONTEXT_VERIFY (0x0101)
pub extern "C" fn secp256k1_context_create(flags : Int) -> Secp256k1Context = "secp256k1_context_create"

///|
/// 销毁 secp256k1 上下文
pub extern "C" fn secp256k1_context_destroy(ctx : Secp256k1Context) -> Unit = "secp256k1_context_destroy"

///|
/// 验证私钥是否有效
/// 返回: 1 有效, 0 无效
pub extern "C" fn secp256k1_ec_seckey_verify(
  ctx : Secp256k1Context,
  seckey : FixedArray[Byte],
) -> Int = "secp256k1_ec_seckey_verify"

///|
/// 从私钥创建公钥
/// pubkey: 64 字节缓冲区（内部格式）
/// seckey: 32 字节私钥
/// 返回: 1 成功, 0 失败
pub extern "C" fn secp256k1_ec_pubkey_create(
  ctx : Secp256k1Context,
  pubkey : FixedArray[Byte],
  seckey : FixedArray[Byte],
) -> Int = "secp256k1_ec_pubkey_create"

///|
/// 序列化公钥
/// output: 输出缓冲区（65 或 33 字节）
/// outputlen: 输入/输出长度（数组，1个元素）
/// pubkey: 64 字节内部格式公钥
/// flags: SECP256K1_EC_COMPRESSED 或 SECP256K1_EC_UNCOMPRESSED
/// 返回: 1 成功, 0 失败
pub extern "C" fn secp256k1_ec_pubkey_serialize(
  ctx : Secp256k1Context,
  output : FixedArray[Byte],
  outputlen : FixedArray[UInt],
  pubkey : FixedArray[Byte],
  flags : Int,
) -> Int = "secp256k1_ec_pubkey_serialize"

// 签名相关的 FFI 函数已移至 sign_impl.mbt

// 公钥恢复相关的 FFI 函数将在 recovery_impl.mbt 中声明

///|
test "ffi correct syntax" {
  // 如果能编译，说明 FFI 语法正确
  inspect(true, content="true")
}
