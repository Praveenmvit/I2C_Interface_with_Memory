# I2C_Interface_with_Memory
eda_playground link : https://www.edaplayground.com/x/YT7i  
![image](https://github.com/user-attachments/assets/a35e42cd-21b2-4672-a1cc-074f8f0e55e6)  

I2C - Inter integrated circuit.   
1. Write and read from the Memory(slave).  
2. Master initiate the transaction, whereas slave respond to the transaction.  
3. Synchronous communication.  
4. Two signal interface between the master and slave is SCL(serial clock line) and SDA(serial data line).  
5. SDA is a inout port. SCL is input to the Memory(slave).
6. Two ways of addressing 7 bit and 10 bit. here we are going with 7 bit.  

Implementation:  
1. In the single time period of SCL we send 1 bit.
2. The time period of SCL is divided into 4 parts called pulses.
3. master initiate the transaction by start(scl -> high throughout time period. sda is made 1100 for (pulse 0..3)).
   ![image](https://github.com/user-attachments/assets/aa4e02d6-464e-432e-a8a1-b96c4d46265d)
4. 

