<img src="./Pictures/Siemens_logo.png" alt="Description" width="200" style="float: right; margin-left: 10px;" />

# DisplayPort (v2.1) Link Layer Source Verification
- Basic testing is finished.
- Working on integrating the reference model class and including more elaborate test scenarios
- Starting to document our work.
- Working on SVAs and coverage.

#### **Signals Definition**
| Name      | Direction | Length | Interface | Description |
| --------  | --------  | ------ | ------    | ------ |
| clk       | input     | 1 bit  |-          | Clock |
| reset     | input     | 1 bit  |-          | Active low async. reset|
| SPM_Data  | input     | 8 bits  |TL     | Data to be written through I2C write request transaction. |
| SPM_Address         | input     | 20 bits |TL     | Register address to be written to or read from when requesting an I2C transaction. |
| SPM_LEN         | input     | 8 bits |TL     | Length of burst I2C transaction in bytes (0 value means 1 byte). |
| SPM_CMD       | input     | 2 bits  |TL     |  The command to specify the I2C transaction type (Read or Write). |
| SPM_Transaction_VLD       | input     | 1 bit |TL     |  Active high valid signal for I2C request transactions. |
| LPM_Data  | input     | 8 bits  |TL     | Data to be written through Native AUX write request transaction. |
| LPM_Address         | input     | 20 bits |TL     | Register address to be written to or read from when requesting an Native AUX transaction. |
| LPM_LEN         | input     | 8 bits |TL     | Length of burst Native AUX transaction in bytes (0 value means 1 byte). |
| LPM_CMD       | input     | 2 bits  |TL     |  The command to specify the Native AUX transaction type (Read or Write). |
| LPM_Transaction_VLD       | input     | 1 bit |TL     |  Active high valid signal for Native AUX request transactions. |
| LPM_Start_CR      | input     | 1 bit |TL     |  Active high valid signal for Native AUX request transactions. |
| LPM_Transaction_VLD       | input     | 1 bit |TL     |  Active high valid signal for Native AUX request transactions. |
| LPM_Transaction_VLD       | input     | 1 bit |TL     |  Active high valid signal for Native AUX request transactions. |
| LPM_Transaction_VLD       | input     | 1 bit |TL     |  Active high valid signal for Native AUX request transactions. |
| LPM_Transaction_VLD       | input     | 1 bit |TL     |  Active high valid signal for Native AUX request transactions. |
| LPM_Transaction_VLD       | input     | 1 bit |TL     |  Active high valid signal for Native AUX request transactions. |
| LPM_Transaction_VLD       | input     | 1 bit |TL     |  Active high valid signal for Native AUX request transactions. |






| SPM_Native_I2C | output    | 1 bit  |TL     |  Active high valid signal for I2C reply transactions. |
| SPM_Reply_ACK_VLD       | output    | 1 bit |TL     |  Valid signal for the I2C reply transaction status. |
| SPM_Reply_ACK     | output    | 2 bits  |TL     | I2C reply transaction status; may be ACK, NACK or DEFER. |
| SPM_Reply_Data_VLD      | output    | 1 bit  |TL    |  Valid signal for the I2C read reply transaction data. |
| SPM_Reply_Data      | output    | 8 bits  |TL    |  I2C read reply transaction data. |
| LPM_Native_I2C | output    | 1 bit  |TL     |  Active low valid signal for Native AUX reply transactions. |
| LPM_Reply_ACK_VLD       | output    | 1 bit |TL     |  Valid signal for the Native AUX reply transaction status. |
| LPM_Reply_ACK     | output    | 2 bits  |TL     | Native AUX reply transaction status; may be ACK, NACK or DEFER. |
| LPM_Reply_Data_VLD      | output    | 1 bit  |TL    |  Valid signal for the Native AUX read reply transaction data. |
| LPM_Reply_Data      | output    | 8 bits  |TL    |  Native AUX read reply transaction data. |
___


#### **Verification Environment Architecture**
![Alt text](./Pictures/Verification_Architecture_DP.drawio.png) |
|:--:|
| *Figure 2: Verification Arichitecture for DP Link Layer Source* |