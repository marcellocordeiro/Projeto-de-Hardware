module Unidade_de_Controle (input logic clock, reset,
                            input logic [5:0] opcode, funct,
                            input logic Zero_flag,
                            output logic PCWrite, IorD, MemReadWrite, IRWrite, AluSrcA, RegWrite,
                                         RegDst, AWrite, BWrite, AluOutWrite, MDRWrite,
                            output logic [1:0] PCSource, AluSrcB, MemtoReg,
                            output logic [5:0] State_out,
                            output logic [2:0] ALUOpOut);

enum logic [5:0] {Fetch_PC, Fetch_E1, Fetch_E2, Decode, // Fetch e Decode
                  Arit_Read, Arit_Store, Break, JumpRegister, // Tipo R
                  BeqAddress, BeqCompare, MemComputation, MemComputation_E1, MemComputation_E2, AritImmRead, AritImmStore,  //Tipo I
                  MemRead, MemRead_E1, MemRead_E2, MemRead_E3, MemWrite, // Tipo I
                  Lui, Jump} state, nextState; //Tipo J

enum logic [2:0] {LOAD, ADD, SUB, AND, INC, NEG, XOR, COMP} ALUOp;

assign State_out = state;
assign ALUOpOut = ALUOp;

always_ff@ (posedge clock, posedge reset)
    if (reset)
        state <= Fetch_PC;
    else
        state <= nextState;

