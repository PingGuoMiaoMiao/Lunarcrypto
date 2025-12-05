# 🚀 Lunarcrypto 下一步实施指南

## ✅ 当前进度

```
✅ RLP 模块          - 完全实现（956 行代码）
✅ LunarKeccak256    - 已有实现
✅ ECDSA 基础架构    - 已搭建（类型、常量、框架）
```

## 🎯 ECDSA 实现：三条路径

### 路径 A: FFI 到 libsecp256k1（推荐）⭐⭐⭐

**时间**: 1-2 周  
**难度**: 中等  
**优势**: 安全、高效、快速

#### 立即开始步骤

**步骤 1: 验证 MoonBit FFI 支持**

```bash
# 检查 MoonBit FFI 文档
moon --help | grep -i ffi

# 查看示例
ls /home/pingguomiaomiao/.moon/lib/core/ | grep -i ffi
```

**步骤 2: 安装 libsecp256k1**

```bash
# Ubuntu/Debian
sudo apt-get update
sudo apt-get install -y libsecp256k1-dev

# 验证安装
ldconfig -p | grep secp256k1

# 或从源码编译
git clone https://github.com/bitcoin-core/secp256k1.git
cd secp256k1
./autogen.sh
./configure --enable-module-recovery
make
sudo make install
sudo ldconfig
```

**步骤 3: 创建 FFI 绑定**

```moonbit
// ecdsa/ffi.mbt

///| secp256k1 上下文类型
pub type Secp256k1Context  // 不透明指针类型

///| 上下文标志
pub const SECP256K1_CONTEXT_SIGN : Int = 0x0201
pub const SECP256K1_CONTEXT_VERIFY : Int = 0x0101

///| 压缩标志
pub const SECP256K1_EC_UNCOMPRESSED : Int = 0
pub const SECP256K1_EC_COMPRESSED : Int = 0x0102

///| FFI 函数声明
extern "C" fn secp256k1_context_create(flags: Int) -> Secp256k1Context

extern "C" fn secp256k1_context_destroy(ctx: Secp256k1Context) -> Unit

extern "C" fn secp256k1_ec_pubkey_create(
  ctx: Secp256k1Context,
  pubkey: FixedArray[Byte],    // 输出：64 字节内部格式
  seckey: FixedArray[Byte]     // 输入：32 字节私钥
) -> Int  // 返回 1 成功，0 失败

extern "C" fn secp256k1_ecdsa_sign_recoverable(
  ctx: Secp256k1Context,
  sig: FixedArray[Byte],       // 输出：65 字节签名
  msg32: FixedArray[Byte],     // 输入：32 字节哈希
  seckey: FixedArray[Byte],    // 输入：32 字节私钥
  noncefp: Int,                // NULL 指针（使用 RFC6979）
  ndata: Int                   // NULL 指针
) -> Int

extern "C" fn secp256k1_ecdsa_verify(
  ctx: Secp256k1Context,
  sig: FixedArray[Byte],       // 输入：64 字节签名
  msg32: FixedArray[Byte],     // 输入：32 字节哈希
  pubkey: FixedArray[Byte]     // 输入：64 字节公钥
) -> Int

extern "C" fn secp256k1_ecdsa_recover(
  ctx: Secp256k1Context,
  pubkey: FixedArray[Byte],    // 输出：64 字节公钥
  sig: FixedArray[Byte],       // 输入：65 字节可恢复签名
  msg32: FixedArray[Byte]      // 输入：32 字节哈希
) -> Int
```

**步骤 4: 实现包装层**

