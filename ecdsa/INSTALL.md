# 🔧 libsecp256k1 安装指南

## 状态

✅ **已编译**: `/tmp/secp256k1/`  
⏳ **待安装**: 需要运行以下命令

---

## 📦 安装步骤

### 1. 安装到系统

```bash
cd /tmp/secp256k1
sudo make install
sudo ldconfig
```

### 2. 验证安装

```bash
# 检查库文件
ldconfig -p | grep secp256k1
# 应该看到:
# libsecp256k1.so.2 (libc6,x86-64) => /usr/local/lib/libsecp256k1.so.2

# 检查 pkg-config
pkg-config --modversion libsecp256k1
# 应该输出版本号，例如: 0.1.0

# 检查头文件
ls -l /usr/local/include/secp256k1*.h
# 应该看到:
# /usr/local/include/secp256k1.h
# /usr/local/include/secp256k1_ecdh.h
# /usr/local/include/secp256k1_extrakeys.h
# /usr/local/include/secp256k1_preallocated.h
# /usr/local/include/secp256k1_recovery.h
# ...
```

### 3. 测试链接

创建一个简单的 C 测试程序：

```c
// test_secp256k1.c
#include <stdio.h>
#include <secp256k1.h>

int main() {
    secp256k1_context *ctx = secp256k1_context_create(SECP256K1_CONTEXT_SIGN);
    if (ctx) {
        printf("✅ libsecp256k1 工作正常！\n");
        secp256k1_context_destroy(ctx);
        return 0;
    }
    printf("❌ libsecp256k1 初始化失败\n");
    return 1;
}
```

编译并运行：

```bash
gcc test_secp256k1.c -lsecp256k1 -o test_secp256k1
./test_secp256k1
```

如果看到 "✅ libsecp256k1 工作正常！"，说明安装成功！

---

## 🔍 故障排除

### 问题 1: 找不到库文件

```bash
# 添加库路径
echo "/usr/local/lib" | sudo tee /etc/ld.so.conf.d/local.conf
sudo ldconfig
```

### 问题 2: pkg-config 找不到

```bash
# 设置 PKG_CONFIG_PATH
export PKG_CONFIG_PATH=/usr/local/lib/pkgconfig:$PKG_CONFIG_PATH

# 永久设置（添加到 ~/.bashrc）
echo 'export PKG_CONFIG_PATH=/usr/local/lib/pkgconfig:$PKG_CONFIG_PATH' >> ~/.bashrc
source ~/.bashrc
```

### 问题 3: 头文件找不到

```bash
# 检查头文件位置
find /usr -name secp256k1.h 2>/dev/null

# 如果在 /usr/local/include，确保编译器能找到
gcc -I/usr/local/include test.c -L/usr/local/lib -lsecp256k1
```

---

## 🚀 配置 MoonBit 项目

安装成功后，需要更新 `ecdsa/moon.pkg.json`：

```json
{
  "is_main": false,
  "import": [],
  "link": {
    "native": {
      "c": ["-lsecp256k1"]
    }
  }
}
```

---

## 📚 libsecp256k1 特性

已启用的模块：
- ✅ **recovery** - 公钥恢复（以太坊必需）
- ✅ **ecdh** - Elliptic Curve Diffie-Hellman
- ✅ **extrakeys** - x-only 公钥（Taproot）
- ✅ **schnorrsig** - Schnorr 签名
- ✅ **musig** - MuSig 多重签名
- ✅ **ellswift** - ElligatorSwift 编码

优化选项：
- ✅ **x86_64 汇编优化**
- ✅ **ecmult 窗口大小: 15**
- ✅ **快速表查找: 86 KiB**

---

## 🧪 下一步

安装完成后：

1. **编译 ECDSA 模块**:
```bash
cd /home/pingguomiaomiao/Desktop/Lunarcrypto
moon check
```

2. **运行测试**:
```bash
moon test
```

3. **开始使用**:
```moonbit
let keypair = generate_keypair()?
let signature = sign(message_hash, keypair.get_private_key())?
```

---

## 📖 参考

- [libsecp256k1 GitHub](https://github.com/bitcoin-core/secp256k1)
- [API 文档](https://github.com/bitcoin-core/secp256k1/blob/master/include/secp256k1.h)
- [恢复模块](https://github.com/bitcoin-core/secp256k1/blob/master/include/secp256k1_recovery.h)

---

**安装完成后，FFI 绑定代码已经准备就绪！** 🎉

