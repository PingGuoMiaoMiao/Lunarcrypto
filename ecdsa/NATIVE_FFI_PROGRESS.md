# 🚀 Native FFI 实现进度

> **开始日期**: 2025-12-06  
> **方案**: 使用 MoonBit Native FFI 直接调用 libsecp256k1  
> **性能**: ⭐⭐⭐⭐⭐ 最佳（原生 C 调用）

---

## ✅ 已完成

### 1. FFI 基础设施 ✅
- ✅ 正确的 FFI 语法验证
- ✅ `#external` 类型定义
- ✅ extern "C" 函数声明
- ✅ moon.pkg.json 链接配置
- ✅ libsecp256k1 成功链接

### 2. 基础 FFI 绑定 ✅
- ✅ `secp256k1_context_create` - 创建上下文
- ✅ `secp256k1_context_destroy` - 销毁上下文
- ✅ `secp256k1_ec_seckey_verify` - 验证私钥
- ✅ 测试全部通过 (3/3)

---

## 🔧 当前挑战

### 问题：secp256k1_pubkey 结构处理

libsecp256k1 使用内部表示的 `secp256k1_pubkey` 结构（64 字节）：

```c
typedef struct {
    unsigned char data[64];
} secp256k1_pubkey;
```

**MoonBit 中如何处理？**

#### 方案 1: 使用 FixedArray[Byte] 模拟 ⭐（推荐）

```moonbit
// 创建 64 字节缓冲区
let pubkey_internal = FixedArray::make(64, b'\x00')

// 传递给 C 函数
secp256k1_ec_pubkey_create(ctx, pubkey_internal, seckey)

// 序列化为标准格式
let output = FixedArray::make(65, b'\x00')
let outputlen = FixedArray::make(1, 65)
secp256k1_ec_pubkey_serialize(ctx, output, outputlen, pubkey_internal, flags)
```

#### 方案 2: 声明对应的结构体

```moonbit
#external
pub type Secp256k1PubkeyBuffer

// 需要创建缓冲区的辅助函数
```

---

## 🎯 实现计划

### Phase 1: 核心功能（当前）

#### 1.1 公钥派生 ⏳
```moonbit
pub fn derive_public_key(private_key: PrivateKey) -> ECDSAResult[PublicKey]
```

**步骤**:
1. ✅ 创建上下文
2. ✅ 验证私钥
3. ⏳ 创建 pubkey 缓冲区
4. ⏳ 调用 secp256k1_ec_pubkey_create
5. ⏳ 序列化公钥
6. ⏳ 返回 PublicKey

**难点**: 正确处理 secp256k1_pubkey 结构

#### 1.2 签名功能 ⏳
```moonbit
pub fn sign(message_hash: FixedArray[Byte], private_key: PrivateKey) -> ECDSAResult[Signature]
```

**步骤**:
1. 创建上下文
2. 创建 recoverable_signature 缓冲区
3. 调用 secp256k1_ecdsa_sign_recoverable
4. 序列化签名 (r + s + v)
5. 返回 Signature

#### 1.3 验证功能 ⏳
```moonbit
pub fn verify(message_hash: FixedArray[Byte], signature: Signature, public_key: PublicKey) -> Bool
```

**步骤**:
1. 解析公钥
2. 解析签名
3. 调用 secp256k1_ecdsa_verify
4. 返回结果

#### 1.4 公钥恢复 ⏳
```moonbit
pub fn recover_public_key(message_hash: FixedArray[Byte], signature: Signature) -> ECDSAResult[PublicKey]
```

**步骤**:
1. 解析 recoverable signature
2. 调用 secp256k1_ecdsa_recover
3. 序列化公钥
4. 返回 PublicKey

---

### Phase 2: 优化和完善

- [ ] 全局上下文缓存（避免重复创建）
- [ ] 错误处理优化
- [ ] 性能测试
- [ ] 内存安全检查

---

### Phase 3: 测试和验证

