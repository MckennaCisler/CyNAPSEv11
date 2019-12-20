/*
-----------------------------------------------------
| Created on: 12.21.2018		            							
| Author: Saunak Saha				    
| Modified by Mckenna Cisler
|                                                   
| Department of Electrical and Computer Engineering  
| Iowa State University                             
-----------------------------------------------------
*/




`timescale 1ns/1ns
module Top_syn_tb
#(
	//Global Timer resolution and limits
	parameter DELTAT_WIDTH = 4,																			//Resolution upto 0.1 ms can be supported 
	parameter BT_WIDTH_INT = 32,																			//2^32 supports 4,000M BT Units (ms) so for 500 ms exposure per example it can support 8M examples
	parameter BT_WIDTH_FRAC = DELTAT_WIDTH,																//BT Follows resolution 
	parameter BT_WIDTH = BT_WIDTH_INT + BT_WIDTH_FRAC,	

	//Data precision 
	parameter INTEGER_WIDTH = 32,																			//All Integer parameters should lie between +/- 2048
	parameter DATA_WIDTH_FRAC = 32,																		//Selected fractional precision for all status data
	parameter DATA_WIDTH = INTEGER_WIDTH + DATA_WIDTH_FRAC,
	parameter TREF_WIDTH = 5,																				//Refractory periods should lie between +/- 16 (integer)
	parameter EXTEND_WIDTH = (TREF_WIDTH+3)*2,																//For Refractory Value Arithmetic

	//Neuron counts and restrictions
	parameter NEURON_WIDTH_LOGICAL = 14,																	//For 2^14 = 16384 supported logical neurons
	parameter NEURON_WIDTH = NEURON_WIDTH_LOGICAL,
	parameter NEURON_WIDTH_INPUT = 11,																		//For 2^11 = 2048 supported input neurons
	parameter NEURON_WIDTH_PHYSICAL = 6,																	//For 2^6 = 64 physical neurons on-chip
	parameter TDMPOWER = NEURON_WIDTH_LOGICAL - NEURON_WIDTH_PHYSICAL,										//The degree of Time division multiplexing of logical to physical neurons
	parameter INPUT_NEURON_START = 0,																		//Input neurons in Weight table starts from index: 0 
	parameter LOGICAL_NEURON_START = 2**NEURON_WIDTH_INPUT,												//Logical neurons in Weight Table starts from index: 2048

	//On-chip Neuron status SRAMs
	parameter SPNR_WORD_WIDTH = ((DATA_WIDTH*6)+(TREF_WIDTH+3)+ NEURON_WIDTH_LOGICAL + 1 + 1),				//Format : |NID|Valid|Ntype|Vmem|Gex|Gin|RefVal|ExWeight|InWeight|Vth| 
	parameter SPNR_ADDR_WIDTH = TDMPOWER,																	//This many entries in each On-chip SRAM 
	
	//Off-Chip Weight RAM
	parameter WRAM_WORD_WIDTH = DATA_WIDTH,																//Weight bit-width is same as all status data bit-width
	parameter WRAM_ROW_WIDTH = 15,
	parameter WRAM_NUM_ROWS = 2**NEURON_WIDTH_LOGICAL + 2**NEURON_WIDTH_INPUT,
	parameter WRAM_COLUMN_WIDTH = NEURON_WIDTH_LOGICAL, 
	parameter WRAM_NUM_COLUMNS = 2**NEURON_WIDTH_LOGICAL,
	parameter WRAM_ADDR_WIDTH = WRAM_ROW_WIDTH + WRAM_COLUMN_WIDTH,										//ADDR_WIDTH = 2* NEURON_WIDTH + 1 (2*X^2 Synapses for X logical neurons and X input neurons) ?? Not Exactly but works in the present Configuration
	
	//Off-Chip Theta RAM
	parameter TRAM_WORD_WIDTH = DATA_WIDTH,																//Vth bit-width = status bit-wdth
	parameter TRAM_ADDR_WIDTH = NEURON_WIDTH_LOGICAL,														//Adaptive thresholds supported for all logical neurons
	parameter TRAM_NUM_ROWS = 2**NEURON_WIDTH_LOGICAL,
	parameter TRAM_NUM_COLUMNS = 1,
	
	
	//Queues
	parameter FIFO_WIDTH = 10,																				//1024 FIFO Queue Entries 

	//Memory initialization binaries
	parameter WEIGHTFILE = "./binaries/Weights_SCWN_bin.mem",												//Binaries for Weights 
	parameter THETAFILE = "./binaries/Theta_SCWN_bin.mem",	
	
	//Real datatype conversion
	parameter sfDATA = 2.0 **- 32.0,
	parameter sfBT = 2.0 **- 4.0
)
(
	//Control Inputs
	input wire Clock,
	input wire Reset,
	input wire Initialize,
	input wire ExternalEnqueue,
	input wire ExternalDequeue,
	input wire Run,

	//AER Inputs
	input wire [(BT_WIDTH-1):0] ExternalBTIn,						  				  //Input AER Packet
	input wire [(NEURON_WIDTH-1):0] ExternalNIDIn,                                    //"

	//Global Inputs
	input wire [(DELTAT_WIDTH-1):0] DeltaT,                                           //Neuron Update or Global Biological Time Resolution 


	//Network Information 
	input wire [(NEURON_WIDTH-1):0] ExRangeLOWER,					  //Excitatory Neuron Range
	input wire [(NEURON_WIDTH-1):0] ExRangeUPPER,                                     //"
	input wire [(NEURON_WIDTH-1):0] InRangeLOWER,                                     //Inhibitory Neuron Range		
	input wire [(NEURON_WIDTH-1):0] InRangeUPPER,                                     //"
	input wire [(NEURON_WIDTH-1):0] IPRangeLOWER,                                     //Input Neuron Range
	input wire [(NEURON_WIDTH-1):0] IPRangeUPPER,                                     //"
	input wire [(NEURON_WIDTH-1):0] OutRangeLOWER,                                    //Output Neuron Range
	input wire [(NEURON_WIDTH-1):0] OutRangeUPPER,                                    //"
	input wire [(NEURON_WIDTH-1):0] NeuStart,                                         //Minimum Actual NeuronID in current network 
	input wire [(NEURON_WIDTH-1):0] NeuEnd, 
	
	//Status register initialization values
	input wire signed [(DATA_WIDTH-1):0] Vmem_Initial_EX,                             //Initial membrane voltage and conductances of Neurons for Pyramidal Cells			
	input wire signed [(DATA_WIDTH-1):0] gex_Initial_EX,                              //"
	input wire signed [(DATA_WIDTH-1):0] gin_Initial_EX,                              //"
	
	input wire signed [(DATA_WIDTH-1):0] Vmem_Initial_IN,                             //for Basket cells
	input wire signed [(DATA_WIDTH-1):0] gex_Initial_IN,                              //"	
	input wire signed [(DATA_WIDTH-1):0] gin_Initial_IN,                              //"


	//Neuron-specific characteristics	
	input wire signed [(INTEGER_WIDTH-1):0] RestVoltage_EX,                           //Neuron Specific Characteristics for Pyramidal Cells
	input wire signed [(INTEGER_WIDTH-1):0] Taumembrane_EX,                           
	input wire signed [(INTEGER_WIDTH-1):0] ExReversal_EX,                            
	input wire signed [(INTEGER_WIDTH-1):0] InReversal_EX,                            
	input wire signed [(INTEGER_WIDTH-1):0] TauExCon_EX,                              	
	input wire signed [(INTEGER_WIDTH-1):0] TauInCon_EX,                              
	input wire signed [(TREF_WIDTH-1):0] Refractory_EX,                               
	input wire signed [(INTEGER_WIDTH-1):0] ResetVoltage_EX,                          
	input wire signed [(DATA_WIDTH-1):0] Threshold_EX,                                
	
	input wire signed [(INTEGER_WIDTH-1):0] RestVoltage_IN,                           //for Basket Cells
	input wire signed [(INTEGER_WIDTH-1):0] Taumembrane_IN, 				
	input wire signed [(INTEGER_WIDTH-1):0] ExReversal_IN,						
	input wire signed [(INTEGER_WIDTH-1):0] InReversal_IN, 						
	input wire signed [(INTEGER_WIDTH-1):0] TauExCon_IN,						
	input wire signed [(INTEGER_WIDTH-1):0] TauInCon_IN,						
	input wire signed [(TREF_WIDTH-1):0] Refractory_IN,							
	input wire signed [(INTEGER_WIDTH-1):0] ResetVoltage_IN,					
	input wire signed [(DATA_WIDTH-1):0] Threshold_IN,							

	//AER Outputs
	output reg [(BT_WIDTH-1):0] ExternalBTOut_out,                                        //Output AER Packet
	output reg [(NEURON_WIDTH-1):0] ExternalNIDOut_out,								

	//Control Outputs
	output reg InitializationComplete_out,                                               //Cue for completion of warm-up and start Running
	output reg WChipEnable_out,
	output reg ThetaChipEnable_out,
	
	//Off-Chip RAM I/O
	output reg [(WRAM_ADDR_WIDTH-1):0] WRAMAddress_out,
	input wire [(WRAM_WORD_WIDTH-1):0] WeightData,
	output reg [(TRAM_ADDR_WIDTH-1):0] ThetaAddress_out,
	input wire [(TRAM_WORD_WIDTH-1):0] ThetaData,

	//On-Chip RAM I/O 
	output reg [(2**NEURON_WIDTH_PHYSICAL -1):0] SPNR_CE_out,
	output reg [(2**NEURON_WIDTH_PHYSICAL -1):0] SPNR_WE_out,
	output reg [(SPNR_ADDR_WIDTH)*(2**NEURON_WIDTH_PHYSICAL) - 1:0] SPNR_IA_out,
	output reg [(SPNR_WORD_WIDTH)*(2**NEURON_WIDTH_PHYSICAL) - 1:0] SPNR_ID_out,
	
	//Input FIFO
	output reg InputReset_out,
	output reg InputQueueEnable_out,
	output reg InputEnqueue_out,
	output reg InputDequeue_out,
	output reg [(BT_WIDTH-1):0] InFIFOBTIn_out,
	output reg [(NEURON_WIDTH-1):0] InFIFONIDIn_out,

	input wire [(BT_WIDTH-1):0] InFIFOBTOut,
	input wire [(NEURON_WIDTH-1):0] InFIFONIDOut,
	input wire [(BT_WIDTH-1):0] InputBT_Head,
	input wire IsInputQueueEmpty,
	input wire IsInputQueueFull,

	//Aux FIFO
	output reg AuxReset_out,
	output reg AuxQueueEnable_out,
	output reg AuxEnqueue_out,
	output reg AuxDequeue_out,
	output reg [(BT_WIDTH-1):0] AuxFIFOBTIn_out,
	output reg [(NEURON_WIDTH-1):0] AuxFIFONIDIn_out,

	input wire [(BT_WIDTH-1):0] AuxFIFOBTOut,
	input wire [(NEURON_WIDTH-1):0] AuxFIFONIDOut,
	input wire [(BT_WIDTH-1):0] AuxBT_Head,
	input wire IsAuxQueueEmpty,
	input wire IsAuxQueueFull,

	//Out FIFO
	output reg OutReset_out,
	output reg OutQueueEnable_out,
	output reg OutEnqueue_out,
	output reg OutDequeue_out,
	output reg [(BT_WIDTH-1):0] OutFIFOBTIn_out,
	output reg [(NEURON_WIDTH-1):0] OutFIFONIDIn_out,

	input wire [(BT_WIDTH-1):0] OutFIFOBTOut,
	input wire [(NEURON_WIDTH-1):0] OutFIFONIDOut,
	input wire [(BT_WIDTH-1):0] OutBT_Head,
	input wire IsOutQueueEmpty,
	input wire IsOutQueueFull
);								 

	reg [(BT_WIDTH-1):0] ExternalBTOut;                                  
	reg [(NEURON_WIDTH-1):0] ExternalNIDOut;								
	reg InitializationComplete;
	reg WChipEnable;
	reg ThetaChipEnable;
	reg [(WRAM_ADDR_WIDTH-1):0] WRAMAddress;
	reg [(TRAM_ADDR_WIDTH-1):0] ThetaAddress;
	reg [(2**NEURON_WIDTH_PHYSICAL -1):0] SPNR_CE;
	reg [(2**NEURON_WIDTH_PHYSICAL -1):0] SPNR_WE;
	reg [(SPNR_ADDR_WIDTH)*(2**NEURON_WIDTH_PHYSICAL) - 1:0] SPNR_IA;
	reg [(SPNR_WORD_WIDTH)*(2**NEURON_WIDTH_PHYSICAL) - 1:0] SPNR_ID;
	reg InputReset;
	reg InputQueueEnable;
	reg InputEnqueue;
	reg InputDequeue;
	reg [(BT_WIDTH-1):0] InFIFOBTIn;
	reg [(NEURON_WIDTH-1):0] InFIFONIDIn;
	reg AuxReset;
	reg AuxQueueEnable;
	reg AuxEnqueue;
	reg AuxDequeue;
	reg [(BT_WIDTH-1):0] AuxFIFOBTIn;
	reg [(NEURON_WIDTH-1):0] AuxFIFONIDIn;
	reg OutReset;
	reg OutQueueEnable;
	reg OutEnqueue;
	reg OutDequeue;
	reg [(BT_WIDTH-1):0] OutFIFOBTIn;
	reg [(NEURON_WIDTH-1):0] OutFIFONIDIn;

	always@(posedge Clock)
	begin
		ExternalBTOut_out <= ExternalBTOut;                            
		ExternalNIDOut_out <= ExternalNIDOut;
		InitializationComplete_out <= InitializationComplete;
		WChipEnable_out <= WChipEnable;
		ThetaChipEnable_out <= ThetaChipEnable;
		WRAMAddress_out <= WRAMAddress;
		ThetaAddress_out <= ThetaAddress;
		SPNR_CE_out <= SPNR_CE;
		SPNR_WE_out <= SPNR_WE;
		SPNR_IA_out <= SPNR_IA;
		SPNR_ID_out <= SPNR_ID;
		InputReset_out <= InputReset;
		InputQueueEnable_out <= InputQueueEnable;
		InputEnqueue_out <= InputEnqueue;
		InputDequeue_out <= InputDequeue;
		InFIFOBTIn_out <= InFIFOBTIn;
		InFIFONIDIn_out <= InFIFONIDIn;
		AuxReset_out <= AuxReset;
		AuxQueueEnable_out <= AuxQueueEnable;
		AuxEnqueue_out <= AuxEnqueue;
		AuxDequeue_out <= AuxDequeue;
		AuxFIFOBTIn_out <= AuxFIFOBTIn;
		AuxFIFONIDIn_out <= AuxFIFONIDIn;
		OutReset_out <= OutReset;
		OutQueueEnable_out <= OutQueueEnable;
		OutEnqueue_out <= OutEnqueue;
		OutDequeue_out <= OutDequeue;
		OutFIFOBTIn_out <= OutFIFOBTIn;
		OutFIFONIDIn_out <= OutFIFONIDIn;
	end
	

	wire [(SPNR_WORD_WIDTH)*(2**NEURON_WIDTH_PHYSICAL) - 1:0] SPNR_OD;

	//I/O Files
	genvar phy;
	
	integer BTFile, NIDFile, ScanBT, ScanNID;
	
	reg signed [(DATA_WIDTH-1):0] IDVmemEx;
	reg signed [(DATA_WIDTH-1):0] IDVmemIn; 
	reg signed [(DATA_WIDTH-1):0] IDGexEx; 
	reg signed [(DATA_WIDTH-1):0] IDGexIn;
	reg signed [(DATA_WIDTH-1):0] IDGinEx; 
	reg signed [(DATA_WIDTH-1):0] IDGinIn;

	//Per-physical (On-Chip) RAM Signal copies
	wire SPNRChipEnable [(2**NEURON_WIDTH_PHYSICAL -1):0]; 
	wire SPNRWriteEnable [(2**NEURON_WIDTH_PHYSICAL -1):0];
	wire [(SPNR_ADDR_WIDTH-1):0] SPNRInputAddress [(2**NEURON_WIDTH_PHYSICAL -1):0];
	wire [(SPNR_WORD_WIDTH-1):0] SPNRInputData [(2**NEURON_WIDTH_PHYSICAL -1):0]; 
	wire [(SPNR_WORD_WIDTH-1):0] SPNROutputData [(2**NEURON_WIDTH_PHYSICAL -1):0];

	for (phy=0; phy<2**NEURON_WIDTH_PHYSICAL;phy = phy+1) begin
		assign SPNRChipEnable[phy] = SPNR_CE[phy];
		assign SPNRWriteEnable[phy] = SPNR_WE[phy];
		assign SPNRInputAddress[phy] = SPNR_IA[((phy+1)*SPNR_ADDR_WIDTH)-1:SPNR_ADDR_WIDTH*phy];
		assign SPNRInputData[phy] = SPNR_ID[((phy+1)*SPNR_WORD_WIDTH)-1:SPNR_WORD_WIDTH*phy];

		assign SPNR_OD[((phy+1)*SPNR_WORD_WIDTH)-1:SPNR_WORD_WIDTH*phy] = SPNROutputData[phy];
	end


	
	integer initStart, initEnd, BTStart, BTEnd, initCycles, BTCycles, numBT, AverageBTCycles;
	
	Top #(DELTAT_WIDTH, BT_WIDTH_INT, BT_WIDTH_FRAC, BT_WIDTH, INTEGER_WIDTH, DATA_WIDTH_FRAC, DATA_WIDTH, TREF_WIDTH, EXTEND_WIDTH, NEURON_WIDTH_LOGICAL, NEURON_WIDTH, NEURON_WIDTH_INPUT, NEURON_WIDTH_PHYSICAL, TDMPOWER, INPUT_NEURON_START, LOGICAL_NEURON_START, SPNR_WORD_WIDTH, SPNR_ADDR_WIDTH, WRAM_WORD_WIDTH, WRAM_ROW_WIDTH, WRAM_NUM_ROWS, WRAM_COLUMN_WIDTH, WRAM_NUM_COLUMNS, WRAM_ADDR_WIDTH, TRAM_WORD_WIDTH, TRAM_ADDR_WIDTH, TRAM_NUM_ROWS, TRAM_NUM_COLUMNS, FIFO_WIDTH, WEIGHTFILE, THETAFILE) CyNAPSE
	(
		//Control Inputs
		.Clock(Clock),
		.Reset(Reset),
		.Initialize(Initialize),
		.ExternalEnqueue(ExternalEnqueue),
		.ExternalDequeue(ExternalDequeue),
		.Run(Run),

		//AER Inputs
		.ExternalBTIn(ExternalBTIn),
		.ExternalNIDIn(ExternalNIDIn),
	
		//Global Inputs 
		.DeltaT(DeltaT),
		
		//Network Information
		.ExRangeLOWER(ExRangeLOWER),			
		.ExRangeUPPER(ExRangeUPPER),			
		.InRangeLOWER(InRangeLOWER),					
		.InRangeUPPER(InRangeUPPER),			
		.IPRangeLOWER(IPRangeLOWER),			
		.IPRangeUPPER(IPRangeUPPER),
		.OutRangeLOWER(OutRangeLOWER),
		.OutRangeUPPER(OutRangeUPPER),			
		.NeuStart(NeuStart),			
		.NeuEnd(NeuEnd),

		//Status register initialization values 
		.Vmem_Initial_EX(Vmem_Initial_EX),
		.gex_Initial_EX(gex_Initial_EX),
		.gin_Initial_EX(gin_Initial_EX),
	
		.Vmem_Initial_IN(Vmem_Initial_IN),
		.gex_Initial_IN(gex_Initial_IN),
		.gin_Initial_IN(gin_Initial_IN),

		//Neuron-specific characteristics
		.RestVoltage_EX(RestVoltage_EX), 	
		.Taumembrane_EX(Taumembrane_EX), 	
		.ExReversal_EX(ExReversal_EX),	
		.InReversal_EX(InReversal_EX), 	
		.TauExCon_EX(TauExCon_EX),	
		.TauInCon_EX(TauInCon_EX),	
		.Refractory_EX(Refractory_EX),		
		.ResetVoltage_EX(ResetVoltage_EX),	
		.Threshold_EX(Threshold_EX),
	
		.RestVoltage_IN(RestVoltage_IN), 	
		.Taumembrane_IN(Taumembrane_IN), 	
		.ExReversal_IN(ExReversal_IN),	
		.InReversal_IN(InReversal_IN), 	
		.TauExCon_IN(TauExCon_IN),	
		.TauInCon_IN(TauInCon_IN),	
		.Refractory_IN(Refractory_IN),		
		.ResetVoltage_IN(ResetVoltage_IN),	
		.Threshold_IN(Threshold_IN),

		//AEROutputs
		.ExternalBTOut(OutFIFOBTOut),
		.ExternalNIDOut(OutFIFONIDOut),

		//Control Outputs
		.InitializationComplete(InitializationComplete),
		.WChipEnable(WChipEnable),
		.ThetaChipEnable(ThetaChipEnable),

		//Off-Chip RAM I/O
		.WRAMAddress(WRAMAddress),
		.WeightData(WeightData),
		.ThetaAddress(ThetaAddress),
		.ThetaData(ThetaData),

		//On-Chip RAM I/O
		.SPNR_CE(SPNR_CE),
		.SPNR_WE(SPNR_WE),
		.SPNR_IA(SPNR_IA),
		.SPNR_ID(SPNR_ID),
		.SPNR_OD(SPNR_OD),

		//FIFO Controls

		//Input FIFO
		.InputReset(InputReset),
		.InputQueueEnable(InputQueueEnable),
		.InputEnqueue(InputEnqueue),
		.InputDequeue(InputDequeue),
		.InFIFOBTIn(InFIFOBTIn),
		.InFIFONIDIn(InFIFONIDIn),

		.InFIFOBTOut(InFIFOBTOut),
		.InFIFONIDOut(InFIFONIDOut),
		.InputBT_Head(InputBT_Head),
		.IsInputQueueEmpty(IsInputQueueEmpty),
		.IsInputQueueFull(IsInputQueueFull),

		//Aux FIFO
		.AuxReset(AuxReset),
		.AuxQueueEnable(AuxQueueEnable),
		.AuxEnqueue(AuxEnqueue),
		.AuxDequeue(AuxDequeue),
		.AuxFIFOBTIn(AuxFIFOBTIn),
		.AuxFIFONIDIn(AuxFIFONIDIn),

		.AuxFIFOBTOut(AuxFIFOBTOut),
		.AuxFIFONIDOut(AuxFIFONIDOut),
		.AuxBT_Head(AuxBT_Head),
		.IsAuxQueueEmpty(IsAuxQueueEmpty),
		.IsAuxQueueFull(IsAuxQueueFull),

		//Out FIFO
		.OutReset(OutReset),
		.OutQueueEnable(OutQueueEnable),
		.OutEnqueue(OutEnqueue),
		.OutDequeue(OutDequeue),
		.OutFIFOBTIn(OutFIFOBTIn),
		.OutFIFONIDIn(OutFIFONIDIn),

		.OutFIFOBTOut(OutFIFOBTOut),
		.OutFIFONIDOut(OutFIFONIDOut),
		.OutBT_Head(OutBT_Head),
		.IsOutQueueEmpty(IsOutQueueEmpty),
		.IsOutQueueFull(IsOutQueueFull)


	);


	/***************************************************************
		ON-CHIP RAMs	
	***************************************************************/

	generate 
		genvar x;
		for (x = 0; x< (2**NEURON_WIDTH_PHYSICAL); x = x+1) begin

			//On-Chip Neuron Status RAMs
			SinglePortNeuronRAM #(INTEGER_WIDTH, DATA_WIDTH_FRAC, DATA_WIDTH, TREF_WIDTH, NEURON_WIDTH_LOGICAL, SPNR_WORD_WIDTH, SPNR_ADDR_WIDTH) SPNR_x(
					.Clock(Clock),
	 				.Reset(Reset),
				 	.ChipEnable(SPNRChipEnable[x]),
					.WriteEnable(SPNRWriteEnable[x]),
					.InputData(SPNRInputData[x]),
				 	.InputAddress(SPNRInputAddress[x]),

 					.OutputData(SPNROutputData[x])
				);
		end
	endgenerate 







endmodule
