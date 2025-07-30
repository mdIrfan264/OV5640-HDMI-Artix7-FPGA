# TMDS Serializer (`OutputSERDES`)

## 🎯 Purpose

The `OutputSERDES` module serializes 10-bit TMDS encoded parallel data into a high-speed serial data stream suitable for HDMI/DVI transmission. It ensures:
- **LSB-first bit order**
- **Differential output signaling (TMDS)**
- **Compatibility with Artix-7 OSERDESE2 hardware blocks**

---

## 🧩 Inputs & Outputs

| Signal        | Width | Direction | Description |
|---------------|-------|-----------|-------------|
| `PixelClk`    | 1     | Input     | 1x Clock used for parallel data processing |
| `SerialClk`   | 1     | Input     | 5x Clock used for serializing data |
| `aRst`        | 1     | Input     | Asynchronous reset |
| `pDataOut`    | 10    | Input     | Parallel 10-bit TMDS encoded data |
| `sDataOut_p`  | 1     | Output    | TMDS differential positive signal |
| `sDataOut_n`  | 1     | Output    | TMDS differential negative signal |

---

## ⚙️ Core Components

### 1. **Bit Reordering**
```verilog
pDataOut_q[14 - i - 1] = pDataOut[i];
````

This reverses the bit order so **LSB is sent first**, as required by the HDMI/DVI protocol. OSERDESE2 always sends `D1` first → by reversing, LSB becomes `D1`.

---

### 2. **OBUFDS – Differential Output Buffer**

```verilog
OBUFDS #(.IOSTANDARD("TMDS_33")) TMDS_OBUFDS (
    .I(sDataOut),
    .O(sDataOut_p),
    .OB(sDataOut_n)
);
```

Drives differential TMDS signals onto HDMI pins.

---

### 3. **OSERDESE2 Master-Slave Serializer**

* **Master** handles `D1–D8` (bits \[13:6])
* **Slave** handles `D3–D8` (bits \[5:0])
* The two are **cascaded using SHIFTOUT/SHIFTIN**

Why Master-Slave?

* A single OSERDESE2 can only serialize up to 8 bits.
* TMDS uses 10-bit data → we split across master and slave.

---

## 🧠 Important Concepts

* **Serialization Rate**: Using `PixelClk` (e.g., 25 MHz) and `SerialClk` (e.g., 125 MHz), we serialize 10 bits per pixel clock.
* **DDR Mode**: OSERDESE2 operates in **DDR mode** (2 bits per `SerialClk` cycle), enabling 10-bit serialization in 5 clock cycles.
* **No Tri-state Used**: TMDS signals are always driven — no 3-state outputs are used.

---

## 🖼️ Bit Mapping Example

If `pDataOut = 10'b ABCDEFGHIJ`, then:

| OSERDESE2 Input | Data Bit |
| --------------- | -------- |
| D1 (master)     | J        |
| D2              | I        |
| D3              | H        |
| D4              | G        |
| D5              | F        |
| D6              | E        |
| D7              | D        |
| D8              | C        |
| Slave D3        | B        |
| Slave D4        | A        |

---

## ✅ Summary

| Feature          | Description                         |
| ---------------- | ----------------------------------- |
| Parallel Input   | 10-bit TMDS data from encoder       |
| Serial Output    | High-speed differential HDMI signal |
| Speed            | 5x PixelClk using DDR               |
| Xilinx Primitive | OSERDESE2 (Artix-7 compatible)      |
| Output Format    | LSB-first                           |

---

