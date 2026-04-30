## 6. SPI Mode Operation

The SPI standard defines 4 modes based on CPOL (Clock Polarity) and CPHA (Clock Phase):

| Mode | CPOL | CPHA | SCLK Idle State | Data Sampled On      | Data Changed On      |
|------|------|------|-----------------|----------------------|----------------------|
| 0    | 0    | 0    | Low             | Rising edge of SCLK  | Falling edge of SCLK |
| 1    | 0    | 1    | Low             | Falling edge of SCLK | Rising edge of SCLK  |
| 2    | 1    | 0    | High            | Falling edge of SCLK | Rising edge of SCLK  |
| 3    | 1    | 1    | High            | Rising edge of SCLK  | Falling edge of SCLK |

### Transaction Sequence
1. Master asserts CS low (active).
2. Slave detects CS falling edge, loads TXDATA into shift register.
3. On each SCLK sampling edge, slave captures MOSI bit.
4. On each SCLK change edge, slave updates MISO with next bit.
5. After DATA_WIDTH bits transferred, slave sets TX_DONE flag and asserts IRQ.
6. Master de-asserts CS high (inactive).
