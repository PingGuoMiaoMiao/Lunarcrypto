# ECDSA (secp256k1) 模块

实现以太坊和比特币使用的 secp256k1 椭圆曲线数字签名算法。

## 状态

🚧 **开发中** - 基础架构已搭建，核心算法待实现

## 模块结构

```
ecdsa/
├── types.mbt          ✅ 类型定义（PrivateKey, PublicKey, Signature）
├── secp256k1.mbt      ✅ 曲线参数和常量
├── random.mbt         🚧 随机数生成（需要实现）
├── keypair.mbt        🚧 密钥对生成（需要实现）
├── sign.mbt           ⏳ 待创建 - 签名功能
├── verify.mbt         ⏳ 待创建 - 验证功能
└── recovery.mbt       ⏳ 待创建 - 公钥恢复
```

## 核心功能

### ✅ 已实现

```moonbit
// 类型定义
PrivateKey::from_bytes(bytes) -> Result[PrivateKey]
PublicKey::from_bytes(bytes) -> Result[PublicKey]
Signature::new(r, s, v) -> Result[Signature]

// 曲线参数
CURVE_P, CURVE_N, GENERATOR_X, GENERATOR_Y
```

### 🚧 需要实现

#### 1. 椭圆曲线算术（最核心）

```moonbit
// 点运算
fn point_add(p1: Point, p2: Point) -> Point
fn point_double(p: Point) -> Point
fn point_multiply(point: Point, scalar: BigInt) -> Point

// 模运算
fn mod_add(a: BigInt, b: BigInt, modulus: BigInt) -> BigInt
fn mod_multiply(a: BigInt, b: BigInt, modulus: BigInt) -> BigInt
fn mod_inverse(a: BigInt, modulus: BigInt) -> BigInt
```

#### 2. 密钥生成

```moonbit
pub fn generate_keypair() -> Result[KeyPair]
pub fn derive_public_key(private_key: PrivateKey) -> Result[PublicKey]
```

#### 3. 签名

```moonbit
pub fn sign(
  message_hash: FixedArray[Byte],
  private_key: PrivateKey
) -> Result[Signature]
```

#### 4. 验证

```moonbit
pub fn verify(
  message_hash: FixedArray[Byte],
  signature: Signature,
  public_key: PublicKey
) -> Bool
```

#### 5. 公钥恢复（以太坊特有）

```moonbit
pub fn recover_public_key(
  message_hash: FixedArray[Byte],
  signature: Signature
) -> Result[PublicKey]
```

## 实现方案

### 方案 A: FFI 绑定到 libsecp256k1（推荐）⭐

**优点**:
- ✅ 经过充分测试和审计
- ✅ 性能优秀（高度优化的 C 代码）
- ✅ 开发速度快
- ✅ 安全性有保障

**缺点**:
- ❌ 需要 FFI 支持
- ❌ 增加外部依赖

**实现**:
```moonbit
// 使用 libsecp256k1 的 C API
extern "C" fn secp256k1_context_create(flags: Int) -> Ptr
extern "C" fn secp256k1_ec_pubkey_create(...) -> Int
extern "C" fn secp256k1_ecdsa_sign(...) -> Int
extern "C" fn secp256k1_ecdsa_verify(...) -> Int
extern "C" fn secp256k1_ecdsa_recover(...) -> Int
```

### 方案 B: 纯 MoonBit 实现

**优点**:
- ✅ 无外部依赖
- ✅ 完全可移植
- ✅ 学习价值高

**缺点**:
- ❌ 工作量巨大（需要实现大整数运算）
- ❌ 性能可能较差
- ❌ 安全审计困难

**需要实现**:
1. 大整数算术库（256位以上）
2. 模运算优化
3. 椭圆曲线点运算
4. 常数时间算法（防止侧信道攻击）

### 方案 C: 混合方案

**核心算法用 FFI，辅助功能纯 MoonBit**

## 使用示例（目标 API）

```moonbit
// 生成密钥对
let keypair = generate_keypair()?

// 签名消息哈希
let message_hash = keccak256(message)
let signature = sign(message_hash, keypair.private_key())?

// 验证签名
let valid = verify(message_hash, signature, keypair.public_key())

// 恢复公钥（以太坊）
let recovered = recover_public_key(message_hash, signature)?
```

## 下一步

### 立即任务

1. **决定实现方案**（推荐方案 A: FFI）
2. **实现大整数库或 FFI 绑定**
3. **实现椭圆曲线基础运算**

### 测试向量

使用官方测试向量验证：
- RFC 6979 (确定性 ECDSA)
- go-ethereum crypto 测试
- bitcoinj 测试向量

## 参考资源

- [SEC 2: Recommended Elliptic Curve Domain Parameters](https://www.secg.org/sec2-v2.pdf)
- [libsecp256k1](https://github.com/bitcoin-core/secp256k1)
- [RFC 6979: Deterministic ECDSA](https://tools.ietf.org/html/rfc6979)
- [以太坊黄皮书 - ECDSA](https://ethereum.github.io/yellowpaper/paper.pdf)

