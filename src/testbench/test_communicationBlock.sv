`timescale 10 ns/ 1 ns

module test_communicationBlock1();
	
	import milStd1553::*;
	
	bit rst, clk;
	
	//debug spi transmitter
	ISpi spi();
	IPushMasterDebug 		spiDebug(clk);
	DebugSpiTransmitter 	spiTrans(rst, clk, spiDebug, spi);

	//debug mil transmitter
	IMilStd mil();
	IPushMilMasterDebug 	milDebug(clk);
	DebugMilTransmitter	milTrans(rst, clk, milDebug, mil);

	//logic
	IMemory mbus();
	IRingBufferControl rcontrol[1:0]();
	
	IPush		pushToMem0();	
	IPop		popFromMem0();	
	IPop		popFromMem1();
		
	IPush		pushFromSpi();	
	IPush		pushFromMil();	
	IPop		popToSpi();
	IPush		pushToMil();	
	
	ICommunicationBlockControl communicationBlockControl();
	
	AlteraMemoryWrapper 	mem(rst, clk, mbus.memory);
	MemoryBlock			  	memBlock(rst, clk, 
											pushToMem0, pushFromMil,
											popFromMem0, popFromMem1,
											rcontrol, mbus);
	
	CommunicationBlock	cb(rst, clk, 
									spi.slave, 
									mil.device,
									pushFromSpi, pushFromMil, 
									popToSpi, pushToMil,
									communicationBlockControl.slave);
	
	//------------------ brain start ----------------------------
	
	parameter blockAddr = 8'hAB;
	
	import ServiceProtocol::*;
	
	//spi to mem
	logic spiToMemEnable;
	BusGate	spiToMemGate(	rst, clk, 
									spiToMemEnable,
									pushFromSpi,
									pushToMem0);
	//mem to mil
	BusPusher memToMilPusher(rst, clk, 
									 (rcontrol[0].memUsed != '0),
									 pushToMil,
									 popFromMem0);
	
	//mem to mil
	// direct connected
	
	//mem, stat to spi
	logic	[1:0] toSpiMuxKey;
	IPop	popFromStat();
	
	IStatusInfoControl statusInfoControl();
	assign statusInfoControl.statusWord0 = rcontrol[0].memUsed;
	assign statusInfoControl.statusWord1 = rcontrol[1].memUsed;
	
	StatusInfo	statusPopper(rst, clk,
									 popFromStat,
									 statusInfoControl);
	
	BusMux	toSpiDataMux(	rst, clk,
									toSpiMuxKey,
									popToSpi,
									popFromMem1, popFromStat);
	
	//processing of the command

	logic [4:0] conf;
	logic resetInPlan;
	
	assign {	spiToMemEnable, toSpiMuxKey, 
				communicationBlockControl.spiTransmitEnable,
				statusInfoControl.enable} = conf;
				
	always_ff @ (posedge clk) begin
		if(rst)
			resetInPlan <= 0;
		if(communicationBlockControl.cmdCode == TCC_RESET)
			resetInPlan <= 1;
	end
	
	logic debugRst;
	
	ResetGenerator		resetGen(rst, clk, 
										(resetInPlan && communicationBlockControl.cmdCode == TCC_UNKNOWN), 
										debugRst);
	
	always_comb begin
		case(communicationBlockControl.cmdCode)
			default: 			conf = 5'b01100;
			TCC_UNKNOWN:		conf = 5'b01100;
			TCC_RESET:			conf = 5'b01100;	// сброс устройства
			TCC_SEND_DATA:		conf = 5'b11100;	// отправить в Mil данные
			TCC_RECEIVE_STS:	conf = 5'b00111;	// отправить в Spi слово статуса
			TCC_RECEIVE_DATA:	conf = 5'b00010;	// отправить в Spi все данные, полученные из Mil
		endcase
	end
	
	always_comb begin
		case(communicationBlockControl.cmdCode)
			default:				communicationBlockControl.spiTransmitDataSize = '0;
			TCC_RECEIVE_STS:	communicationBlockControl.spiTransmitDataSize = 2;
			TCC_RECEIVE_DATA:	communicationBlockControl.spiTransmitDataSize = rcontrol[1].memUsed;	
		endcase
	end
	
	//------------------ brain end ----------------------------
	
	initial begin
		{rcontrol[0].open, rcontrol[0].commit, rcontrol[0].rollback} = '0;
		{rcontrol[1].open, rcontrol[1].commit, rcontrol[1].rollback} = '0;
	
		rst = 1;
	#2 rst = 0;
		//fork
			//отправить произвольные данные в Mil
			begin
				$display("TransmitOverMil Start");	
				
				milDebug.doPush(WCOMMAND,	16'hAB00);
				milDebug.doPush(WDATA,		16'hEFAB);
				milDebug.doPush(WDATA,		16'h9D4D);
				
				$display("TransmitOverMil End");	
			end
		
			//передать в spi данные для отправки в Mil
			begin
				$display("TransmitOverSpi Start");	
			
				spiDebug.doPush(16'hAB00);	//ардес AB
				spiDebug.doPush(16'h06A2); //размер 0006, команда A2
				spiDebug.doPush(16'hFFA1); 
				spiDebug.doPush(16'h0001); 
				
				spiDebug.doPush(16'h0002);
				spiDebug.doPush(16'hAB45);
				spiDebug.doPush(16'hFFA3);
				spiDebug.doPush(16'hFFA1);
				
				spiDebug.doPush(16'h57CF); //контрольная сумма
				spiDebug.doPush(16'h0);		//номер слова
				
				$display("TransmitOverSpi End");	
			end
			
			//получить через spi текущий статус
			begin
				$display("GetStatus Start");	
			
				spiDebug.doPush(16'hAB00);	//ардес AB
				spiDebug.doPush(16'h0AB0); //размер 000A, команда B0				
				spiDebug.doPush(16'h0);		//пустые данные для приема
				spiDebug.doPush(16'h0);		
				spiDebug.doPush(16'h0);		
				spiDebug.doPush(16'h0);		
				spiDebug.doPush(16'h0);		
				spiDebug.doPush(16'h0);	
				spiDebug.doPush(16'h0);		
				spiDebug.doPush(16'h0);		
				spiDebug.doPush(16'h0);		
				spiDebug.doPush(16'h0);
				spiDebug.doPush(16'hB5B0); //контрольная сумма
				spiDebug.doPush(16'h0);		//номер слова	
			
				$display("GetStatus End");		
			end
			
			//получить через spi принятые по Mil данные
			begin
				$display("ReceiveOverSpi Start");	
			
				spiDebug.doPush(16'hAB00);	//ардес AB
				spiDebug.doPush(16'h0AB2); //размер 000A, команда B2				
				spiDebug.doPush(16'h0);		//пустые данные для приема
				spiDebug.doPush(16'h0);		
				spiDebug.doPush(16'h0);		
				spiDebug.doPush(16'h0);		
				spiDebug.doPush(16'h0);		
				spiDebug.doPush(16'h0);	
				spiDebug.doPush(16'h0);		
				spiDebug.doPush(16'h0);		
				spiDebug.doPush(16'h0);		
				spiDebug.doPush(16'h0);
				spiDebug.doPush(16'hB5B2); //контрольная сумма
				spiDebug.doPush(16'h0);		//номер слова	
			
				$display("ReceiveOverSpi End");		
			end
			
			//выполнить сброс
			begin
				$display("Reset Start");	
			
				spiDebug.doPush(16'hAB00);	//ардес AB
				spiDebug.doPush(16'h00A0); //размер 0000, команда A2				
				spiDebug.doPush(16'hABA0); //контрольная сумма
				spiDebug.doPush(16'h0);		//номер слова	
			
				$display("Reset End");		
			end
			
			
		//join
	end
	
	always begin
	#1  clk =  ! clk;
	end

endmodule

module test_communicationBlock2();
	
	import milStd1553::*;
	
	bit rst, clk;
	
	//debug spi transmitter
	ISpi spi();
	IPushMasterDebug 		spiDebug(clk);
	DebugSpiTransmitter 	spiTrans(rst, clk, spiDebug, spi);

	//debug mil transmitter
	IMilStd mil();
	IPushMilMasterDebug 	milDebug(clk);
	DebugMilTransmitter	milTrans(rst, clk, milDebug, mil);

	//logic
	IMemory mbus();
	
	IRingBufferControl rcontrol[1:0]();
	IPush	push[1:0]();	
	IPop	pop[1:0]();	
	

	
	AlteraMemoryWrapper 	mem(rst, clk, mbus.memory);
	MemoryBlock			  	memBlock(rst, clk, 
											push[0], push[1],
											pop[0], pop[1],
											rcontrol, mbus);
	
	logic resetRequest;
	
	MilSpiCore	milSpiCore(	rst, clk, 
									spi, mil,
									push[0], push[1],
									pop[0], pop[1],
									rcontrol[0], rcontrol[1],
									resetRequest);
	
	
	/*
	module MilSpiCore	(	input logic rst, clk,
							ISpi spi,	IMilStd mil
							IPush.master 	pushToMem0, 	pushToMem1,
							IPop.master		popFromMem0, 	popFromMem1,
							IRingBufferControl.master rcontrol0, rcontrol1,
							output logic resetRequest);
	
	logic debugRst;
	
	ResetGenerator		resetGen(rst, clk, 
										(resetInPlan && communicationBlockControl.cmdCode == TCC_UNKNOWN), 
										debugRst);
	
	*/
	
	initial begin
	
		rst = 1;
	#2 rst = 0;
		//fork
			//отправить произвольные данные в Mil
			begin
				$display("TransmitOverMil Start");	
				
				milDebug.doPush(WCOMMAND,	16'hAB00);
				milDebug.doPush(WDATA,		16'hEFAB);
				milDebug.doPush(WDATA,		16'h9D4D);
				
				$display("TransmitOverMil End");	
			end
		
			//передать в spi данные для отправки в Mil
			begin
				$display("TransmitOverSpi Start");	
			
				spiDebug.doPush(16'hAB00);	//ардес AB
				spiDebug.doPush(16'h06A2); //размер 0006, команда A2
				spiDebug.doPush(16'hFFA1); 
				spiDebug.doPush(16'h0001); 
				
				spiDebug.doPush(16'h0002);
				spiDebug.doPush(16'hAB45);
				spiDebug.doPush(16'hFFA3);
				spiDebug.doPush(16'hFFA1);
				
				spiDebug.doPush(16'h57CF); //контрольная сумма
				spiDebug.doPush(16'h0);		//номер слова
				
				$display("TransmitOverSpi End");	
			end
			
			//получить через spi текущий статус
			begin
				$display("GetStatus Start");	
			
				spiDebug.doPush(16'hAB00);	//ардес AB
				spiDebug.doPush(16'h0AB0); //размер 000A, команда B0				
				spiDebug.doPush(16'h0);		//пустые данные для приема
				spiDebug.doPush(16'h0);		
				spiDebug.doPush(16'h0);		
				spiDebug.doPush(16'h0);		
				spiDebug.doPush(16'h0);		
				spiDebug.doPush(16'h0);	
				spiDebug.doPush(16'h0);		
				spiDebug.doPush(16'h0);		
				spiDebug.doPush(16'h0);		
				spiDebug.doPush(16'h0);
				spiDebug.doPush(16'hB5B0); //контрольная сумма
				spiDebug.doPush(16'h0);		//номер слова	
			
				$display("GetStatus End");		
			end
			
			//получить через spi принятые по Mil данные
			begin
				$display("ReceiveOverSpi Start");	
			
				spiDebug.doPush(16'hAB00);	//ардес AB
				spiDebug.doPush(16'h0AB2); //размер 000A, команда B2				
				spiDebug.doPush(16'h0);		//пустые данные для приема
				spiDebug.doPush(16'h0);		
				spiDebug.doPush(16'h0);		
				spiDebug.doPush(16'h0);		
				spiDebug.doPush(16'h0);		
				spiDebug.doPush(16'h0);	
				spiDebug.doPush(16'h0);		
				spiDebug.doPush(16'h0);		
				spiDebug.doPush(16'h0);		
				spiDebug.doPush(16'h0);
				spiDebug.doPush(16'hB5B2); //контрольная сумма
				spiDebug.doPush(16'h0);		//номер слова	
			
				$display("ReceiveOverSpi End");		
			end
			
			//выполнить сброс (левый адрес, команда д.б. проигнорирована)
			begin
				$display("Reset Start");	
			
				spiDebug.doPush(16'h0100);	//ардес 01
				spiDebug.doPush(16'h00A0); //размер 0000, команда A2				
				spiDebug.doPush(16'h01A0); //контрольная сумма
				spiDebug.doPush(16'h0);		//номер слова	
			
				$display("Reset End");		
			end
			
			//выполнить сброс
			begin
				$display("Reset Start");	
			
				spiDebug.doPush(16'hAB00);	//ардес AB
				spiDebug.doPush(16'h00A0); //размер 0000, команда A2				
				spiDebug.doPush(16'hABA0); //контрольная сумма
				spiDebug.doPush(16'h0);		//номер слова	
			
				$display("Reset End");		
			end
			
			
		//join
	end
	
	always begin
	#1  clk =  ! clk;
	end

endmodule


