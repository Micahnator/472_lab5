//-----------------------------------------------------------------------------
// Title         : MIPS Pipelined Processor
// Project       : ECE 313 - Computer Organization
//-----------------------------------------------------------------------------
// File          : mips_single.v
// Author        : John Nestor  <nestorj@lafayette.edu>
// Organization  : Lafayette College
// 
// Created       : October 2002
// Last modified : 7 January 2005
//-----------------------------------------------------------------------------
// Description :
//   Pipelined implementation of the MIPS processor subset described in
//   Section 6.3 of "Computer Organization and Design, 3rd ed."
//   by David Patterson & John Hennessey, Morgan Kaufmann, 2004 (COD3e).  
//
//   It implements the equivalent of Figure 6.27 on page 404 of COD3e
//
//-----------------------------------------------------------------------------

module mips_pipeline(clk, reset);
input clk, reset;

    // ********************************************************************
    //                              Signal Declarations
    // ********************************************************************

    // IF Signal Declarations
    
    wire [31:0] IF_instr, IF_pc, IF_pc_next, IF_pc4;

    // ID Signal Declarations

    reg [31:0] ID_instr, ID_pc4;  // pipeline register values from EX

    wire [5:0] ID_op, ID_funct;
    wire [4:0] ID_rs, ID_rt, ID_rd;
    wire [15:0] ID_immed;
    wire [31:0] ID_extend, ID_rd1, ID_rd2;

    assign ID_op = ID_instr[31:26];
    assign ID_rs = ID_instr[25:21];
    assign ID_rt = ID_instr[20:16];
    assign ID_rd = ID_instr[15:11];
    assign ID_immed = ID_instr[15:0];
    assign ID_funct = ID_instr[5:0];

    wire ID_RegWrite, ID_Branch, ID_RegDst, ID_MemtoReg,  // ID Control signals
         ID_MemRead, ID_MemWrite, ID_ALUSrc;
    wire [1:0] ID_ALUOp;
    
    wire ID_RegWrite_2, ID_Branch_2, ID_RegDst_2, ID_MemtoReg_2, ID_MemRead_2,
        ID_MemWrite_2, ID_ALUSrc_2;     ///control signals from hazard mux to EX stage
    wire [1:0] ID_ALUOp_2;
        
    ///bus of control signals that go to the hazard mux
    wire [8:0] control_bus_to_mux;
    assign control_bus_to_mux[0] = ID_RegWrite;
    assign control_bus_to_mux[1] = ID_Branch;
    assign control_bus_to_mux[2] = ID_RegDst;
    assign control_bus_to_mux[3] = ID_MemtoReg;
    assign control_bus_to_mux[4] = ID_MemRead;
    assign control_bus_to_mux[5] = ID_MemWrite;
    assign control_bus_to_mux[6] = ID_ALUSrc;
    assign control_bus_to_mux[8:7] = ID_ALUOp[1:0];
    ///bus of control signals coming out of the hazard mux
    wire [8:0] control_bus_out_of_mux;
    assign ID_RegWrite_2 = control_bus_out_of_mux[0];
    assign ID_Branch_2 = control_bus_out_of_mux[1];
    assign ID_RegDst_2 = control_bus_out_of_mux[2];
    assign ID_MemtoReg_2 = control_bus_out_of_mux[3];
    assign ID_MemRead_2 = control_bus_out_of_mux[4];
    assign ID_MemWrite_2 = control_bus_out_of_mux[5];
    assign ID_ALUSrc_2 = control_bus_out_of_mux[6];
    assign ID_ALUOp_2[1:0] = control_bus_out_of_mux[8:7];
       
    ///The stall control signal
    wire stall;
    ///The ID stage register write control signal
    wire ID_Write;
    
    ///The 9 bit wide zero value into the hazard mux for nops
    wire [8:0] zero_reg_9;
    assign zero_reg_9 = 0;

    // EX Signals

    reg  [31:0] EX_pc4, EX_extend, EX_rd1, EX_rd2;
    wire [31:0]  EX_offset, EX_btgt, EX_alub, EX_ALUOut;
    reg  [4:0]  EX_rt, EX_rd;
    wire [4:0]  EX_RegRd;
    wire [5:0] EX_funct;
     
    reg  EX_RegWrite, EX_Branch, EX_RegDst, EX_MemtoReg,  // EX Control Signals
         EX_MemRead, EX_MemWrite, EX_ALUSrc;

    wire EX_Zero;

    reg  [1:0] EX_ALUOp;
    wire [2:0] EX_Operation;

   // MEM Signals

    wire MEM_PCSrc;

    reg  MEM_RegWrite, MEM_Branch, MEM_MemtoReg, 
         MEM_MemRead, MEM_MemWrite, MEM_Zero;

    reg  [31:0] MEM_btgt, MEM_ALUOut, MEM_rd2;
    wire [31:0] MEM_memout;
    reg  [5:0] MEM_RegRd;

    // WB Signals

    reg WB_RegWrite, WB_MemtoReg;  // WB Control Signals

    reg  [31:0] WB_memout, WB_ALUOut;
    wire [31:0] WB_wd;
    reg  [4:0] WB_RegRd;

    // ********************************************************************
    //                              IF Stage
    // ********************************************************************

    // IF Hardware

    reg32		IF_PC(clk, reset, IF_pc_next, IF_pc, ID_Write);

    add32 		IF_PCADD(IF_pc, 32'd4, IF_pc4);

    mux2 #(32)	IF_PCMUX(MEM_PCSrc, IF_pc4, MEM_btgt, IF_pc_next);

    rom32 		IMEM(IF_pc, IF_instr);

    always @(posedge clk)		    // IF/ID Pipeline Register
    begin
        if (reset)
        begin
            ID_instr <= 0;
            ID_pc4   <= 0;
        end else if (ID_Write == 0) begin ///handle hazard stall conditions
            ID_instr <= ID_instr;
            ID_pc4   <= ID_pc4;
        end else begin
            ID_instr <= IF_instr;
            ID_pc4   <= IF_pc4;
        end
    end

    // ********************************************************************
    //                              ID Stage
    // ********************************************************************

    reg_file	RFILE(clk, WB_RegWrite, ID_rs, ID_rt, WB_RegRd, ID_rd1, ID_rd2, WB_wd); 

    // sign-extender
    assign ID_extend = { {16{ID_immed[15]}}, ID_immed };

    control_pipeline CTL(.opcode(ID_op), .RegDst(ID_RegDst),
                       .ALUSrc(ID_ALUSrc), .MemtoReg(ID_MemtoReg), 
                       .RegWrite(ID_RegWrite), .MemRead(ID_MemRead),
                       .MemWrite(ID_MemWrite), .Branch(ID_Branch), 
                       .ALUOp(ID_ALUOp));
                       
    /// Hazard Detection Mux
    mux2 #(9)	HAZ_MUX(stall, control_bus_to_mux, zero_reg_9, control_bus_out_of_mux);
    
    /// Hazard Detection Unit
    hazard Hazard_Detector(clk, reset, ID_instr, EX_rt, EX_MemRead, ID_Write, stall);

    always @(posedge clk)		    // ID/EX Pipeline Register
    begin
        if (reset)
        begin
            EX_RegDst   <= 0;
	          EX_ALUOp    <= 0;
            EX_ALUSrc   <= 0;
            EX_Branch   <= 0;
            EX_MemRead  <= 0;
            EX_MemWrite <= 0;
            EX_RegWrite <= 0;
            EX_MemtoReg <= 0;
            //EX_RegDst   <= 0;
            //EX_ALUOp    <= 0;
            //EX_ALUSrc   <= 0;
            //EX_Branch   <= 0;
            //EX_MemRead  <= 0;
            //EX_MemWrite <= 0;
            //EX_RegWrite <= 0;
            //EX_MemtoReg <= 0;

            EX_pc4      <= 0;
            EX_rd1      <= 0;
            EX_rd2      <= 0;
            EX_extend   <= 0;
            EX_rt       <= 0;
            EX_rd       <= 0;
        end
        else if (ID_Write == 0) begin
            EX_RegDst   <= 0;
	          EX_ALUOp    <= 0;
            EX_ALUSrc   <= 0;
            EX_Branch   <= 0;
            EX_MemRead  <= 0;
            EX_MemWrite <= 0;
            EX_RegWrite <= 0;
            EX_MemtoReg <= 0;
            
            EX_pc4      <= ID_pc4;
            EX_rd1      <= ID_rd1;
            EX_rd2      <= ID_rd2;
            EX_extend   <= ID_extend;
            EX_rt       <= ID_rt;
            EX_rd       <= ID_rd;
        end        
        else begin
            EX_RegDst   <= ID_RegDst_2;
            EX_ALUOp    <= ID_ALUOp_2;
            EX_ALUSrc   <= ID_ALUSrc_2;
            EX_Branch   <= ID_Branch_2;
            EX_MemRead  <= ID_MemRead_2;
            EX_MemWrite <= ID_MemWrite_2;
            EX_RegWrite <= ID_RegWrite_2;
            EX_MemtoReg <= ID_MemtoReg_2;
            //EX_RegDst   <= ID_RegDst;
            //EX_ALUOp    <= ID_ALUOp;
            //EX_ALUSrc   <= ID_ALUSrc;
            //EX_Branch   <= ID_Branch;
            //EX_MemRead  <= ID_MemRead;
            //EX_MemWrite <= ID_MemWrite;
            //EX_RegWrite <= ID_RegWrite;
            //EX_MemtoReg <= ID_MemtoReg;

            EX_pc4      <= ID_pc4;
            EX_rd1      <= ID_rd1;
            EX_rd2      <= ID_rd2;
            EX_extend   <= ID_extend;
            EX_rt       <= ID_rt;
            EX_rd       <= ID_rd;
        end
    end

    // ********************************************************************
    //                              EX Stage
    // ********************************************************************

    // branch offset shifter
    assign EX_offset = EX_extend << 2;

    assign EX_funct = EX_extend[5:0];  

    add32 		EX_BRADD(EX_pc4, EX_offset, EX_btgt);

    mux2 #(32) 	ALUMUX(EX_ALUSrc, EX_rd2, EX_extend, EX_alub);

    alu 		EX_ALU(EX_Operation, EX_rd1, EX_alub, EX_ALUOut, EX_Zero);

    mux2 #(5) 	EX_RFMUX(EX_RegDst, EX_rt, EX_rd, EX_RegRd);

    alu_ctl 	EX_ALUCTL(EX_ALUOp, EX_funct, EX_Operation);

    always @(posedge clk)		    // EX/MEM Pipeline Register
    begin
        if (reset)
        begin
            MEM_Branch   <= 0;
            MEM_MemRead  <= 0;
            MEM_MemWrite <= 0;
            MEM_RegWrite <= 0;
            MEM_MemtoReg <= 0;
            MEM_Zero     <= 0;

            MEM_btgt     <= 0;
            MEM_ALUOut   <= 0;
            MEM_rd2      <= 0;
            MEM_RegRd    <= 0;
        end
        else begin
            MEM_Branch   <= EX_Branch;
            MEM_MemRead  <= EX_MemRead;
            MEM_MemWrite <= EX_MemWrite;
            MEM_RegWrite <= EX_RegWrite;
            MEM_MemtoReg <= EX_MemtoReg;
            MEM_Zero     <= EX_Zero;

            MEM_btgt     <= EX_btgt;
            MEM_ALUOut   <= EX_ALUOut;
            MEM_rd2      <= EX_rd2;
            MEM_RegRd    <= EX_RegRd;
        end
    end

    // ********************************************************************
    //                              MEM Stage
    // ********************************************************************

    mem32 		MEM_DMEM(clk, MEM_MemRead, MEM_MemWrite, MEM_ALUOut, MEM_rd2, MEM_memout);

    and  		MEM_BR_AND(MEM_PCSrc, MEM_Branch, MEM_Zero);

    always @(posedge clk)		// MEM/WB Pipeline Register
    begin
        if (reset)
        begin
            WB_RegWrite <= 0;
            WB_MemtoReg <= 0;
            WB_ALUOut   <= 0;
            WB_memout   <= 0;
            WB_RegRd    <= 0;
        end
        else begin
            WB_RegWrite <= MEM_RegWrite;
            WB_MemtoReg <= MEM_MemtoReg;
            WB_ALUOut   <= MEM_ALUOut;
            WB_memout   <= MEM_memout;
            WB_RegRd    <= MEM_RegRd;
        end
    end       

    // ********************************************************************
    //                              WB Stage
    // ********************************************************************

    mux2 #(32)	WB_WRMUX(WB_MemtoReg, WB_ALUOut, WB_memout, WB_wd);


endmodule

