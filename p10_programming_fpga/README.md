# Programming FPGA with Quad SPI Flash

To make your FPGA design permanent (i.e., stored in flash), you need to generate a `.bin` file and program the onboard QSPI memory.

---

## Step 1: Enable `.bin` File Generation

Go to **Tools → Settings → Bitstream**, and enable the `-bin_file` option.
![binfile](docs/tools_settings_bin.png)

Re-run **Synthesis** so the new options are available.

---

## Step 2: (Optional) Optimize Bitstream for Flash Programming

Open **Tools → Edit Device Properties** and adjust the following settings:

* `General → Enable Bitstream Compression → TRUE`
Makes the .bin file smaller. Programming to flash is faster.
  ![bitcomp](docs/en_bit_comp.png)

* `Configuration → Configuration Rate → 33 MHz`
Increases the clock rate the FPGA uses to read from flash. Shorter boot time.
  ![clock](docs/clock.png)

* `Configuration Modes → Master SPI x4`
Uses 4-bit wide flash transfers instead of 1-bit. Roughly 4× faster boot.
  ![qspi](docs/qspi.png)

**Summary:**

* Without these, programming still works, but flashing is slower and FPGA takes longer to configure on reset/power-up.
* With these, flashing and booting are both noticeably faster.

---

## Step 3: Program QSPI Flash

After **Generate Bitstream**, both `.bit` and `.bin` files will be created.

1. Open Hardware Manager (**Open Hardware Device → Open Target**).
2. Right-click on the FPGA and select **Add Configuration Memory Device**.
3. Choose the correct flash chip.

   * For **Cmod A7 Rev. C**, the device is `Macronix MX25L3233FZBI-08Q`.
4. Select the `.bin` file (e.g., `project.runs/impl_1/project.bin`) as the configuration file.
5. Program the device.

Once complete, the design will automatically load from flash on power-up.

---

## References

1. [Cmod A7 Programming Guide](https://digilent.com/reference/learn/programmable-logic/tutorials/cmod-a7-programming-guide/start)
2. [Cmod A7 GPIO Demo](https://digilent.com/reference/programmable-logic/cmod-a7/demos/gpio)
