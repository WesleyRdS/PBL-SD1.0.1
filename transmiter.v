module transmiter(Tx, Data_in, clk, rst, start, done);
		input clk, rst, start;
		input [7:0] Data_in;
		output reg Tx, done;
		
		//Para o baund rate de 9600 e o clk é de 50MHZ
		parameter baundRateSerial = 13'd5208; //50.000.000/9600 ~= 5208
		
		////////////////////////Variaveis de controle///////////////////////////////////////////////
		
		reg [7:0] bufferTX = 8'b0; //buffer para guardar os dados lidos
		reg [12:0] counterBR = 13'b0; //contador de baund rate
		reg [3:0] Nbits = 4'd8; //contador de bits recebidos
		reg enable = 1'b0; //Permissão de leitura
		
		/////////////////////////////////////Logica de envio///////////////////////////////////////
		always @(posedge clk, negedge rst) begin
			if(!rst) begin // se o reset for clicado zera todos os contadores
				counterBR = 13'b0;
				Nbits = 4'd8;
				done = 1'b1; // variavel que indica que a transmissão foi terminada quando esta em nivel logico alto
			end
			else if(start) begin //inicio da transmissão definido
				Tx = 1'b0; //envia o start bit
				done = 1'b0; //indica que a transmissão esta em andamento
				enable = 1'b1; // ativa permissão de transmissão
				bufferTX <= Data_in; // passa o dado a ser transmitido para o buffer
			end
			else if(enable) begin // permissão de transmissão ativa
				if(counterBR < baundRateSerial) begin //se o contador de baund rate não tiver atingido o valor de baund rate definido
					counterBR = counterBR + 1'b1; // itera o contador
				end
				else begin // quando atingir
					counterBR = 8'b0; // zera o contador
					Nbits = Nbits - 1'b1; //indica que esta transmitindo um bit
					Tx = bufferTX[0]; //transmite o bit menos significativo
					bufferTX[7:0] = {1'b1,bufferTX[7:1]}; //retira o dado transmitido do buffer
					
					if(Nbits == 0) begin // se todos os bits foram enviados reseta os contadores
						Nbits = 8'd8;
						counterBR = 8'b0;
						enable = 1'b0; //desativa a permição de transmissão
						done = 1'b1; //indica fim da leitura
					end
				end
			
			end
			else begin // se nenhuma das condições foram compridas deixa todos os controles resetados
				counterBR = 13'b0;
				Nbits = 4'd8;
				done = 1'b1;
			end
		end
		
		
		
		
	
endmodule