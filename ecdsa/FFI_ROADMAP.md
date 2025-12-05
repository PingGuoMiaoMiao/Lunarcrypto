# 🚧 FFI 实现路线图

## 当前状态

- ✅ libsecp256k1 已编译（位于 `/tmp/secp256k1`）
- ✅ FFI 函数声明已创建（`ffi.mbt`）
- ✅ 上下文管理已创建（`context.mbt`）
- ⏳ 等待安装 libsecp256k1 到系统
- ⏳ 等待 MoonBit `Ptr` 类型支持成熟

## 问题分析

### 问题 1: Ptr 类型不可用

MoonBit 当前的 FFI 支持中，`Ptr` 类型还不能直接使用。我们需要：

```moonbit
// 当前错误：
extern "C" fn secp256k1_context_create(flags : Int) -> Secp256k1Ctx

// Ptr 类型未定义，导致编译失败
```

**解决方案**:
1. 等待 MoonBit 官方完善 FFI Ptr 支持
2. 或使用 `UnsafePointer` (如果可用)
3. 或通过 WASM FFI 间接调用

### 问题 2: Option 类型语法

```moonbit
// 错误的写法：
let mut global_context : Secp256k1Ctx? = None

// 正确的写法：
let mut global_context : Option[Secp256k1Ctx] = None
```

### 问题 3: 数组到 Ptr 转换

```moonbit
// 需要将 FixedArray[Byte] 转换为 Ptr
let bytes = FixedArray::make(32, b'\x00')
let ptr = bytes.as_ptr()  // 或 bytes.ptr()
```

## 📋 三个并行方案

### 方案 A: 等待原生 FFI 成熟（推荐长期）

**优势**:
- 最佳性能
- 直接使用 libsecp256k1
- 无中间层开销

**步骤**:
1. ✅ 编译 libsecp256k1
2. ⏳ 安装到系统：`sudo make install && sudo ldconfig`
3. ⏳ 等待 MoonBit Ptr 支持
4. ⏳ 更新 FFI 绑定使用正确的 Ptr 语法
5. ⏳ 实现 FixedArray -> Ptr 转换
6. ⏳ 测试所有功能

**预计时间**: 取决于 MoonBit 更新周期

### 方案 B: WASM FFI 桥接（推荐短期）

创建一个 Rust WASM 模块作为桥接层：

```rust
// secp256k1-bridge/src/lib.rs
use k256::ecdsa::{SigningKey, VerifyingKey, Signature};
use wasm_bindgen::prelude::*;

#[wasm_bindgen]
pub fn sign_message(
    message_hash: &[u8],
    private_key: &[u8],
) -> Vec<u8> {
    // 实现签名
}

#[wasm_bindgen]
pub fn verify_signature(
    message_hash: &[u8],
    signature: &[u8],
    public_key: &[u8],
) -> bool {
    // 实现验证
}

#[wasm_bindgen]
pub fn recover_public_key(
    message_hash: &[u8],
    signature: &[u8],
) -> Vec<u8> {
    // 实现公钥恢复
}
```

然后在 MoonBit 中调用：

```moonbit
// ecdsa/wasm_bridge.mbt
extern "wasm" fn sign_message(
  message_hash: FixedArray[Byte],
  private_key: FixedArray[Byte]
) -> FixedArray[Byte]

pub fn sign(
  message_hash: FixedArray[Byte],
  private_key: PrivateKey
) -> ECDSAResult[Signature] {
  let result = sign_message(message_hash, private_key.to_bytes())
  // 解析结果...
}
```

**优势**:
- 立即可用
- 使用成熟的 k256 库
- WASM 性能可接受

**步骤**:
1. 创建 Rust WASM 项目
2. 实现桥接函数
3. 编译为 WASM
4. 在 MoonBit 中声明和调用
5. 测试

**预计时间**: 2-3 天

### 方案 C: 纯 MoonBit 实现（长期项目）

实现完整的大整数和椭圆曲线运算。

**优势**:
- 完全自主
- 无依赖

**缺点**:
- 工作量巨大（6-8 周）
- 性能较差
- 安全审计困难

## 🎯 推荐行动计划

