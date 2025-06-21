`timescale 1ns/1ps

module memory_slave(clk,rst,scl,sda,ack_err,done);
  
  input clk,rst,scl;
  inout sda;
  output reg ack_err;
  output reg done;
  reg [7:0]mem[128];
  
  typedef enum bit[3:0] {WAIT_FOR_START,WAIT_PULSE,READ_ADDR,SEND_ADDR_ACK,STORE_DATA,SEND_DATA,RECEIVE_MASTER_ACK,STORE_DATA_ACK,DETECT_STOP} fsm;
  
  fsm state=WAIT_FOR_START;
  
  parameter sys_freq = 40000000; //40 MHz
  parameter i2c_freq = 1000000;  //// 100k
  parameter clk_count4 = (sys_freq/i2c_freq);/// 400
  parameter clk_count1 = clk_count4/4; ///100
  integer count;
  
  reg busy,sda_en,r_ack,sda_t;
  reg [7:0] addr_op;
  reg [3:0] bit_count;
  reg [1:0] pulse;
  
  
  always@(posedge clk) begin
    if(rst) begin
      done <= 0;
      busy <= 0;
      ack_err <= 0;
      pulse <= 0;
      bit_count <= 0;
      for(int i=0; i< 128; i+=1) begin
        mem[i] <= i;
      end
    end
    else begin
      if(busy == 1'b0) begin
        pulse <= 2;
        count <= 21;
      end
      else if(count == clk_count1-1) begin
        pulse <= 1;
        count <= count + 1;        
      end
      else if(count == (clk_count1*2)-1) begin
        pulse <= 2;
        count <= count + 1;
      end
      else if(count == (clk_count1*3)-1) begin
        pulse <= 3;
        count <= count + 1;
      end
      else if(count == (clk_count1*4)-1) begin
        pulse <= 0;
        count <= 0;
      end
      else begin
        count <= count + 1;
      end
    end
  end
  
  always @(posedge clk) begin
    
    case(state) 
      WAIT_FOR_START: begin
        sda_en <= 0;
        if(scl == 1 && sda ==0) begin
          busy <= 1;
          state <= WAIT_PULSE;
        end
        else begin
          state <= WAIT_FOR_START;
        end
      end
      
      WAIT_PULSE: begin
        if(count == (clk_count1*4)-1) begin
          state <= READ_ADDR;
        end
        else
          state <= WAIT_PULSE;
      end
      
      READ_ADDR: begin
        if(bit_count <= 7) begin
          case(pulse)
            0: ;
            1: ;
            2: addr_op <= (count == 20)?{addr_op[6:0],sda}:addr_op; // addr range [7:1] to [6:0]
            3: ;
          endcase
          if(count == (clk_count1*4)-1) begin
            state <= READ_ADDR;
            bit_count <= bit_count + 1;
          end
          else
            state <= READ_ADDR;
        end
        else begin
          state <= SEND_ADDR_ACK;
          bit_count <= 0;
        end
      end
      
      SEND_ADDR_ACK: begin
        sda_en <= 1;
        case(pulse)
          0: sda_t <= 0;
          1: ;
          2: ;
          3: ;
        endcase
        
        if(count == (clk_count1*4)-1) begin
          if(addr_op[7]==1) begin // changed from 0 to 7.
            state <= SEND_DATA;
          end
          else if(addr_op[7] == 0) begin // changed 0 to 7.
            state <= STORE_DATA;
            sda_en <= 0;
          end
          else begin
            state <= SEND_ADDR_ACK;
          end
        end
      end
      
      SEND_DATA: begin
        sda_en <= 1;
        if(bit_count <= 7) begin
          case(pulse)
            0: ;
            1: sda_t <= mem[addr_op[6:0]][7-bit_count]; // [7:1] -> [6:0]
            2: ;
            3: ;
          endcase
          
          if(count == (clk_count1*4)-1) begin
            bit_count <= bit_count+1;
            state <= SEND_DATA;
          end
          else
            state <= SEND_DATA;
        end
        else begin
          state <= RECEIVE_MASTER_ACK;
          bit_count <=0;
          sda_en <= 0;
        end
      end
      
      RECEIVE_MASTER_ACK: begin
        sda_en <= 0;
        case(pulse)
          0: ;
          1: ;
          2: r_ack <= sda;
          3: ;
        endcase
        if(count == (clk_count1*4)-1) begin
          if(r_ack == 1) begin
            ack_err <= 0;
            sda_en <= 0;
            state <= DETECT_STOP;
            r_ack <= 0;
          end
          else begin
            ack_err <= 1;
            sda_en <= 0;
            state <= DETECT_STOP;
          end
        end
        else begin
          state <= RECEIVE_MASTER_ACK;
        end
        
      end
      
      STORE_DATA: begin
        sda_en <= 0;
        if(bit_count <= 7) begin
          case(pulse)
            0: ;
            1: ;
            2: mem[addr_op[6:0]][7-bit_count]<= (count==20)?sda:mem[addr_op[6:0]][7-bit_count]; // [7;1] - > [6:0]
            3: ;
          endcase
          if(count == (clk_count1*4)-1) begin
            state <= STORE_DATA;
            bit_count <= bit_count + 1;
          end
          else
            state <= STORE_DATA;
        end
        else begin
          state <= STORE_DATA_ACK;
          sda_en <= 1;
          bit_count <= 0;
        end
      end
      
      STORE_DATA_ACK: begin
        sda_en <= 1;
        case(pulse)
          0: sda_t <= 0;
          1: ;
          2: ;
          3: ;
        endcase
        
        if(count == (clk_count1*4)-1) begin
          state <= DETECT_STOP;
          sda_en <= 0;
        end
        else
          state <= STORE_DATA_ACK;
      end
      
      DETECT_STOP: begin
        sda_en <= 0;
        if(pulse == 2'b10 && count == 20) begin
          busy <= 0;
          done <= 1;
          state <= WAIT_FOR_START;
        end
        else
          state <= DETECT_STOP;
      end
      
      default: state <= WAIT_FOR_START;
    endcase
    
  end
  
  assign sda = (sda_en==1)?(sda_t):1'bz;
  
endmodule
