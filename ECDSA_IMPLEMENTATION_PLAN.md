# 🔐 ECDSA 实现计划

## ✅ 第一步：基础架构（已完成）

```
✅ ecdsa/types.mbt       - 核心类型定义
✅ ecdsa/secp256k1.mbt   - 曲线参数
✅ ecdsa/random.mbt      - 随机数生成框架
✅ ecdsa/keypair.mbt     - 密钥对管理框架
✅ ecdsa/README.md       - 模块文档
```

## 🎯 关键决策：实现方案

### ⭐ 推荐：方案 A - FFI 到 libsecp256k1

#### 为什么选择这个方案？

1. **安全性** 🔒
   - libsecp256k1 经过 Bitcoin Core 多年实战检验
   - 经过专业安全审计
   - 防侧信道攻击优化

2. **性能** ⚡
   - 高度优化的 C 代码
   - 使用汇编加速关键路径
   - 比纯脚本语言实现快 10-100 倍

3. **开发速度** 🚀
   - 只需要写 FFI 绑定层
   - 1-2 周可以完成
   - 立即可用，无需造轮子

4. **兼容性** ✅
   - 与 go-ethereum 使用相同的底层库
   - 结果完全一致

#### 实现步骤

**Week 1: FFI 绑定层**

```moonbit
// ecdsa/ffi.mbt

// 上下文管理
extern "C" fn secp256k1_context_create(flags: Int) -> Ptr
extern "C" fn secp256k1_context_destroy(ctx: Ptr) -> Unit

// 公钥操作
extern "C" fn secp256k1_ec_pubkey_create(
  ctx: Ptr,
  pubkey: Ptr,      // 输出：64 字节
  seckey: Ptr       // 输入：32 字节私钥
) -> Int

extern "C" fn secp256k1_ec_pubkey_serialize(
  ctx: Ptr,
  output: Ptr,      // 输出：33 或 65 字节
  outputlen: Ptr,   // 输入/输出：长度
  pubkey: Ptr,      // 输入：64 字节公钥
  flags: Int        // 压缩/未压缩标志
) -> Int

// 签名操作
extern "C" fn secp256k1_ecdsa_sign_recoverable(
  ctx: Ptr,
  sig: Ptr,         // 输出：签名
  msg32: Ptr,       // 输入：32 字节消息哈希
  seckey: Ptr,      // 输入：32 字节私钥
  noncefp: Ptr,     // nonce 生成函数（NULL = RFC6979）
  ndata: Ptr        // nonce 数据
) -> Int

// 验证操作
extern "C" fn secp256k1_ecdsa_verify(
  ctx: Ptr,
  sig: Ptr,         // 输入：签名
  msg32: Ptr,       // 输入：32 字节消息哈希
  pubkey: Ptr       // 输入：公钥
) -> Int

// 公钥恢复（以太坊特有）
extern "C" fn secp256k1_ecdsa_recover(
  ctx: Ptr,
  pubkey: Ptr,      // 输出：恢复的公钥
  sig: Ptr,         // 输入：可恢复签名
  msg32: Ptr        // 输入：32 字节消息哈希
) -> Int
```

**Week 2: MoonBit 包装层**

```moonbit
// ecdsa/sign.mbt

pub fn sign(
  message_hash: FixedArray[Byte],
  private_key: PrivateKey
) -> ECDSAResult[Signature] {
  // 1. 验证输入
  if message_hash.length() != 32 {
    return Err(InvalidSignature("Message hash must be 32 bytes"))
  }
  
  // 2. 创建 secp256k1 上下文
  let ctx = create_context()
  
  // 3. 调用 FFI 签名函数
  let result = ffi_sign(ctx, message_hash, private_key.to_bytes())
  
  // 4. 解析结果
  match result {
    Ok((r, s, v)) => {
      destroy_context(ctx)
      Signature::new(r, s, v)
    }
    Err(e) => {
      destroy_context(ctx)
      Err(e)
    }
  }
}
```

#### 依赖设置

**Linux/macOS**:
```bash
# 安装 libsecp256k1
# Ubuntu/Debian
sudo apt-get install libsecp256k1-dev

# macOS
brew install secp256k1

# 或者从源码编译
git clone https://github.com/bitcoin-core/secp256k1
cd secp256k1
./autogen.sh
./configure
make
sudo make install
```

**moon.pkg.json 配置**:
```json
{
  "link": {
    "c": ["-lsecp256k1"]
  }
}
```

---

### 方案 B - 纯 MoonBit 实现（备选）

如果 FFI 不可行，需要实现：

#### Phase 1: 大整数库（2-3 周）

```moonbit
// bigint/
├── types.mbt          - BigInt 类型
├── arithmetic.mbt     - 加减乘
├── division.mbt       - 除法和模运算
├── modular.mbt        - 模运算优化
└── montgomery.mbt     - Montgomery 乘法
```

核心运算：
- 256 位整数加法
- 256 位整数乘法
- 模运算（mod p, mod n）
- 模逆运算（扩展欧几里得算法）

#### Phase 2: 椭圆曲线算术（2-3 周）

```moonbit
// ecdsa/curve/
├── point.mbt          - 点运算
├── scalar.mbt         - 标量乘法
└── jacobian.mbt       - Jacobian 坐标优化
```

