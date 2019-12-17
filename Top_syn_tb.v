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
module Top_syn_tb();

	//Global Timer resolution and limits
	localparam DELTAT_WIDTH = 4;																			//Resolution upto 0.1 ms can be supported 
	localparam BT_WIDTH_INT = 32;																			//2^32 supports 4,000M BT Units (ms) so for 500 ms exposure per example it can support 8M examples
	localparam BT_WIDTH_FRAC = DELTAT_WIDTH;																//BT Follows resolution 
	localparam BT_WIDTH = BT_WIDTH_INT + BT_WIDTH_FRAC;	

	//Data precision 
	localparam INTEGER_WIDTH = 32;																			//All Integer localparams should lie between +/- 2048
	localparam DATA_WIDTH_FRAC = 32;																		//Selected fractional precision for all status data
	localparam DATA_WIDTH = INTEGER_WIDTH + DATA_WIDTH_FRAC;
	localparam TREF_WIDTH = 5;																				//Refractory periods should lie between +/- 16 (integer)
	localparam EXTEND_WIDTH = (TREF_WIDTH+3)*2;																//For Refractory Value Arithmetic

	//Neuron counts and restrictions
	localparam NEURON_WIDTH_LOGICAL = 14;																	//For 2^14 = 16384 supported logical neurons
	localparam NEURON_WIDTH = NEURON_WIDTH_LOGICAL;
	localparam NEURON_WIDTH_INPUT = 11;																		//For 2^11 = 2048 supported input neurons
	localparam NEURON_WIDTH_PHYSICAL = 6;																	//For 2^6 = 64 physical neurons on-chip
	localparam TDMPOWER = NEURON_WIDTH_LOGICAL - NEURON_WIDTH_PHYSICAL;										//The degree of Time division multiplexing of logical to physical neurons
	localparam INPUT_NEURON_START = 0;																		//Input neurons in Weight table starts from index: 0 
	localparam LOGICAL_NEURON_START = 2**NEURON_WIDTH_INPUT;												//Logical neurons in Weight Table starts from index: 2048

	//On-chip Neuron status SRAMs
	localparam SPNR_WORD_WIDTH = ((DATA_WIDTH*6)+(TREF_WIDTH+3)+ NEURON_WIDTH_LOGICAL + 1 + 1);				//Format : |NID|Valid|Ntype|Vmem|Gex|Gin|RefVal|ExWeight|InWeight|Vth| 
	localparam SPNR_ADDR_WIDTH = TDMPOWER;																	//This many entries in each On-chip SRAM 
	
	//Off-Chip Weight RAM
	localparam WRAM_WORD_WIDTH = DATA_WIDTH;																//Weight bit-width is same as all status data bit-width
	localparam WRAM_ROW_WIDTH = 15;
	localparam WRAM_NUM_ROWS = 2**NEURON_WIDTH_LOGICAL + 2**NEURON_WIDTH_INPUT;
	localparam WRAM_COLUMN_WIDTH = NEURON_WIDTH_LOGICAL;  
	localparam WRAM_NUM_COLUMNS = 2**NEURON_WIDTH_LOGICAL;
	localparam WRAM_ADDR_WIDTH = WRAM_ROW_WIDTH + WRAM_COLUMN_WIDTH;										//ADDR_WIDTH = 2* NEURON_WIDTH + 1 (2*X^2 Synapses for X logical neurons and X input neurons) ?? Not Exactly but works in the present Configuration
	
	//Off-Chip Theta RAM
	localparam TRAM_WORD_WIDTH = DATA_WIDTH;																//Vth bit-width = status bit-wdth
	localparam TRAM_ADDR_WIDTH = NEURON_WIDTH_LOGICAL;														//Adaptive thresholds supported for all logical neurons
	localparam TRAM_NUM_ROWS = 2**NEURON_WIDTH_LOGICAL;
	localparam TRAM_NUM_COLUMNS = 1;
	
	
	//Queues
	localparam FIFO_WIDTH = 10;																				//1024 FIFO Queue Entries 

	//Memory initialization binaries
	localparam WEIGHTFILE = "./binaries/Weights_SCWN_bin.mem";												//Binaries for Weights 
	localparam THETAFILE = "./binaries/Theta_SCWN_bin.mem";	
	
	//Real datatype conversion
	localparam sfDATA = 2.0 **- 32.0;
	localparam sfBT = 2.0 **- 4.0;


	//Control Inputs
	reg  Clock;
	reg  Reset;
	reg  Initialize;
	reg  ExternalEnqueue;
	reg  ExternalDequeue;
	reg  Run;

	//AER Inputs
	reg  [(BT_WIDTH-1):0] ExternalBTIn;
	reg  [(NEURON_WIDTH-1):0] ExternalNIDIn;

	//Global Inputs
	reg  [(DELTAT_WIDTH-1):0] DeltaT;																//DeltaT = 0.5ms  


	//Network Information 
	reg  [(NEURON_WIDTH-1):0] ExRangeLOWER;							
	reg  [(NEURON_WIDTH-1):0] ExRangeUPPER;							
	reg  [(NEURON_WIDTH-1):0] InRangeLOWER;							 	
	reg  [(NEURON_WIDTH-1):0] InRangeUPPER;							
	reg  [(NEURON_WIDTH-1):0] IPRangeLOWER;							
	reg  [(NEURON_WIDTH-1):0] IPRangeUPPER;							
	reg  [(NEURON_WIDTH-1):0] OutRangeLOWER;							
	reg  [(NEURON_WIDTH-1):0] OutRangeUPPER;							
	reg  [(NEURON_WIDTH-1):0] NeuStart;							 
	reg  [(NEURON_WIDTH-1):0] NeuEnd;								 

	
	//Status register initialization values
	reg signed [(DATA_WIDTH-1):0] Vmem_Initial_EX;
	reg signed [(DATA_WIDTH-1):0] gex_Initial_EX;
	reg signed [(DATA_WIDTH-1):0] gin_Initial_EX;
	
	reg signed [(DATA_WIDTH-1):0] Vmem_Initial_IN;
	reg signed [(DATA_WIDTH-1):0] gex_Initial_IN;
	reg signed [(DATA_WIDTH-1):0] gin_Initial_IN;


	//Neuron-specific characteristics	
	reg signed [(INTEGER_WIDTH-1):0] RestVoltage_EX; 	
	reg signed [(INTEGER_WIDTH-1):0] Taumembrane_EX; 	
	reg signed [(INTEGER_WIDTH-1):0] ExReversal_EX;	
	reg signed [(INTEGER_WIDTH-1):0] InReversal_EX; 	
	reg signed [(INTEGER_WIDTH-1):0] TauExCon_EX;	
	reg signed [(INTEGER_WIDTH-1):0] TauInCon_EX;	
	reg signed [(TREF_WIDTH-1):0] Refractory_EX;		
	reg signed [(INTEGER_WIDTH-1):0] ResetVoltage_EX;	
	reg signed [(DATA_WIDTH-1):0] Threshold_EX;

	reg signed [(INTEGER_WIDTH-1):0] RestVoltage_IN; 	
	reg signed [(INTEGER_WIDTH-1):0] Taumembrane_IN; 	
	reg signed [(INTEGER_WIDTH-1):0] ExReversal_IN;	
	reg signed [(INTEGER_WIDTH-1):0] InReversal_IN; 	
	reg signed [(INTEGER_WIDTH-1):0] TauExCon_IN;	
	reg signed [(INTEGER_WIDTH-1):0] TauInCon_IN;	
	reg signed [(TREF_WIDTH-1):0] Refractory_IN;		
	reg signed [(INTEGER_WIDTH-1):0] ResetVoltage_IN;	
	reg signed [(DATA_WIDTH-1):0] Threshold_IN;

	//AER Outputs
	wire [(BT_WIDTH-1):0] ExternalBTOut;
	wire [(NEURON_WIDTH-1):0] ExternalNIDOut;

	//Control Outputs 
	wire InitializationComplete;
	wire WChipEnable;
	wire ThetaChipEnable;

	//Off-Chip RAM I/O
	wire [(WRAM_ADDR_WIDTH-1):0] WRAMAddress;
	wire [(WRAM_WORD_WIDTH-1):0] WeightData;
	wire [(TRAM_ADDR_WIDTH-1):0] ThetaAddress;
	wire [(TRAM_WORD_WIDTH-1):0] ThetaData;

	//On-Chip RAM I/O 
	wire [(2**NEURON_WIDTH_PHYSICAL -1):0] SPNR_CE;
	wire [(2**NEURON_WIDTH_PHYSICAL -1):0] SPNR_WE;
	wire [(SPNR_ADDR_WIDTH)*(2**NEURON_WIDTH_PHYSICAL) - 1:0] SPNR_IA;
	wire [(SPNR_WORD_WIDTH)*(2**NEURON_WIDTH_PHYSICAL) - 1:0] SPNR_ID;
	wire [(SPNR_WORD_WIDTH)*(2**NEURON_WIDTH_PHYSICAL) - 1:0] SPNR_OD;

	
	//Input FIFO
	wire InputReset;
	wire InputQueueEnable;
	wire InputEnqueue;
	wire InputDequeue;
	wire [(BT_WIDTH-1):0] InFIFOBTIn;
	wire [(NEURON_WIDTH-1):0] InFIFONIDIn;

	wire [(BT_WIDTH-1):0] InFIFOBTOut;
	wire [(NEURON_WIDTH-1):0] InFIFONIDOut;
	wire [(BT_WIDTH-1):0] InputBT_Head;
	wire IsInputQueueEmpty;
	wire IsInputQueueFull;

	//Aux FIFO
	wire AuxReset;
	wire AuxQueueEnable;
	wire AuxEnqueue;
	wire AuxDequeue;
	wire [(BT_WIDTH-1):0] AuxFIFOBTIn;
	wire [(NEURON_WIDTH-1):0] AuxFIFONIDIn;

	wire [(BT_WIDTH-1):0] AuxFIFOBTOut;
	wire [(NEURON_WIDTH-1):0] AuxFIFONIDOut;
	wire [(BT_WIDTH-1):0] AuxBT_Head;
	wire IsAuxQueueEmpty;
	wire IsAuxQueueFull;

	//Out FIFO
	wire OutReset;
	wire OutQueueEnable;
	wire OutEnqueue;
	wire OutDequeue;
	wire [(BT_WIDTH-1):0] OutFIFOBTIn;
	wire [(NEURON_WIDTH-1):0] OutFIFONIDIn;

	wire [(BT_WIDTH-1):0] OutFIFOBTOut;
	wire [(NEURON_WIDTH-1):0] OutFIFONIDOut;
	wire [(BT_WIDTH-1):0] OutBT_Head;
	wire IsOutQueueEmpty;
	wire IsOutQueueFull;



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





	//State Monitor
	localparam Monitor = 174;	//Change this
	localparam MonitorIn = (Monitor+400);
	localparam ExPhysical = Monitor%(2**NEURON_WIDTH_PHYSICAL);
	localparam ExRow = Monitor>>(NEURON_WIDTH_PHYSICAL);
	localparam InPhysical = MonitorIn%(2**NEURON_WIDTH_PHYSICAL);
	localparam InRow = MonitorIn>>(NEURON_WIDTH_PHYSICAL);

	
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
		WEIGHT RAM 	
	***************************************************************/
	SinglePortOffChipRAM #(WRAM_WORD_WIDTH, WRAM_ADDR_WIDTH, WRAM_NUM_ROWS, WRAM_NUM_COLUMNS, WEIGHTFILE) WeightRAM
	(
		//Controls Signals
		.Clock(Clock),	
		.Reset(InternalRouteReset),
		.ChipEnable(WChipEnable),
		.WriteEnable(1'b0),

		//Inputs from Router		
		.InputData({WRAM_WORD_WIDTH{1'b0}}),
		.InputAddress(WRAMAddress),

		//Outputs to Router 
		.OutputData(WeightData)

	);

	
	
	/***************************************************************
		THETA RAM 	
	***************************************************************/
	
	SinglePortOffChipRAM #(TRAM_WORD_WIDTH, TRAM_ADDR_WIDTH, TRAM_NUM_ROWS, TRAM_NUM_COLUMNS, THETAFILE) ThetaRAM
	(
		//Controls Signals
		.Clock(Clock),	
		.Reset(Reset),
		.ChipEnable(ThetaChipEnable),			
		.WriteEnable(1'b0),			

		//Inputs from Router		
		.InputData({TRAM_WORD_WIDTH{1'b0}}),		
		.InputAddress(ThetaAddress),	

		//Outputs to Router 
		.OutputData(ThetaData)		

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

	/***************************************************************
			INPUT FIFO
	***************************************************************/
	InputFIFO #(BT_WIDTH, NEURON_WIDTH_LOGICAL, NEURON_WIDTH, FIFO_WIDTH) InFIFO
	(
		//Control Signals
		.Clock(Clock),
		.Reset(InputReset),
		.QueueEnable(InputQueueEnable),
		.Dequeue(InputDequeue),
		.Enqueue(InputEnqueue),

		//ExternalInputs
		.BTIn(InFIFOBTIn),	
		.NIDIn(InFIFONIDIn),
		
		//To Router via IRIS Selector
		.BTOut(InFIFOBTOut),
		.NIDOut(InFIFONIDOut),

		//Control Outputs
		.BT_Head(InputBT_Head),
		.IsQueueEmpty(IsInputQueueEmpty),
		.IsQueueFull(IsInputQueueFull)

	);

	/***************************************************************
			AUXILIARY FIFO
	***************************************************************/
	InputFIFO #(BT_WIDTH, NEURON_WIDTH_LOGICAL, NEURON_WIDTH, FIFO_WIDTH) AuxFIFO
	(
		//Control Signals
		.Clock(Clock),
		.Reset(AuxReset),
		.QueueEnable(AuxQueueEnable),
		.Dequeue(AuxDequeue),

		//From Internal Router
		.Enqueue(AuxEnqueue),

		//Internal ROUTER iNPUTS
		.BTIn(AuxFIFOBTIn),	
		.NIDIn(AuxFIFONIDIn),

		//To Router via IRIS Selector
		.BTOut(AuxFIFOBTOut),
		.NIDOut(AuxFIFONIDOut),

		//Control Inputs
		.BT_Head(AuxBT_Head),
		.IsQueueEmpty(IsAuxQueueEmpty),
		.IsQueueFull(IsAuxQueueFull)

	);

	/***************************************************************
			OUTPUT FIFO
	***************************************************************/
	InputFIFO #(BT_WIDTH, NEURON_WIDTH_LOGICAL, NEURON_WIDTH, FIFO_WIDTH) OutFIFO
	(
		//Control Signals
		.Clock(Clock),
		.Reset(OutReset),
		.QueueEnable(OutQueueEnable),
		.Dequeue(OutDequeue),

		//From Internal Router
		.Enqueue(OutEnqueue),

		//Internal ROUTER Inputs
		.BTIn(OutFIFOBTIn),	
		.NIDIn(OutFIFONIDIn),

		//To External 
		.BTOut(OutFIFOBTOut),
		.NIDOut(OutFIFONIDOut),

		//Control Inputs
		.BT_Head(OutBT_Head),
		.IsQueueEmpty(IsOutQueueEmpty),
		.IsQueueFull(IsOutQueueFull)

	);






endmodule