```moonbit
// ecdsa/sign.mbt

pub fn sign(
  message_hash: FixedArray[Byte],
  private_key: PrivateKey
) -> ECDSAResult[Signature] {
  if message_hash.length() != 32 {
    return Err(InvalidSignature("Message hash must be 32 bytes"))
  }
  
  let ctx = secp256k1_context_create(SECP256K1_CONTEXT_SIGN)
  let sig_output = FixedArray::make(65, b'\x00')
  
  let result_code = secp256k1_ecdsa_sign_recoverable(
    ctx,
    sig_output,
    message_hash,
    private_key.to_bytes(),
    0,  // NULL
    0   // NULL
  )
  
  secp256k1_context_destroy(ctx)
  
  if result_code == 1 {
    // 解析签名
    let r = FixedArray::make(32, b'\x00')
    let s = FixedArray::make(32, b'\x00')
    for i = 0; i < 32; i = i + 1 {
      r[i] = sig_output[i]
      s[i] = sig_output[32 + i]
    }
    let v = sig_output[64].to_int()
    
    Signature::new(r, s, v)
  } else {
    Err(InvalidSignature("Signature creation failed"))
  }
}
```

**步骤 5: 配置编译**

```json
// ecdsa/moon.pkg.json
{
  "is_main": false,
  "import": [],
  "link": {
    "c": ["-lsecp256k1"]
  }
}
```

---

### 路径 B: 使用现有 Rust/WASM 库

**时间**: 1 周  
**难度**: 低  
**优势**: 快速、现代

#### 方案

使用 `k256` 或 `secp256k1` Rust crate 编译为 WASM，通过 MoonBit 的 WASM FFI 调用。

```rust
// secp256k1-wasm/src/lib.rs

use k256::ecdsa::{SigningKey, VerifyingKey, Signature};

#[no_mangle]
pub extern "C" fn secp256k1_sign(
    message: *const u8,
    private_key: *const u8,
    signature_out: *mut u8,
) -> i32 {
    // 实现签名逻辑
}
```

---

### 路径 C: 纯 MoonBit 实现

**时间**: 6-8 周  
**难度**: 很高  
**优势**: 完全可控、教育价值

#### 需要实现的组件

**Week 1-2: 大整数库**
```moonbit
// bigint/types.mbt
pub struct BigInt {
  limbs: Array[UInt64]  // 使用 64 位肢体
  sign: Bool            // 正负号
}

// 基础运算
pub fn BigInt::add(a: BigInt, b: BigInt) -> BigInt
pub fn BigInt::sub(a: BigInt, b: BigInt) -> BigInt
pub fn BigInt::mul(a: BigInt, b: BigInt) -> BigInt
pub fn BigInt::div(a: BigInt, b: BigInt) -> (BigInt, BigInt)
```

**Week 3-4: 模运算**
```moonbit
// bigint/modular.mbt
pub fn mod_add(a: BigInt, b: BigInt, m: BigInt) -> BigInt
pub fn mod_sub(a: BigInt, b: BigInt, m: BigInt) -> BigInt
pub fn mod_mul(a: BigInt, b: BigInt, m: BigInt) -> BigInt
pub fn mod_inverse(a: BigInt, m: BigInt) -> Option[BigInt]  // 扩展欧几里得
pub fn mod_exp(base: BigInt, exp: BigInt, m: BigInt) -> BigInt  // 快速幂
```

**Week 5-6: 椭圆曲线**
```moonbit
// ecdsa/curve.mbt
pub fn point_add(p1: Point, p2: Point) -> Point
pub fn point_double(p: Point) -> Point
pub fn point_multiply(point: Point, scalar: BigInt) -> Point  // 关键！
```

**Week 7-8: ECDSA**
```moonbit
// ecdsa/sign.mbt & verify.mbt
```

---

## 🎯 我的建议：分阶段实施

### 🔥 立即（本周）：决定实现路径

运行以下命令验证选项：

```bash
# 检查 FFI 支持
cd /home/pingguomiaomiao/Desktop/Lunarcrypto
moon --version
moon --help | grep -i ffi

# 检查是否有 libsecp256k1
which secp256k1
ldconfig -p | grep secp256k1

# 检查 WASM 支持
moon build --target wasm-gc
```

### 🚀 第一里程碑（2-3 周）