### 立即行动（本周）

1. **安装 libsecp256k1**:
```bash
cd /tmp/secp256k1
sudo make install
sudo ldconfig
```

2. **验证安装**:
```bash
pkg-config --modversion libsecp256k1
```

3. **修复编译错误**:
- 修复 Option 类型语法
- 暂时注释掉 FFI 调用
- 保持接口可用

### 短期目标（1-2 周）

4. **调研 MoonBit FFI 状态**:
- 查看 MoonBit 官方文档
- 测试 Ptr 类型是否可用
- 如果不可用，切换到方案 B

5. **实现 WASM 桥接**（如果必要）:
```bash
mkdir secp256k1-bridge
cd secp256k1-bridge
cargo init --lib
# 添加依赖并实现
```

### 中期目标（1 个月）

6. **完成 ECDSA 功能**:
- 签名
- 验证
- 公钥恢复
- 公钥派生

7. **测试和验证**:
- 单元测试
- 与 go-ethereum 对比
- 性能测试

## 📝 当前任务优先级

### P0 - 立即（今天）

- [ ] 安装 libsecp256k1 到系统
- [ ] 修复 context.mbt Option 语法
- [ ] 让代码编译通过（临时注释 FFI 调用）

### P1 - 本周

- [ ] 调研 MoonBit FFI Ptr 支持状态
- [ ] 决定使用方案 A 还是方案 B
- [ ] 如果选 B，创建 WASM 桥接项目

### P2 - 下周

- [ ] 实现完整的签名/验证功能
- [ ] 编写测试用例
- [ ] 验证与 go-ethereum 兼容性

## 🔍 技术调研需求

### MoonBit FFI 状态查询

需要查询：
1. `Ptr` 类型是否可用？
2. 如何将 `FixedArray[Byte]` 转换为 C 指针？
3. 如何接收 C 指针并转换回 `FixedArray[Byte]`？
4. 是否有 `UnsafePointer` 或类似类型？
5. extern "C" 函数的完整语法？

### 资源

- [MoonBit 官方文档](https://www.moonbitlang.com/docs/)
- [MoonBit GitHub](https://github.com/moonbitlang)
- MoonBit 社区论坛/Discord

## 📖 代码示例（期望的 FFI 语法）

```moonbit
// 理想情况下的 FFI 绑定

///|
/// 假设 Ptr 类型可用
pub type Ptr

///|
/// 从数组获取指针
pub fn FixedArray::as_ptr[T](self : FixedArray[T]) -> Ptr

///|
/// FFI 函数声明
extern "C" fn secp256k1_context_create(
  #owned flags : Int
) -> Ptr

extern "C" fn secp256k1_ec_pubkey_create(
  #borrow ctx : Ptr,
  #owned pubkey : Ptr,
  #borrow seckey : Ptr
) -> Int

///|
/// 调用示例
pub fn create_pubkey(private_key : PrivateKey) -> ECDSAResult[PublicKey] {
  let ctx = secp256k1_context_create(SECP256K1_CONTEXT_SIGN)
  let pubkey_buf = FixedArray::make(64, b'\x00')
  
  let result = secp256k1_ec_pubkey_create(
    ctx,
    pubkey_buf.as_ptr(),
    private_key.to_bytes().as_ptr()
  )
  
  if result == 1 {
    // 序列化公钥...
  } else {
    Err(InvalidPrivateKey("Failed to create public key"))
  }
}
```

## 🎉 成功标准

完成后应该能够：

```moonbit
// 生成密钥对
let keypair = generate_keypair()?

// 签名
let message = "Hello Ethereum"
let hash = keccak256(message.to_bytes())
let signature = sign(hash, keypair.get_private_key())?

// 验证
assert!(verify(hash, signature, keypair.get_public_key()))

// 恢复公钥
let recovered = recover_public_key(hash, signature)?
assert_eq!(recovered, keypair.get_public_key())

// 获取地址
let address = public_key_to_ethereum_address(keypair.get_public_key())?
println("Address: \{to_checksum_address(address)}")
```

---

**下一步：安装 libsecp256k1，然后决定实现路径！** 🚀

