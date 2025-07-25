
### 📘 TMDS Encoder – Step-by-Step Documentation

---

## 🔷 Overview

**TMDS (Transition Minimized Differential Signaling)** is a high-speed serial protocol used in HDMI to transmit video data with minimal signal degradation and electromagnetic interference.

The encoder converts **8-bit RGB or control data** into **10-bit TMDS encoded data**, suitable for differential transmission over HDMI.

---

## 🔧 TMDS Encoder Stages

| Stage | Purpose                     | Technique               |
| ----- | --------------------------- | ----------------------- |
| 1     | Minimize bit transitions    | XOR/XNOR-based encoding |
| 2     | DC balance                  | Conditional encoding    |
| 3     | Produce final 10-bit output | Output Register         |

---

## ✅ Stage 1 – Minimize Transitions

### 🎯 Goal

Reduce the number of transitions (bit flips) in the transmitted data to:

* Lower **EMI (Electromagnetic Interference)**
* Improve **signal integrity** at high speeds

### ⚙️ Encoding Method

We compute two possible encodings from the 8-bit input data:

1. **XOR-Based Encoding**:
   Encodes input by chaining XOR operations.
2. **XNOR-Based Encoding**:
   Similar but flips the result conditionally to reduce transitions.

The final 9-bit intermediate result is chosen based on the **number of 1s** in the input.

### 🔢 Logic Explanation

Let’s say the input 8-bit data is: `D = data[7:0]`

```verilog
// XOR method
q_m_xor[0] = D[0];
for (i = 1; i < 8; i++) {
    q_m_xor[i] = q_m_xor[i-1] ^ D[i];
}
q_m_xor[8] = 1;

// XNOR method
q_m_xnor[0] = D[0];
for (i = 1; i < 8; i++) {
    q_m_xnor[i] = ~(q_m_xnor[i-1] ^ D[i]); // XNOR
}
q_m_xnor[8] = 0;
```

### 🧠 Which to choose?

Let `N1` be the number of 1s in `D[7:0]`.

```verilog
if (N1 > 4 || (N1 == 4 && D[0] == 0))
    q_m = q_m_xnor;
else
    q_m = q_m_xor;
```

✅ The output of this stage is `q_m[8:0]` – the transition-minimized version of the 8-bit input.

---

