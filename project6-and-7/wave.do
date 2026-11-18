onerror {resume}
quietly WaveActivateNextPane {} 0
add wave -noupdate /hart_tb/valid
add wave -noupdate /hart_tb/rst
add wave -noupdate -radix hexadecimal /hart_tb/pc
add wave -noupdate -radix hexadecimal /hart_tb/inst
add wave -noupdate /hart_tb/dmem_wen
add wave -noupdate -radix hexadecimal /hart_tb/dmem_wdata
add wave -noupdate /hart_tb/dmem_valid
add wave -noupdate /hart_tb/dmem_ren
add wave -noupdate /hart_tb/dmem_ready
add wave -noupdate -radix hexadecimal /hart_tb/dmem_rdata
add wave -noupdate -radix hexadecimal /hart_tb/dmem_addr
add wave -noupdate /hart_tb/clk
add wave -noupdate /hart_tb/dut/o_IF_ID_nop_signal
add wave -noupdate /hart_tb/dut/o_ID_EX_nop_signal
add wave -noupdate /hart_tb/dut/o_EX_MEM_nop_signal
add wave -noupdate /hart_tb/dut/o_MEM_WB_nop_signal
add wave -noupdate /hart_tb/dut/IF_ID_prev_flush
add wave -noupdate /hart_tb/dut/ID_EX_flush
add wave -noupdate -radix hexadecimal /hart_tb/dut/u_fetch/o_instruction
add wave -noupdate -radix hexadecimal /hart_tb/dut/u_memory/o_dmem_wdata
add wave -noupdate -radix hexadecimal /hart_tb/dut/u_memory/o_dmem_addr
add wave -noupdate -radix hexadecimal /hart_tb/dut/u_memory/i_dmem_rdata
add wave -noupdate -group DMTC /hart_tb/dut/u_memory/iDTMC/wen_actual
add wave -noupdate -group DMTC /hart_tb/dut/u_memory/iDTMC/state
add wave -noupdate -group DMTC /hart_tb/dut/u_memory/iDTMC/stall
add wave -noupdate -group DMTC /hart_tb/dut/u_memory/iDTMC/ren_actual
add wave -noupdate -group DMTC /hart_tb/dut/u_memory/iDTMC/READ_DATA
add wave -noupdate -group DMTC /hart_tb/dut/u_memory/iDTMC/next_state
add wave -noupdate -group DMTC /hart_tb/dut/u_memory/iDTMC/i_rst
add wave -noupdate -group DMTC /hart_tb/dut/u_memory/iDTMC/i_clk
add wave -noupdate -group DMTC /hart_tb/dut/u_memory/iDTMC/EX_MEM_wen
add wave -noupdate -group DMTC /hart_tb/dut/u_memory/iDTMC/EX_MEM_ren
add wave -noupdate -group DMTC /hart_tb/dut/u_memory/iDTMC/dmem_valid
add wave -noupdate -group DMTC /hart_tb/dut/u_memory/iDTMC/dmem_ready
add wave -noupdate -group DMTC /hart_tb/dut/u_memory/iDTMC/CHILLIN
add wave -noupdate -expand -group {Stall & Flush Signals} /hart_tb/dut/MEM_WB_flush
add wave -noupdate -expand -group {Stall & Flush Signals} /hart_tb/dut/IF_ID_stall
add wave -noupdate -expand -group {Stall & Flush Signals} /hart_tb/dut/IF_ID_flush
add wave -noupdate -expand -group {Stall & Flush Signals} /hart_tb/dut/ID_EX_stall
add wave -noupdate -expand -group {Stall & Flush Signals} /hart_tb/dut/ID_EX_flush
add wave -noupdate -expand -group {Stall & Flush Signals} /hart_tb/dut/EX_MEM_stall
add wave -noupdate -expand -group {Stall & Flush Signals} /hart_tb/dut/ebreak_flush
add wave -noupdate -expand -group {Stall & Flush Signals} /hart_tb/dut/dmtc_stall
add wave -noupdate -group {Fetch Invalid Stuff} /hart_tb/dut/u_fetch/o_flush_invalid
add wave -noupdate -group {Fetch Invalid Stuff} /hart_tb/dut/u_fetch/o_branch_flush
add wave -noupdate -group {Fetch Invalid Stuff} -radix hexadecimal /hart_tb/imem/o_rdata
add wave -noupdate -group {FTC Statemachine} /hart_tb/dut/u_fetch/fsm_ftc/valid
add wave -noupdate -group {FTC Statemachine} /hart_tb/dut/u_fetch/fsm_ftc/state
add wave -noupdate -group {FTC Statemachine} /hart_tb/dut/u_fetch/fsm_ftc/stall
add wave -noupdate -group {FTC Statemachine} /hart_tb/dut/u_fetch/fsm_ftc/ren
add wave -noupdate -group {FTC Statemachine} /hart_tb/dut/u_fetch/fsm_ftc/ready
add wave -noupdate -group {FTC Statemachine} /hart_tb/dut/u_fetch/fsm_ftc/pc_target
add wave -noupdate -group {FTC Statemachine} /hart_tb/dut/u_fetch/fsm_ftc/pc_increment
add wave -noupdate -group {FTC Statemachine} /hart_tb/dut/u_fetch/fsm_ftc/next_state
add wave -noupdate -group {FTC Statemachine} /hart_tb/dut/u_fetch/fsm_ftc/inflight_cnt
add wave -noupdate -group {FTC Statemachine} /hart_tb/dut/u_fetch/fsm_ftc/inc
add wave -noupdate -group {FTC Statemachine} /hart_tb/dut/u_fetch/fsm_ftc/imem_output_pc
add wave -noupdate -group {FTC Statemachine} /hart_tb/dut/u_fetch/fsm_ftc/i_rst
add wave -noupdate -group {FTC Statemachine} /hart_tb/dut/u_fetch/fsm_ftc/i_clk
add wave -noupdate -group {FTC Statemachine} /hart_tb/dut/u_fetch/fsm_ftc/flush_invalid
add wave -noupdate -group {FTC Statemachine} /hart_tb/dut/u_fetch/fsm_ftc/ebreak_flush
add wave -noupdate -group {FTC Statemachine} /hart_tb/dut/u_fetch/fsm_ftc/INIT
add wave -noupdate -group {FTC Statemachine} /hart_tb/dut/u_fetch/fsm_ftc/RUN
add wave -noupdate -group {FTC Statemachine} /hart_tb/dut/u_fetch/fsm_ftc/EBREAK
add wave -noupdate -group {FTC Statemachine} /hart_tb/dut/u_fetch/fsm_ftc/STALL
add wave -noupdate -group {FTC Statemachine} /hart_tb/dut/u_fetch/fsm_ftc/FLUSH
add wave -noupdate -group {FTC Statemachine} /hart_tb/dut/u_fetch/fsm_ftc/ebreak
add wave -noupdate -group {FTC Statemachine} /hart_tb/dut/u_fetch/fsm_ftc/dec
add wave -noupdate -group {FTC Statemachine} /hart_tb/dut/u_fetch/fsm_ftc/branch_flush
add wave -noupdate -group {FTC Statemachine} /hart_tb/dut/u_fetch/fsm_ftc/branch
add wave -noupdate /hart_tb/dut/pc_imm_sel
TreeUpdate [SetDefaultTree]
WaveRestoreCursors {{Cursor 1} {686281 ps} 0}
quietly wave cursor active 1
configure wave -namecolwidth 286
configure wave -valuecolwidth 232
configure wave -justifyvalue left
configure wave -signalnamewidth 0
configure wave -snapdistance 10
configure wave -datasetprefix 0
configure wave -rowmargin 4
configure wave -childrowmargin 2
configure wave -gridoffset 0
configure wave -gridperiod 1
configure wave -griddelta 40
configure wave -timeline 0
configure wave -timelineunits ps
update
WaveRestoreZoom {501142 ps} {860504 ps}
