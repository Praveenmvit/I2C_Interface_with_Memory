// Code your design here
`timescale 1ns/1ps

module master(clk,rst,newd,addr,op,din,dout,busy,ack_err,done,sda,scl);
  input clk,rst,newd,op;
  inout sda;
  input [6:0] addr;
  input [7:0] din; // 8 bit data
  output reg [7:0] dout;
  output reg busy,ack_err,done;
  output scl;
  
  reg scl_t,sda_t;
  typedef enum bit[3:0] {IDLE,START,WRITE_ADDR,ACK_ADDR,READ_DATA,WRITE_DATA,ACK_DATA,MASTER_ACK,STOP}fsm;
  
  fsm state;
  
  
  parameter sys_freq = 40000000; //40 MHz
  parameter i2c_freq = 1000000;  //// 1MHz
  parameter clk_count4 = (sys_freq/i2c_freq);/// 40
  parameter clk_count1 = clk_count4/4; ///10
  integer count;
  bit [3:0] bit_count;
  
  reg [1:0] pulse;
  
  always @(posedge clk) begin
    if(rst) begin
      scl_t <= 1;
      sda_t <= 1;
      busy <= 0;
      ack_err <= 0;
      done <= 0;
      state <= IDLE;
      pulse <= 0;
      count <= 0;
      bit_count <= 0;
    end
    else begin
      if(busy == 1'b0) begin
        pulse <= 0;
        count <= 0;
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
  
  reg [7:0] data_addr,data;
  reg sda_en,r_ack;
  
  always @(posedge clk) begin
    case(state) 
      IDLE: begin
        done <= 0;
        if(newd == 1) begin
          data_addr <= {op,addr}; // {op,followed by msb bits}
          data <= din;
          state <= START;
          ack_err <= 0;
          busy <= 1;
          dout <= 0;
        end
        else begin
          state <= IDLE;
          busy <= 0;
          ack_err <= 0;          
        end
      end
      
      START: begin
        sda_en <= 1;
        case(pulse)
          0: begin scl_t <= 1; sda_t <= 1; end
          1: begin scl_t <= 1; sda_t <= 1; end
          2: begin scl_t <= 1; sda_t <= 0; end
          3: begin scl_t <= 1; sda_t <= 0; end
        endcase
        if(count == (clk_count1*4)-1) begin
          state <= WRITE_ADDR;
        end
        else begin
          state <= START;
        end
      end
      
      WRITE_ADDR: begin
        sda_en <= 1;
        if(bit_count <= 7) begin
          case(pulse)
            0: begin scl_t <= 0; sda_t <=0; end
            1: begin scl_t <= 0; sda_t <= data_addr[7-bit_count]; end
            2: begin scl_t <= 1; end
            3: begin scl_t <= 1; end
          endcase
          if(count == (clk_count1*4)-1) begin
            state <= WRITE_ADDR;
            bit_count <= bit_count + 1;
          end
          else begin
            state <= WRITE_ADDR;
          end
        end
        else begin
          state <= ACK_ADDR;
          bit_count <= 0;
          sda_en <= 0;
        end
      end
      
      ACK_ADDR: begin
        sda_en <= 0;
        case(pulse)
          0: scl_t <= 0; 
          1: scl_t <= 0; 
          2: begin scl_t <= 1; r_ack <= sda; end
          3: scl_t <= 1; 
        endcase
        if(count == (clk_count1*4)-1) begin
          if(r_ack == 0 && data_addr[7]==0) begin // data_addr changed from 0 to 7
            state <= WRITE_DATA;
            sda_en <= 1;
            ack_err <= 0;
            r_ack <= 0;
          end
          else if(r_ack == 0 && data_addr[7] == 1) begin // 0 to 7.
            state <= READ_DATA;
            sda_en <= 0;
            ack_err <= 0;
            r_ack <= 0;
          end
          else begin
            state <= STOP;
            sda_en <= 1;
            ack_err <= 1;
          end
        end
        else begin
          state <= ACK_ADDR;
        end
      end
      
      READ_DATA: begin
        sda_en <= 0;
        if(bit_count <= 7) begin
          case(pulse)
            0: scl_t <= 0; 
            1: scl_t <= 0; 
            2: begin scl_t <= 1; dout<=(count==20)?({dout[6:0],sda}):dout; end
            3: scl_t <= 1; 
          endcase
          if(count == (clk_count1*4)-1) begin
            state <= READ_DATA;
            bit_count <= bit_count + 1;
          end
          else begin
            state <= READ_DATA;
          end
        end
        else begin
          state <= MASTER_ACK;
          bit_count <= 0;
        end 
      end
      
      WRITE_DATA: begin
        sda_en <= 1;
        if(bit_count <= 7) begin
          case(pulse)
            0: scl_t <= 0; 
            1: begin scl_t <= 0; sda_t <= data[7-bit_count]; end
            2: scl_t <= 1; 
            3: scl_t <= 1; 
          endcase
          if(count == (clk_count1*4)-1) begin
            state <= WRITE_DATA;
            bit_count <= bit_count + 1;
          end
          else begin
            state <= WRITE_DATA;
          end
        end
        else begin
          state <= ACK_DATA;
          bit_count <= 0;
        end 
      end
      
      MASTER_ACK: begin
        sda_en <= 1;
        case(pulse)
          0: begin scl_t <= 0; sda_t <= 1; end
          1: scl_t <= 0; 
          2: scl_t <= 1; 
          3: scl_t <= 1; 
        endcase
        if(count == (clk_count1*4)-1) begin
          state <= STOP;
          sda_t <= 0;
        end
        else begin
          state <= MASTER_ACK;
        end
      end
      
      ACK_DATA: begin
        sda_en <= 0;
        case(pulse)
          0: scl_t <= 0; 
          1: scl_t <= 0; 
          2: begin scl_t <= 1; r_ack <= sda; end
          3: scl_t <= 1; 
        endcase
        
        if(count == (clk_count1*4)-1) begin
          if(r_ack == 0) begin
            state <= STOP;
            sda_en <= 1;
            ack_err <= 0;
          end
          else begin
            state <= STOP;
            sda_en <= 1;
            ack_err <= 1;
          end
        end
        else begin
          state <= ACK_DATA;
        end
      end
      
      STOP: begin
        sda_en <= 1;
        
        case(pulse)
          0: begin scl_t <= 1; sda_t <= 0; end
          1: begin scl_t <= 1; sda_t <= 0; end 
          2: begin scl_t <= 1; sda_t <= 1; end
          3: begin scl_t <= 1; sda_t <= 1; end
        endcase
        
        if(count == (clk_count1*4)-1) begin
          state <= IDLE;
          done <= 1;
          busy <= 0;
        end
        else begin
          state <= STOP;
        end
        
      end
      
      default : state <= IDLE;
    endcase
    
  end
  
  assign sda = (sda_en==1)?(sda_t):1'bz;
  assign scl = scl_t;
  
endmodule