核心算法：
- 点加法（P + Q）
- 点倍乘（2P）
- 标量乘法（kP）- 使用窗口法优化
- 坐标转换（Affine ↔ Jacobian）

#### Phase 3: ECDSA 算法（1 周）

```moonbit
// ecdsa/
├── sign.mbt           - 签名实现
├── verify.mbt         - 验证实现
└── recovery.mbt       - 公钥恢复
```

**预计总工作量**: 5-7 周

---

## 🚀 推荐路线：方案 A

### Week 1: FFI 绑定

**Day 1-2**: 研究 libsecp256k1 API
- 阅读官方文档
- 理解函数签名
- 准备测试数据

**Day 3-4**: 实现 FFI 绑定
- `ffi.mbt` - 外部函数声明
- `context.mbt` - 上下文管理
- 编译测试

**Day 5-7**: 包装层
- `sign.mbt` - 签名实现
- `verify.mbt` - 验证实现
- 错误处理

### Week 2: 完善功能

**Day 1-2**: 公钥恢复
- `recovery.mbt` - 实现恢复算法
- 测试以太坊兼容性

**Day 3-4**: 密钥生成
- 完善 `random.mbt`
- 实现 `derive_public_key`
- 完善 `generate_keypair`

**Day 5-7**: 测试和文档
- 单元测试
- 集成测试
- 使用示例

---

## 📋 检查清单

### FFI 方案

- [ ] 安装 libsecp256k1
- [ ] 验证 MoonBit FFI 支持
- [ ] 实现基础 FFI 绑定
- [ ] 实现上下文管理
- [ ] 实现公钥派生
- [ ] 实现签名功能
- [ ] 实现验证功能
- [ ] 实现公钥恢复
- [ ] 编写测试用例
- [ ] 与 go-ethereum 对比测试

### 纯 MoonBit 方案（如果需要）

- [ ] 实现 BigInt 类型
- [ ] 实现基础算术
- [ ] 实现模运算
- [ ] 实现模逆
- [ ] 实现点加法
- [ ] 实现点倍乘
- [ ] 实现标量乘法
- [ ] 实现 ECDSA 签名
- [ ] 实现 ECDSA 验证
- [ ] 实现公钥恢复

---

## 🧪 测试策略

### 1. 单元测试

```moonbit
test "private key validation" {
  // 测试私钥范围检查
}

test "public key derivation" {
  // 测试公钥派生正确性
}

test "signature creation" {
  // 测试签名生成
}

test "signature verification" {
  // 测试签名验证
}

test "public key recovery" {
  // 测试公钥恢复
}
```

### 2. 官方测试向量

使用标准测试向量：
- RFC 6979 测试向量
- go-ethereum crypto 测试
- Bitcoin Core 测试

### 3. 兼容性测试

与其他实现对比：
```moonbit
// 生成相同的密钥对
// 签名相同的消息
// 验证结果一致
```

---

## 📖 学习资源

### 必读

1. **libsecp256k1 文档**
   - [GitHub](https://github.com/bitcoin-core/secp256k1)
   - [API 文档](https://github.com/bitcoin-core/secp256k1/blob/master/include/secp256k1.h)

2. **椭圆曲线密码学**
   - [SEC 2 标准](https://www.secg.org/sec2-v2.pdf)
   - [RFC 6979](https://tools.ietf.org/html/rfc6979)

3. **以太坊特定**
   - [黄皮书 - 附录 F](https://ethereum.github.io/yellowpaper/paper.pdf)
   - [go-ethereum crypto 包](https://github.com/ethereum/go-ethereum/tree/master/crypto)

### 推荐

- [Understanding Elliptic Curve Cryptography](https://andrea.corbellini.name/2015/05/17/elliptic-curve-cryptography-a-gentle-introduction/)
- [ECDSA 算法详解](https://en.wikipedia.org/wiki/Elliptic_Curve_Digital_Signature_Algorithm)

---

## 🎯 成功标准

完成后应该能够：

1. ✅ 生成密码学安全的密钥对
2. ✅ 从私钥派生公钥
3. ✅ 签名任意 32 字节哈希
4. ✅ 验证签名的有效性
5. ✅ 从签名恢复公钥（以太坊）
6. ✅ 通过所有官方测试向量
7. ✅ 与 go-ethereum 结果完全一致

---

## 🚦 下一步行动

### 立即开始

1. **验证 FFI 支持**
   ```bash
   # 检查 MoonBit 是否支持 FFI
   moon --help | grep ffi
   ```

2. **安装 libsecp256k1**
   ```bash
   # Ubuntu/Debian
   sudo apt-get install libsecp256k1-dev
   
   # 或从源码编译
   git clone https://github.com/bitcoin-core/secp256k1
   cd secp256k1
   ./autogen.sh && ./configure && make
   ```

3. **创建第一个 FFI 绑定**
   ```moonbit
   // 测试 FFI 是否工作
   extern "C" fn secp256k1_context_create(flags: Int) -> Ptr
   
   test "ffi basic" {
     let ctx = secp256k1_context_create(1)
     // 验证上下文创建成功
   }
   ```

准备好了吗？我们可以立即开始实现 FFI 绑定层！🚀

