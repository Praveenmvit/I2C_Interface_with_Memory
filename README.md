# I2C_Interface_with_Memory
eda_playground link : https://www.edaplayground.com/x/YT7i  

![image](https://github.com/user-attachments/assets/a35e42cd-21b2-4672-a1cc-074f8f0e55e6)  

## <inc>I2C - Inter integrated circuit.</inc>   
1. Write and read from the Memory(slave).  
2. Master initiate the transaction, whereas slave respond to the transaction.  
3. Synchronous communication.  
4. Two signal interface between the master and slave is SCL(serial clock line) and SDA(serial data line).  
5. SDA is a inout port. SCL is input to the Memory(slave).
6. Two ways of addressing 7 bit and 10 bit. here we are going with 7 bit.  

## Implementation:  
1. In the single time period of SCL we send one bit.
2. The time period of SCL is divided into 4 parts called pulses.
3. Master initiate the transaction by start(scl -> high throughout time period. sda is made 1100 for (pulse 0..3)).
<div align="center">
  <image src = "https://github.com/user-attachments/assets/aa4e02d6-464e-432e-a8a1-b96c4d46265d">  
</div>  
                                                     
                                                       For one time period of SCL<br/>     

4. After sending start, operation(R/W') bit followed by 7 bit address is send in 8 SCL period.<br/>
<div align="center">
   <image src = "https://github.com/user-attachments/assets/b0ebc840-5f4d-4039-a8b2-513ca6115127">  
</div>    
                                                   
5. The SDA line is pulled according to the op code and address bit at pulse 1. SCL is same for all bit transaction as in above figure.<br/>   
6. It will wait for Addr_ack from slave in next SCL after sending address bits.<br/>
7. if ack received in master it will go to state of READ OR WRITE based on operation.  
8. For read the memory will send the 8 bit data to the master in SDA on 8 SCL.  
9. Master will sample the SDA line at pulse 2, capture this 8 bit data.  
10. After receiving the data master will send the ACK.  
11. If it is write operation on the memory. master will send the 8 bit data to slave in SDA on 8 SCL.   
12. After receiving this data slave will send ack for the received data.  
13. Finally the stop transaction is send from the master to slave.   
14. slave will detect the stop from master and stop.
    
<div align="center">  
   <image src = "https://github.com/user-attachments/assets/efd58c9b-6a16-4d93-8576-e069aaf6098c">  
</div>