**如果选择 FFI 路径**:
- [ ] Week 1: FFI 绑定完成
- [ ] Week 2: 签名/验证测试通过
- [ ] Week 3: 与 go-ethereum 对齐测试

**如果选择 WASM 路径**:
- [ ] Week 1: Rust WASM 模块
- [ ] Week 2: MoonBit 绑定
- [ ] Week 3: 集成测试

**如果选择纯实现**:
- [ ] Week 1-2: BigInt 基础
- [ ] Week 3: 模运算测试通过

---

## 📦 同时进行：地址生成模块（可并行开发）

即使 ECDSA 未完成，地址生成的接口可以先定义：

```moonbit
// address/
├── types.mbt
├── generator.mbt
└── checksum.mbt

// 核心 API
pub fn public_key_to_address(public_key: PublicKey) -> Address {
  // 1. 获取公钥的 64 字节（x, y 坐标）
  let coords = public_key.get_coordinates()?
  
  // 2. Keccak256 哈希
  let hash = keccak256(coords)  // ✅ 已有实现
  
  // 3. 取后 20 字节
  let addr_bytes = slice_bytes(hash, 12, 32)
  
  Address { bytes: addr_bytes }
}

pub fn to_checksum_address(address: Address) -> String {
  // EIP-55: 混合大小写校验和
  let hex = bytes_to_hex(address.bytes)
  let hash = keccak256(hex.to_bytes())
  
  // 根据哈希值决定大小写
  let mut result = "0x"
  for i = 0; i < 40; i = i + 1 {
    let c = hex[i]
    if hash[i / 2].to_int() >> (if i % 2 == 0 { 4 } else { 0 }) & 0x0F >= 8 {
      result = result + c.to_upper_case()
    } else {
      result = result + c.to_lower_case()
    }
  }
  result
}
```

---

## 📊 里程碑和交付物

### Milestone 1: ECDSA 完成（2-3 周）

**交付**:
- ✅ 密钥对生成
- ✅ 公钥派生
- ✅ 消息签名
- ✅ 签名验证
- ✅ 公钥恢复
- ✅ 与 go-ethereum 完全兼容

**验收标准**:
```moonbit
test "ecdsa compatibility" {
  let private_key = PrivateKey::from_hex("...")
  let message = "Hello Ethereum"
  let hash = keccak256(message)
  let signature = sign(hash, private_key)?
  
  // 应该与 go-ethereum 签名完全相同
  assert_eq(signature.to_hex(), "0x...")
}
```

### Milestone 2: 地址生成（3-5 天）

**交付**:
- ✅ 公钥到地址转换
- ✅ EIP-55 校验和
- ✅ 地址验证

**示例**:
```moonbit
let address = public_key_to_address(public_key)
println(to_checksum_address(address))
// 输出: "0x742d35Cc6634C0532925a3b844Bc9e7595f0bEb"
```

### Milestone 3: 交易签名（1 周）

**交付**:
- ✅ Legacy 交易编码
- ✅ EIP-155 签名
- ✅ 交易哈希计算

**示例**:
```moonbit
let tx = LegacyTransaction {
  nonce: 0UL,
  gas_price: 20000000000UL,
  gas_limit: 21000UL,
  to: Some(to_address),
  value: 1000000000000000000UL,
  data: FixedArray::make(0, b'\x00'),
  v: 0UL, r: FixedArray::make(0, b'\x00'), s: FixedArray::make(0, b'\x00')
}

let signed = sign_transaction(tx, private_key, 1)  // chain_id = 1
```

---

## 🛠️ 技术准备

### 需要研究的内容

1. **MoonBit FFI 文档**
   - 如何声明 extern 函数
   - 如何传递指针/数组
   - 如何处理返回值

