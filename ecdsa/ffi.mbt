///|
/// FFI 绑定到 libsecp256k1（占位符版本）
/// 
/// 状态：等待 MoonBit FFI Ptr 支持成熟
/// 
/// 当前问题：
/// 1. Ptr 类型在 MoonBit 中尚不可用
/// 2. 无法将 FixedArray[Byte] 转换为 C 指针
/// 3. extern "C" 函数声明需要完整的 Ptr 支持
/// 
/// 下一步：
/// - 方案 A: 等待 MoonBit 官方完善 FFI Ptr 支持
/// - 方案 B: 使用 WASM FFI 桥接（通过 Rust k256 crate）
/// - 方案 C: 实现纯 MoonBit 版本（长期项目）
/// 
/// 详见：FFI_ROADMAP.md

///|
/// secp256k1 上下文类型（占位符）
/// 实际应该是指向 C secp256k1_context 的指针
pub type Secp256k1Ctx = Int // 临时使用 Int 作为占位符

///|
/// 上下文创建标志
pub const SECP256K1_CONTEXT_NONE : Int = 0x01

///|
pub const SECP256K1_CONTEXT_VERIFY : Int = 0x0101

///|
pub const SECP256K1_CONTEXT_SIGN : Int = 0x0201

///|
/// 公钥序列化标志
pub const SECP256K1_EC_COMPRESSED : Int = 0x0102

///|
pub const SECP256K1_EC_UNCOMPRESSED : Int = 0x0002

///|
/// 以下是完整的 FFI 函数声明（待实现）
/// 
/// 一旦 MoonBit 支持 Ptr 类型，可以取消注释并使用

// ///|
// /// 上下文管理
// extern "C" fn secp256k1_context_create(flags : Int) -> Ptr

// extern "C" fn secp256k1_context_destroy(ctx : Ptr) -> Unit

// extern "C" fn secp256k1_context_randomize(
//   ctx : Ptr,
//   seed32 : Ptr
// ) -> Int

// ///|
// /// 公钥操作
// extern "C" fn secp256k1_ec_pubkey_create(
//   ctx : Ptr,
//   pubkey : Ptr,
//   seckey : Ptr
// ) -> Int

// extern "C" fn secp256k1_ec_pubkey_serialize(
//   ctx : Ptr,
//   output : Ptr,
//   outputlen : Ptr,
//   pubkey : Ptr,
//   flags : Int
// ) -> Int

// extern "C" fn secp256k1_ec_pubkey_parse(
//   ctx : Ptr,
//   pubkey : Ptr,
//   input : Ptr,
//   inputlen : Int
// ) -> Int

// ///|
// /// ECDSA 签名操作
// extern "C" fn secp256k1_ecdsa_sign_recoverable(
//   ctx : Ptr,
//   sig : Ptr,
//   msg32 : Ptr,
//   seckey : Ptr,
//   noncefp : Ptr,
//   ndata : Ptr
// ) -> Int

// extern "C" fn secp256k1_ecdsa_verify(
//   ctx : Ptr,
//   sig : Ptr,
//   msg32 : Ptr,
//   pubkey : Ptr
// ) -> Int

// extern "C" fn secp256k1_ecdsa_signature_serialize_compact(
//   ctx : Ptr,
//   output64 : Ptr,
//   sig : Ptr
// ) -> Int

// extern "C" fn secp256k1_ecdsa_signature_parse_compact(
//   ctx : Ptr,
//   sig : Ptr,
//   input64 : Ptr
// ) -> Int

// ///|
// /// 公钥恢复操作
// extern "C" fn secp256k1_ecdsa_recoverable_signature_serialize_compact(
//   ctx : Ptr,
//   output64 : Ptr,
//   recid : Ptr,
//   sig : Ptr
// ) -> Int

// extern "C" fn secp256k1_ecdsa_recoverable_signature_parse_compact(
//   ctx : Ptr,
//   sig : Ptr,
//   input64 : Ptr,
//   recid : Int
// ) -> Int

// extern "C" fn secp256k1_ecdsa_recover(
//   ctx : Ptr,
//   pubkey : Ptr,
//   sig : Ptr,
//   msg32 : Ptr
// ) -> Int