always_comb
    case (state)
        Fetch_PC: begin
            PCWrite = 0;
            IorD = 0;
            MemReadWrite = 0; // read
            MemtoReg = 2'bxx;
            IRWrite = 0;
            AluSrcA = 0; // PC
            RegWrite = 0;
            RegDst = 1'bx;
            AWrite = 0;
            BWrite = 0;
            AluOutWrite = 0;
            MDRWrite = 1;

            PCSource = 0;
            AluSrcB = 1;

            ALUOp = LOAD;

            nextState = Fetch_E1;
        end

        Fetch_E1: begin // espera 1
            PCWrite = 0;
            IorD = 0;
            MemReadWrite = 0;
            MemtoReg = 2'bxx;
            IRWrite = 0;
            AluSrcA = 0;
            RegWrite = 0;
            RegDst = 1'bx;
            AWrite = 0;
            BWrite = 0;
            AluOutWrite = 0;
            MDRWrite = 1;

            PCSource = 0;
            AluSrcB = 1;

            ALUOp = ADD;

            nextState = Fetch_E2;
        end

        Fetch_E2: begin // espera 2
            PCWrite = 1;
            IorD = 0;
            MemReadWrite = 0;
            MemtoReg = 2'bxx;
            IRWrite = 1;
            AluSrcA = 0; // PC
            RegWrite = 0;
            RegDst = 1'bx;
            AWrite = 1;
            BWrite = 1;
            AluOutWrite = 0;
            MDRWrite = 1;

            PCSource = 2'b00;
            AluSrcB = 2'b01;

            ALUOp = ADD;

            nextState = Decode;
        end

        Decode: begin
            PCWrite = 0;
            IorD = 0;
            MemReadWrite = 0;
            MemtoReg = 2'bxx;
            IRWrite = 0;
            AluSrcA = 0; // PC
            RegWrite = 0;
            RegDst = 1'bx;
            AWrite = 1;
            BWrite = 1;
            AluOutWrite = 1; // PC + branch address << 2
            MDRWrite = 0;

            PCSource = 0;
            AluSrcB = 2'b11; // branch address << 2

            ALUOp = ADD;

            case (opcode)
                6'h0: begin
                    case (funct)
                        6'h20, 6'h22, 6'h26, 6'h24:
                            nextState = Arit_Read;
                        6'hd, 6'h0:
                            nextState = Break;
                        6'h8: // jr
                            nextState = JumpRegister;
                        default:
                            nextState = Fetch_PC;
                    endcase
                end

                6'h2:
                    nextState = Jump;
                //6'h3:
                //    nextState = jal;
                6'h2b, 6'h23:
                    nextState = MemComputation;
                6'h0f:
                    nextState = Lui;
                6'h4, 6'h5:
                    nextState = BeqCompare;
                6'h8, 6'h9, 6'hc, 6'ha, 6'he: // arit com immediate
                    nextState = AritImmRead;
                default:
                    nextState = Fetch_PC;


            endcase
        end

        Arit_Read: begin
            PCWrite = 0;
            IorD = 0;
            MemReadWrite = 0;
            MemtoReg = 2'bxx;
            IRWrite = 0;
            AluSrcA = 1;
            RegWrite = 0;
            RegDst = 1'bx;
            AWrite = 1;
            BWrite = 1;
            AluOutWrite = 1;
            MDRWrite = 1'bx;

            PCSource = 0;
            AluSrcB = 0;

            case (funct)
                6'h20:
                    ALUOp = ADD;
                6'h22:
                    ALUOp = SUB;
                6'h24:
                    ALUOp = AND;
                6'h26:
                    ALUOp = XOR;
                default:
                    ALUOp = LOAD;
            endcase

            nextState = Arit_Store;
        end

        Arit_Store: begin
            PCWrite = 0;
            IorD = 0;
            MemReadWrite = 1'bx;
            MemtoReg = 0;
            IRWrite = 0;
            AluSrcA = 1;
            RegWrite = 1;
            RegDst = 1;
            AWrite = 0;
            BWrite = 0;
            AluOutWrite = 0;
            MDRWrite = 1'bx;

            PCSource = 0;
            AluSrcB = 0;

            case (funct)
                6'h20:
                    ALUOp = ADD;
                6'h22:
                    ALUOp = SUB;
                6'h24:
                    ALUOp = AND;
                6'h26:
                    ALUOp = XOR;
                default:
                    ALUOp = LOAD;
            endcase

            nextState = Fetch_PC;
        end

        Break: begin
            IorD = 0;
            MemReadWrite = 0;
            MemtoReg = 0;
            IRWrite = 0;
            AluSrcA = 0;
            RegWrite = 0;
            RegDst = 0;
            AWrite = 0;
            BWrite = 0;
            AluOutWrite = 0;
            MDRWrite = 0;

            PCSource = 0;
            AluSrcB = 0;

            ALUOp = LOAD;

            PCWrite = 0;

            if (funct == 6'h0) // nop
                nextState = Fetch_PC;
            else // break
                nextState = Break;
        end

        MemComputation: begin
            PCWrite = 0;
            IorD = 0;
            MemReadWrite = 1'bx;
            MemtoReg = 2'bxx;
            IRWrite = 0;
            AluSrcA = 1;
            RegWrite = 0;
            RegDst = 1'bx;
            AWrite = 1;
            BWrite = 1;
            AluOutWrite = 1;
            MDRWrite = 1'bx;

            PCSource = 0;
            AluSrcB = 2;

            ALUOp = ADD;

            nextState = MemComputation_E1;
        end

        MemComputation_E1: begin
            PCWrite = 0;
            IorD = 0;
            MemReadWrite = 1'bx;
            MemtoReg = 2'bxx;
            IRWrite = 0;
            AluSrcA = 1;
            RegWrite = 0;
            RegDst = 1'bx;
            AWrite = 1;
            BWrite = 1;
            AluOutWrite = 1;
            MDRWrite = 1'bx;

            PCSource = 0;
            AluSrcB = 2;

            ALUOp = ADD;

            nextState = MemComputation_E2;
        end

        MemComputation_E2: begin
            PCWrite = 0;
            IorD = 0;
            MemReadWrite = 1'bx;
            MemtoReg = 2'bxx;
            IRWrite = 0;
            AluSrcA = 1;
            RegWrite = 0;
            RegDst = 1'bx;
            AWrite = 1;
            BWrite = 1;
            AluOutWrite = 1;
            MDRWrite = 1'bx;

            PCSource = 0;
            AluSrcB = 2;

            ALUOp = ADD;

            if (opcode == 6'h23)
                nextState = MemRead;
            else
                nextState = MemWrite;
        end

        AritImmRead: begin
            PCWrite = 0;
            IorD = 0;
            MemReadWrite = 1'bx;
            MemtoReg = 2'bxx;
            IRWrite = 0;
            AluSrcA = 1;
            RegWrite = 0;
            RegDst = 1'bx;
            AWrite = 1;
            BWrite = 1;
            AluOutWrite = 1;
            MDRWrite = 1'bx;

            PCSource = 2'b00;
            AluSrcB = 2'b10;

            case (opcode)
                6'h8: // addi // com check de overflow
                    ALUOp = ADD;
                6'h9: // addiu // sem check de overflow
                    ALUOp = ADD; // fazer
                6'hc: // andi
                    ALUOp = AND;
                6'ha: // slti
                    ALUOp = LOAD; // fazer (seta rt se rs < imm) // fazer um load e verificar a saída Menor da ALU?
                6'he: //sxori
                    ALUOp = XOR;
                default:
                    ALUOp = LOAD;
            endcase

            nextState = AritImmStore;
        end

        AritImmStore: begin
            PCWrite = 0;
            IorD = 0;
            MemReadWrite = 1'bx;
            MemtoReg = 2'b00; // ?????
            IRWrite = 0;
            AluSrcA = 1;
            RegWrite = 1;
            RegDst = 0;
            AWrite = 0;
            BWrite = 0;
            AluOutWrite = 0;
            MDRWrite = 0;

            PCSource = 0;
            AluSrcB = 0;

            ALUOp = LOAD;

            /*case (funct)
                6'h20:
                    ALUOp = ADD;
                6'h22:
                    ALUOp = SUB;
                6'h24:
                    ALUOp = AND;
                6'h26:
                    ALUOp = XOR;
                default:
                    ALUOp = LOAD;
            endcase*/

            nextState = Fetch_PC;
        end

        MemRead: begin // corrigir/melhorar
            PCWrite = 0;
            IorD = 1'b1;
            MemReadWrite = 1'b0;
            MemtoReg = 1;
            IRWrite = 0;
            AluSrcA = 1;
            RegWrite = 0;
            RegDst = 1'b0;
            AWrite = 0;
            BWrite = 0;
            AluOutWrite = 0;
            MDRWrite = 1'b1;

            PCSource = 0;
            AluSrcB = 0;

            ALUOp = ADD;

            nextState = MemRead_E1;
        end

        MemRead_E1: begin
            PCWrite = 0;
            IorD = 1'b1;
            MemReadWrite = 1'b0;
            MemtoReg = 1;
            IRWrite = 0;
            AluSrcA = 1;
            RegWrite = 0;
            RegDst = 1'b0;
            AWrite = 0;
            BWrite = 0;
            AluOutWrite = 0;
            MDRWrite = 1'b1;

            PCSource = 0;
            AluSrcB = 0;

            ALUOp = ADD;

            nextState = MemRead_E2;
        end

        MemRead_E2: begin
            PCWrite = 0;
            IorD = 1'b1;
            MemReadWrite = 1'b0;
            MemtoReg = 0;
            IRWrite = 0;
            AluSrcA = 1;
            RegWrite = 0;
            RegDst = 1'b0;
            AWrite = 0;
            BWrite = 0;
            AluOutWrite = 0;
            MDRWrite = 1'b1;

            PCSource = 0;
            AluSrcB = 0;

            ALUOp = ADD;

            nextState = MemRead_E3;
        end

        MemRead_E3: begin
            PCWrite = 0;
            IorD = 1'b1;
            MemReadWrite = 1'b0;
            MemtoReg = 1;
            IRWrite = 0;
            AluSrcA = 1;
            RegWrite = 1;
            RegDst = 1'b0;
            AWrite = 0;
            BWrite = 0;
            AluOutWrite = 0;
            MDRWrite = 1'b1;

            PCSource = 0;
            AluSrcB = 0;

            ALUOp = ADD;

            nextState = Fetch_PC;
        end

        MemWrite: begin
            PCWrite = 0;
            IorD = 1'b1;
            MemReadWrite = 1'b1;
            MemtoReg = 1;
            IRWrite = 0;
            AluSrcA = 1;
            RegWrite = 0;
            RegDst = 1'b0;
            AWrite = 0;
            BWrite = 0;
            AluOutWrite = 0;
            MDRWrite = 1'b1;

            PCSource = 0;
            AluSrcB = 0;

            ALUOp = ADD;

            nextState = Fetch_PC;
        end

        Lui: begin
            PCWrite = 0;
            IorD = 1'bx;
            MemReadWrite = 1'bx;
            MemtoReg = 2;
            IRWrite = 0;
            AluSrcA = 1'bx;
            RegWrite = 1;
            RegDst = 0;
            AWrite = 0;
            BWrite = 0;
            AluOutWrite = 0;
            MDRWrite = 1'bx;

            PCSource = 0;
            AluSrcB = 2'bxx;

            ALUOp = LOAD;

            nextState = Fetch_PC;
        end

        Jump: begin
            PCWrite = 1;
            IorD = 1'bx;
            MemReadWrite = 1'bx;
            MemtoReg = 2'bxx;
            IRWrite = 0;
            AluSrcA = 1'bx;
            RegWrite = 0;
            RegDst = 1'bx;
            AWrite = 0;
            BWrite = 0;
            AluOutWrite = 0;
            MDRWrite = 1'bx;

            PCSource = 2;
            AluSrcB = 2'bxx;

            ALUOp = LOAD;

            nextState = Fetch_PC;
        end

        JumpRegister: begin
            PCWrite = 1;
            IorD = 1'bx;
            MemReadWrite = 1'bx;
            MemtoReg = 2'bxx;
            IRWrite = 0;
            AluSrcA = 1;
            RegWrite = 0;
            RegDst = 1'bx;
            AWrite = 1;
            BWrite = 1;
            AluOutWrite = 0;
            MDRWrite = 1'bx;

            PCSource = 0; // soma
            AluSrcB = 2'b00;

            ALUOp = ADD;

            nextState = Fetch_PC;
        end

        /*BeqAddress: begin
            PCWrite = 0;
            IorD = 0;
            MemReadWrite = 0;
            MemtoReg = 2;
            IRWrite = 0;
            AluSrcA = 0;
            RegWrite = 0;
            RegDst = 0;
            AWrite = 1;
            BWrite = 1;
            AluOutWrite = 1;
            MDRWrite = 0;

            PCSource = 0;
            AluSrcB = 3;

            ALUOp = ADD;
            nextState = BeqCompare;
        end*/

        BeqCompare: begin

            IorD = 0;
            MemReadWrite = 0;
            MemtoReg = 2;
            IRWrite = 0;
            AluSrcA = 1;
            RegWrite = 0;
            RegDst = 0;
            AWrite = 1;
            BWrite = 1;
            AluOutWrite = 0;
            MDRWrite = 0;

            AluSrcB = 2'b00;

            ALUOp = SUB;

            if (opcode == 6'h4) begin // beq
                if (Zero_flag == 1) begin
                    PCSource = 1;
                    PCWrite = 1;
                end
                else begin
                    PCSource = 0;
                    PCWrite = 0;
                end
            end
            else begin // opcode == 6'5, bne
                if (Zero_flag != 1) begin
                    PCSource = 1;
                    PCWrite = 1;
                end
                else begin
                    PCSource = 0;
                    PCWrite = 0;
                end
            end

            nextState = Fetch_PC;
        end
    endcase

endmodule: Unidade_de_Controle