2. **libsecp256k1 API**
   - [官方头文件](https://github.com/bitcoin-core/secp256k1/blob/master/include/secp256k1.h)
   - [恢复模块](https://github.com/bitcoin-core/secp256k1/blob/master/include/secp256k1_recovery.h)

3. **测试数据**
   - [go-ethereum 测试向量](https://github.com/ethereum/go-ethereum/blob/master/crypto/secp256k1/secp256k1_test.go)
   - [RFC 6979 测试向量](https://tools.ietf.org/html/rfc6979#appendix-A.2.5)

---

## 📋 任务清单

### 本周任务

- [ ] 验证 MoonBit FFI 能力
- [ ] 安装 libsecp256k1
- [ ] 创建简单的 FFI 测试（调用 context_create/destroy）
- [ ] 研究 libsecp256k1 API 文档

### Week 2 任务

- [ ] 实现 FFI 绑定层（所有函数声明）
- [ ] 实现上下文管理
- [ ] 实现公钥派生
- [ ] 编写单元测试

### Week 3 任务

- [ ] 实现签名功能
- [ ] 实现验证功能  
- [ ] 实现公钥恢复
- [ ] 与 go-ethereum 对比测试

---

## 🧪 测试策略

### 测试向量来源

1. **官方测试**
   ```moonbit
   test "official test vector 1" {
     // 来自 RFC 6979
     let private_key = "0xC9AFA9D845BA75166B5C215767B1D6934E50C3DB36E89B127B8A622B120F6721"
     let message = "sample"
     let expected_r = "0xEFD48B2AACB6A8FD1140DD9CD45E81D69D2C877B56AAF991C34D0EA84EAF3716"
     // ...
   }
   ```

2. **go-ethereum 兼容性**
   ```moonbit
   test "geth compatibility" {
     // 使用 go-ethereum 的测试数据
     // 确保字节级一致
   }
   ```

3. **边界情况**
   ```moonbit
   test "edge cases" {
     // 全零私钥（应该失败）
     // 全 1 私钥
     // 边界值测试
   }
   ```

---

## 🎉 1 个月后的目标

完成后你将拥有：

```moonbit
// 完整的以太坊工具链

// 1. 生成钱包
let keypair = generate_keypair()?
let address = public_key_to_address(keypair.get_public_key())
println("Your address: \{to_checksum_address(address)}")

// 2. 签名消息
let message = "Hello Ethereum"
let hash = keccak256(message.to_bytes())
let signature = sign(hash, keypair.get_private_key())?

// 3. 构造交易
let tx = create_transfer_transaction(
  from: address,
  to: recipient,
  value: 1000000000000000000UL,  // 1 ETH
  nonce: 0UL,
  gas_price: 20000000000UL,
  chain_id: 1UL
)

// 4. 签名交易
let signed_tx = sign_transaction(tx, keypair.get_private_key())?

// 5. 获取原始交易数据
let raw_tx = encode_transaction(signed_tx)
let tx_hex = bytes_to_hex(raw_tx)
println("Raw transaction: \{tx_hex}")

// 6. 发送交易（通过 RPC）
// let tx_hash = eth_send_raw_transaction(raw_tx)?
```

---

## 🚦 立即行动

### 现在就做：

1. **运行验证命令**:
```bash
cd /home/pingguomiaomiao/Desktop/Lunarcrypto
moon --help | grep -i ffi
which pkg-config
pkg-config --list-all | grep secp256k1
```

2. **安装依赖**:
```bash
sudo apt-get install -y libsecp256k1-dev pkg-config
```

3. **创建第一个 FFI 测试**:
```moonbit
// ecdsa/ffi_test.mbt
test "ffi basic - context create" {
  // 验证能否成功调用 C 函数
}
```

---

## 💡 成功的关键

1. **小步迭代** - 先让最简单的 FFI 调用工作
2. **持续测试** - 每个函数都要有测试
3. **参考实现** - 对照 go-ethereum 的行为
4. **文档先行** - 理解算法再编码

---

**准备好了吗？告诉我你想先从哪个路径开始！** 🚀

建议：**先运行验证命令，看看你的环境支持哪种方案**。

