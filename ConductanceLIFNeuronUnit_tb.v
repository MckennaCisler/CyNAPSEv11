/*
-----------------------------------------------------
| Created on: 12.17.2019		            							
| Author: Mckenna Cisler
| Based heavily off existing code in this repository			    
|                                                   
| Department of Engineering
| Brown University                         
-----------------------------------------------------
*/

`timescale 1ns/1ns
module ConductanceLIFNeuronUnit_tb();

    // see below for formats
    localparam WTSUM_FILE = "test_data/CLIFNU_tb_wtSums.csv";
    localparam OUTFILE = "CLIFNU_tb_out.csv";
    reg NeuronType = 0; // 0 = excitatory, 1 = inhibitory

    //Global Timer resolution and limits
	localparam DELTAT_WIDTH = 4;				//Resolution upto 0.1 ms can be supported 

	//Data precision 
	localparam INTEGER_WIDTH = 32;				//All Integer localparams should lie between +/- 2048
	localparam DATA_WIDTH_FRAC = 32;			//Selected fractional precision for all status data
	localparam DATA_WIDTH = INTEGER_WIDTH + DATA_WIDTH_FRAC;
	localparam TREF_WIDTH = 5;					//Refractory periods should lie between +/- 16 (integer)
	localparam EXTEND_WIDTH = (TREF_WIDTH+3)*2;	//For Refractory Value Arithmetic

    //Global Inputs
	reg  [(DELTAT_WIDTH-1):0] DeltaT = 4'b1000;	//DeltaT = 0.5ms  

    //Control Inputs
	reg  Clock;
	reg  Reset;
    reg  UpdateEnable;
	reg  Initialize; // unused

    //Neuron-specific characteristics	
	reg signed [(INTEGER_WIDTH-1):0] RestVoltage_EX = {-32'd65}; 	
	reg signed [(INTEGER_WIDTH-1):0] Taumembrane_EX = {32'd100}; // will be overridden 	
	reg signed [(INTEGER_WIDTH-1):0] ExReversal_EX = {32'd0};	
	reg signed [(INTEGER_WIDTH-1):0] InReversal_EX = {-32'd100}; 	
	reg signed [(INTEGER_WIDTH-1):0] TauExCon_EX = {32'd1};	// will be overridden
	reg signed [(INTEGER_WIDTH-1):0] TauInCon_EX = {32'd2};	// will be overridden
	reg signed [(TREF_WIDTH-1):0] Refractory_EX = {5'd5};		
	reg signed [(INTEGER_WIDTH-1):0] ResetVoltage_EX = {-32'd65};	
	reg signed [(DATA_WIDTH-1):0] Threshold_EX = {-32'd52,32'd0};

	reg signed [(INTEGER_WIDTH-1):0] RestVoltage_IN = {-32'd60}; 	
	reg signed [(INTEGER_WIDTH-1):0] Taumembrane_IN = {32'd10}; // will be overridden	
	reg signed [(INTEGER_WIDTH-1):0] ExReversal_IN = {32'd0};	
	reg signed [(INTEGER_WIDTH-1):0] InReversal_IN = {-32'd85}; 	
	reg signed [(INTEGER_WIDTH-1):0] TauExCon_IN = {32'd1};	// will be overridden
	reg signed [(INTEGER_WIDTH-1):0] TauInCon_IN = {32'd2};	// will be overridden
	reg signed [(TREF_WIDTH-1):0] Refractory_IN = {5'd2};		
	reg signed [(INTEGER_WIDTH-1):0] ResetVoltage_IN = {-32'd45};	
	reg signed [(DATA_WIDTH-1):0] Threshold_IN = {-32'd40, 32'd0};

    //Status register initialization values
	reg signed [(DATA_WIDTH-1):0] Vmem_Initial_EX = {-32'd105, 32'd0};
	reg signed [(DATA_WIDTH-1):0] gex_Initial_EX = {64'd0};
	reg signed [(DATA_WIDTH-1):0] gin_Initial_EX = {64'd0};
	
	reg signed [(DATA_WIDTH-1):0] Vmem_Initial_IN = {-32'd100, 32'd0};
	reg signed [(DATA_WIDTH-1):0] gex_Initial_IN = {64'd0};
	reg signed [(DATA_WIDTH-1):0] gin_Initial_IN = {64'd0};

    // Neuron status variables; normally stored in NeuronRAMs
    reg  signed [(DATA_WIDTH-1):0] Threshold;
    initial Threshold = (NeuronType == 0) ? Threshold_EX : Threshold_IN;
    // Output registers for Physical Neurons  
    reg  signed [(DATA_WIDTH-1):0] Vmem;
    reg  signed [(DATA_WIDTH-1):0] gex;
    reg  signed [(DATA_WIDTH-1):0] gin;
    reg  [(TREF_WIDTH+3-1):0] RefVal;
    reg  signed [(DATA_WIDTH-1):0] ExWeightSum; 
    reg  signed [(DATA_WIDTH-1):0] InWeightSum;
    // Output Registers for Physical Neurons
    wire  signed [(DATA_WIDTH-1):0] VmemOut;
    wire  signed [(DATA_WIDTH-1):0] gexOut;
    wire  signed [(DATA_WIDTH-1):0] ginOut;
    wire  [(TREF_WIDTH+3-1):0] RefValOut;
    // Output spike buffer
    reg  SpikeBuffer;
    wire  SpikeBufferOut;

    // Neuron output handling
    always @ (posedge Clock) begin
        Vmem <= VmemOut;
        gex <= gexOut;
        gin <= ginOut;
        RefVal <= RefValOut;
        SpikeBuffer <= SpikeBufferOut;
    end

    // Neuron unit
    ConductanceLIFNeuronUnit #(INTEGER_WIDTH, DATA_WIDTH_FRAC, DATA_WIDTH, DELTAT_WIDTH, TREF_WIDTH, EXTEND_WIDTH) CLIF
    (
        .Clock(Clock),
        .Reset(Reset),
        .UpdateEnable(UpdateEnable),
        .Initialize(Initialize),

        .NeuronType(NeuronType),

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

        .Threshold(Threshold),

        .Vmem(Vmem),
        .gex(gex),
        .gin(gin),
        .RefVal(RefVal),

        .DeltaT(DeltaT),

        .ExWeightSum(ExWeightSum),
        .InWeightSum(InWeightSum),

        .SpikeBuffer(SpikeBufferOut),
        .VmemOut(VmemOut),
        .gexOut(gexOut),
        .ginOut(ginOut),
        .RefValOut(RefValOut)
    );

    integer scanWtSum; // needed to compile; unused
    integer wtSumFile, outFile;
    integer inputSet, nextInputSet;

    // Init
    initial begin 
        inputSet = 0;
        nextInputSet = 0;

        Clock = 0;
        Reset = 0;
        UpdateEnable = 0;

        Vmem = (NeuronType == 0) ? Vmem_Initial_EX : Vmem_Initial_IN;
        gex = (NeuronType == 0) ? gex_Initial_EX : gex_Initial_IN;
        gin = (NeuronType == 0) ? gin_Initial_EX : gin_Initial_IN;
        RefVal = 0;
        ExWeightSum = 0; 
        InWeightSum = 0;

        wtSumFile = $fopen(WTSUM_FILE, "r");
        outFile = $fopen(OUTFILE, "w");
    end
    
    // Clock
    always begin 
		#5 Clock = ~Clock;
	end

    // Simulation routine
    initial begin
        $display("Reading input weight sum pattern from %s", WTSUM_FILE);
        $display("Writing simulation data to %s", OUTFILE);

        Reset = 1;
        UpdateEnable = 0;

        #20
        Reset = 0;
        UpdateEnable = 1;
        $display("starting input set %d", inputSet);

        while (!$feof(wtSumFile)) begin
            scanWtSum = $fscanf(wtSumFile, "%d,", nextInputSet);
            if (inputSet != nextInputSet) begin
                inputSet = nextInputSet;
                // reset for the new input set
                Reset = 1;
                UpdateEnable = 0;
                #20
                Reset = 0;
                UpdateEnable = 1;
                $display("starting input set %d", inputSet);
            end

            scanWtSum = $fscanf(wtSumFile, "%d,%d,%d,%d,%d\n", 
                Taumembrane_EX, 
                TauExCon_EX, 
                TauInCon_EX, 
                ExWeightSum, 
                InWeightSum);
                
            // make sure to set for both types if need be
            Taumembrane_IN = Taumembrane_EX;
            TauExCon_IN = TauExCon_EX;
            TauInCon_IN = TauInCon_EX;

            // one clock cycle to latch internally, one to latch in the testbench
            #20;
            $fwrite(outFile, "%d,%d,%d,%d,%d,%d,%d,%d,%d,%d,%d\n", 
                inputSet, 
                Taumembrane_EX, 
                TauExCon_EX, 
                TauInCon_EX, 
                ExWeightSum, 
                InWeightSum, 
                Vmem, 
                gex, 
                gin, 
                RefVal, 
                SpikeBuffer);
        end

        $fclose(wtSumFile);
        $fclose(outFile);
        $finish;
    end
                
endmodule