module Receiver(clk, rst, start, rx, data_out, done);

	input clk, rst, start, rx;
	output reg [8:0] data_out;
	output reg done;
	
	//Para o baund rate de 9600 e o clk é de 50MHZ
	parameter baundRateSerial = 13'd5208; //50.000.000/9600 ~= 5208
	//Precisamos pegar o meio do sinal para evitar atraso então pegamos
	parameter sleeptime = 13'd2604; // 5208/2 = 2604
	
	///////////////////////////Variaveis de controle//////////////////////////////////////
	reg [8:0] bufferRX = 9'b0; //buffer para guardar os dados lidos
	reg [12:0] counterBR = 13'b0; //contador de baund rate
	reg [3:0] Nbits = 4'd8; //contador de bits recebidos
	reg [3:0] startBit = 4'b1111; //Permissão de leitura, leitor de borda de descida do start bit
	
	
	//Logica de mudança de estado
	parameter  idle = 2'b00, sleep = 2'b01 , read = 2'b10;
	reg [1:0] state = idle;
	
	
	/////////////////////////////FSM - Receptor//////////////////////////////////////////////
	
	always @(posedge clk or negedge rst) begin
		if(!rst) begin // se o reset for precionado reseta os contadores e vai para o estado idle
			counterBR = 13'b0;
			bufferRX = 9'b0;
			Nbits = 4'd8;
			startBit = 4'b1111;
			state <= idle;
		end
		else begin
			if(state == idle) begin //estando no estado idle
				if(start) begin
					done = 0; // sinaliza que esta lendo
					startBit[3:0] = {1'b0,startBit[3:1]};//verificando bits 0
					if(startBit == 4'b0000) begin //start_bir verificado
						state <= sleep;// vai para o estado de descanço
					end
				end
			end
			else if(state == sleep) begin // estando no estado sleep
				if(counterBR != sleeptime) begin //se o contador de baund rate não tiver atingido o valor de espera definido
					counterBR = counterBR + 1'b1; // itera o contador
				end
				else begin // se sim quer dizer que vc esta mais ou menso no meio do sinal
					counterBR = 13'b0;
					state <= read; // vai para o estado de leitura
				end
			end
			else if(state == read) begin // estando no estado de leitura
				if(counterBR !=  baundRateSerial) begin // se o valor do contador não for igual ao do baund rate
					counterBR = counterBR + 1'b1; // incrementa
				end
				else begin // se for ele é zerado
					counterBR = 13'b0;
					bufferRX[8:0] = {bufferRX[7:0],rx}; // e o bit é recebido e atualizado no buffer
					Nbits = Nbits - 1'b1; //mudamos o valor do contador de bits recebidos em 1
				end
				
				if(Nbits == 4'd0) begin // quando todos os bits forem recebidos
						if(bufferRX[0]) begin //checamos se o bit menos significativo que deveria ser o stop bit é 1
							data_out = bufferRX; // sendo transferimos o dado do buffer para a saida
							done = 1'b1; // e sinalizamos o termino da leitura
						end // depois disso zeramos todos os contadores e colocamos o leitor de borda em alto
						counterBR = 13'b0;
						bufferRX = 9'b0;
						Nbits = 4'd8;
						startBit = 4'b1111;
						state <= idle; // voltamos para o estado idle
				end
			end
			else begin // caso nenhuma das condições seja satisfeita resetamos tudo e ficamos no idle
				counterBR = 13'b0;
				bufferRX = 9'b0;
				Nbits = 4'd8;
				startBit = 4'b1111;
				state <= idle;
			end
		end
		
	
	end

endmodule