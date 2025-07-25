
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

## 🔄 **Stage 2 – DC Balancing (Maintain Signal Integrity)**

### 🎯 **Goal**:

Ensure that the **number of 1s and 0s** is balanced over time in the transmitted data to maintain a **zero average DC voltage** (no net charge buildup), which is essential for **differential transmission lines** like HDMI.

---

## 🧠 **Why is this needed?**

* If the signal has too many 1s or 0s, it causes a **DC bias** (electrical imbalance).
* DC bias can lead to:

  * Signal distortion
  * Loss of synchronization
  * Long-term damage to transmission hardware
* **Differential signaling** (like HDMI) expects the average voltage to remain **centered (balanced)**.

---

## 🧮 How is DC balancing done?

After Stage 1 (XOR/XNOR encoding), we get an **intermediate 9-bit value** `q_m`:

* It has **8 data bits** (`q_m[7:0]`)
* And **1 flag bit** (`q_m[8]`) that tells whether XOR or XNOR was used

Now in Stage 2:

### 🔢 Step 1: Count 1’s in the 8-bit data

```verilog
int ones = count_ones(q_m[7:0]);
```

### 🔁 Step 2: Maintain a running **DC bias counter**

Let’s call it:

```verilog
int dc_balance = 0;
```

This gets updated **every cycle** to reflect the imbalance in 1s and 0s.

---

### ⚖️ Step 3: Choose how to transmit the bits:

Depending on the current bias and new data:

#### 3a. If imbalance is increasing ➜ **Invert the data**

This helps **reduce the number of 1s** (or 0s)

#### 3b. If imbalance is OK ➜ **Keep it as is**

#### 3c. Add 2 MSBs:

* Bit 9 (MSB): Indicates whether the data was inverted
* Bit 8: Carries the XOR/XNOR flag from Stage 1 (`q_m[8]`)

```text
Final TMDS 10-bit word:

Bit 9 | Bit 8 |  Data (inverted or not based on DC balancing)
  ↑       ↑         ↑
Inversion  XOR/XNOR    8-bit result
```

---

## 🧪 Example:

Suppose `q_m = 9'b101010101` (5 ones, 4 zeros)
Current DC bias = +4

Since we already have **too many 1s**, we invert the 8 bits:

```verilog
q_m[7:0] = ~q_m[7:0]
```

And set MSB (bit 9) = 1 to indicate inversion.

Update DC bias:

```verilog
dc_balance = dc_balance - (number of 1s in original - 0s in original)
```

---

## 🛠️ Final Output:

A 10-bit word that:

* Minimizes long-term DC imbalance
* Indicates what transformations were done
* Can be decoded correctly on the receiver side

---

## ✅ Summary

| Step             | Purpose                        |
| ---------------- | ------------------------------ |
| Count 1s         | Know how unbalanced data is    |
| Track DC bias    | Running total of 1s vs 0s      |
| Invert if needed | To correct imbalance           |
| Add MSBs         | To tell receiver how to decode |

---