- [ ] 单元测试（每个函数）
- [ ] 集成测试（完整流程）
- [ ] 与 go-ethereum 对比测试
- [ ] 官方测试向量验证

---

## 🔍 技术细节

### FFI 类型映射

| C 类型 | MoonBit 类型 | 说明 |
|--------|-------------|------|
| `secp256k1_context*` | `#external type Secp256k1Context` | 不透明指针 |
| `secp256k1_pubkey*` | `FixedArray[Byte]` (64字节) | 内部表示 |
| `secp256k1_ecdsa_recoverable_signature*` | `FixedArray[Byte]` (65字节) | 内部表示 |
| `unsigned char*` | `FixedArray[Byte]` | 字节数组 |
| `size_t*` | `FixedArray[UInt]` | 长度指针 |
| `int` | `Int` | 返回值 |

### 内存管理

- **上下文**: 手动创建和销毁
- **缓冲区**: MoonBit 管理（FixedArray）
- **返回值**: 复制到 MoonBit 对象

### 调用约定

- 使用 `#borrow` 标注借用参数
- 使用 `#owned` 标注拥有参数
- 返回值按值传递

---

## 📊 进度追踪

```
总体进度: ███░░░░░░░ 30%

├─ FFI 基础     ████████████████████ 100% ✅
├─ 公钥派生     ██████░░░░░░░░░░░░░░  30% ⏳
├─ 签名功能     ░░░░░░░░░░░░░░░░░░░░   0% ⏳
├─ 验证功能     ░░░░░░░░░░░░░░░░░░░░   0% ⏳
├─ 公钥恢复     ░░░░░░░░░░░░░░░░░░░░   0% ⏳
└─ 测试验证     ░░░░░░░░░░░░░░░░░░░░   0% ⏳
```

---

## 🎯 下一步行动

### 立即任务（今天）

1. **解决 secp256k1_pubkey 结构问题**
   - 尝试使用 FixedArray[Byte] 作为缓冲区
   - 测试是否能正确传递给 C 函数

2. **完成公钥派生**
   - 实现完整的 derive_public_key
   - 编写测试用例

3. **实现签名功能**
   - 使用 secp256k1_ecdsa_sign_recoverable
   - 测试签名创建

### 本周任务

4. **完成验证和恢复**
   - 实现 verify 函数
   - 实现 recover_public_key

5. **测试和验证**
   - 与 C 测试程序对比
   - 确保结果一致

---

## 💡 技巧和注意事项

### 1. 缓冲区管理

```moonbit
// ❌ 错误：尝试直接使用 #external 类型
#external
type Secp256k1Pubkey

// ✅ 正确：使用 FixedArray[Byte] 作为缓冲区
let pubkey_buf = FixedArray::make(64, b'\x00')
```

### 2. 指针传递

```moonbit
// FFI 函数自动处理 FixedArray -> C 指针转换
extern "C" fn func(data : FixedArray[Byte]) -> Int = "c_func"

// 调用时直接传递
let arr = FixedArray::make(32, b'\x00')
let result = func(arr)  // ✅ 自动转换
```

### 3. 输出参数

```moonbit
// C 函数会修改数组内容
let output = FixedArray::make(65, b'\x00')
secp256k1_ec_pubkey_serialize(ctx, output, ..., flags)
// output 现在包含序列化的公钥
```

---

## 🎉 成功标准

完成后应该能够：

```moonbit
// 1. 生成密钥对
let private_key = generate_private_key()?
let public_key = derive_public_key(private_key)?

// 2. 签名
let hash = FixedArray::make(32, b'\x01')
let signature = sign(hash, private_key)?

// 3. 验证
assert!(verify(hash, signature, public_key))

// 4. 恢复公钥
let recovered = recover_public_key(hash, signature)?
assert_eq!(recovered, public_key)

// 5. 性能测试
// 应该接近 C 实现的性能（>90%）
```

---

**当前状态**: 正在实现公钥派生功能 🚧

**预计完成**: 2-3 天

