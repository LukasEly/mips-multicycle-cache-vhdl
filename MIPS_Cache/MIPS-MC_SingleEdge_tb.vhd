-------------------------------------------------------------------------
--
--  TESTBENCH DO PROCESSADOR MIPS_S (LITTLE ENDIAN) 13/10/2004
--
-- Observe-se que o processador come�a sendo ressetado por este testbench
-- (rstCPU <= '1') no in�cio da simula��o, sendo ativado  -- (rstCPU <= '0')
-- somente depois do fim da leitura do arquiv contendo o c�digo objeto do
-- programa e executar, bem como seus dados iniciais.
--
-- Este testbench emprega duas mem�rias, implicando uma organiza��o HARVARD
-- para o processador
--
-- Mudan�as:
--	16/05/2012 (Ney Calazans)
--		- Bug corrigido no processo de preenchimento da mem�ria durante o reset.
--		Anteriormente, o processo fazia o processador produzir habilita��es no 
--      sinal ce para a mem�ria o que acabava preenchendo a mem�ria de dados 
--      com lixo ao mesmo tempo. Para resolver isto, a gera��o do sinal de 
--      controle Dce da mem�ria de dados foi mudada de 
--			--	ce='1' or go_d='1'	 
--          para 
--			-- (ce='1' and rstCPU/='1') or go_d='1'
--		- Al�m disto, havia um problema com a opera��o de escrita da mem�ria de 
--      dados nas implementa��es monociclo do MIPS: quando m�ltiplas instru��es
--      SW eram programadas uma ap�s  outra, a escrita ocorria  em dois conjuntos
--		de posi��es da mem�ria ao mesmo tempo ap�s o primeiro SW da s�rie.
--      Para resolver isto o sinal data foi removido da lista de sensitividade 
--      do processo de escrita na mem�ria.
--	10/10/2015 (Ney Calazans)
--		- Sinal bw da mem�ria setado para '1', uma vez que a CPU
--		n�o gera mais ele.
--	28/10/2016 (Ney Calazans)
--		- Defini��es regX mudadas para wiresX, para melhora a readabilidade do
--         c�digo.
--	02/06/2017 (Ney Calazans) - conserto de bugs
--		- tmp_address mudado para int_address na defini��o da mem�ria
--		- na defini��o dos processo de escrita/leitura da mem�ria
--		  CONV_INTEGER(low_address+3)<=MEMORY_SIZE 
--        foi mudado para
--		  CONV_INTEGER(low_address)<=MEMORY_SIZE-3
-- 		Isto evita um erro que congelava a simula��o quando a
--		   ALU continnha um n�mero grande (>65533) na sua sa�da 
--		   imediatamente antes de uma instru��o LW o SW.
-------------------------------------------------------------------------

library IEEE;
use IEEE.Std_Logic_1164.all;
use std.textio.all;
package aux_functions is  

	subtype wires32  is std_logic_vector(31 downto 0);
	subtype wires16  is std_logic_vector(15 downto 0);
	subtype wires8   is std_logic_vector( 7 downto 0);
	subtype wires4   is std_logic_vector( 3 downto 0);

   -- defini��o do tipo 'memory', que ser� utilizado para as mem�rias de dados/instru��es
   constant MEMORY_SIZE : integer := 2048;     
   type memory is array (0 to MEMORY_SIZE) of wires8;

   constant TAM_LINHA : integer := 200;
   
   function CONV_VECTOR( letra : string(1 to TAM_LINHA);  pos: integer ) return std_logic_vector;
	
	procedure readFileLine(file in_file: TEXT; outStrLine: out string);
   
end aux_functions;

package body aux_functions is

  --
  -- converte um caracter de uma dada linha em um std_logic_vector
  --
  function CONV_VECTOR( letra:string(1 to TAM_LINHA);  pos: integer ) return std_logic_vector is         
     variable bin: wires4;
   begin
      case (letra(pos)) is  
              when '0' => bin := "0000";
              when '1' => bin := "0001";
              when '2' => bin := "0010";
              when '3' => bin := "0011";
              when '4' => bin := "0100";
              when '5' => bin := "0101";
              when '6' => bin := "0110";
              when '7' => bin := "0111";
              when '8' => bin := "1000";
              when '9' => bin := "1001";
              when 'A' | 'a' => bin := "1010";
              when 'B' | 'b' => bin := "1011";
              when 'C' | 'c' => bin := "1100";
              when 'D' | 'd' => bin := "1101";
              when 'E' | 'e' => bin := "1110";
              when 'F' | 'f' => bin := "1111";
              when others =>  bin := "0000";  
      end case;
     return bin;
  end CONV_VECTOR;

  procedure readFileLine(file in_file: TEXT; 
					      outStrLine: out string) is
		
		variable localLine: line;
		variable localChar:  character;
		variable isString: 	boolean;
			
	begin
				
		 readline(in_file, localLine);

		 for i in outStrLine'range loop
			 outStrLine(i) := ' ';
		 end loop;   

		 for i in outStrLine'range loop
			read(localLine, localChar, isString);
			outStrLine(i) := localChar;
			if not isString then -- encontrou o fim da linha
				exit;
			end if;   
		 end loop; 
						 
	end readFileLine;
	
end aux_functions;    

--=======================================================================
--                  Delay para a memória RAM
--=======================================================================

library ieee;
use IEEE.std_logic_1164.all;
use IEEE.std_logic_unsigned.all;  

entity Delay is
    port(
        ck, rst, ce_n: in std_logic;
        halt: out std_logic;
        counter: out std_logic_vector(2 downto 0)
    );
end Delay;
architecture Delay of Delay is
    signal counter_s: std_logic_vector(2 downto 0);
    signal halt_t: std_logic;
begin

    process(rst, ck)
    begin
        if rst = '1' then
            counter_s <= (others => '0');
            halt_t <= '0';
        elsif falling_edge(ck) then
            if ce_n = '0' or halt_t = '1' then
                if counter_s = "111" then
                    halt_t <= '0';
                    counter_s <= "000";
                else
                    halt_t <= '1';
                    counter_s <= counter_s + '1';                
                end if;
            end if;
        end if;
    end process;

    counter <= counter_s;
    halt <= halt_t;
     
end Delay;

--------------------------------------------------------------------------
-- M�dulo que implementa um modelo comportamental de uma RAM
-- com interface ass�ncrona (sem clock)
--------------------------------------------------------------------------
library IEEE;
use ieee.std_logic_1164.all;
use ieee.STD_LOGIC_UNSIGNED.all;
use std.textio.all;
use work.aux_functions.all;

entity RAM_mem is
      generic(  START_ADDRESS: wires32 := (others=>'0')  );
      port(ce_n, we_n, oe_n, bw: in std_logic;    address: in wires32;   data: inout wires32);
end RAM_mem;

architecture RAM_mem of RAM_mem is 
   signal RAM : memory;
   signal tmp_address: wires32;
   alias  low_address: wires16 is tmp_address(15 downto 0);    --  baixa para 16 bits, devido ao CONV_INTEGER --
begin     

    tmp_address <= address - START_ADDRESS;   --  offset do endereamento  -- 
   
   -- escrita ass�ncrona na mem�ria  -- LITTLE ENDIAN -------------------
   process(ce_n, we_n, low_address) -- Modifica��o em 16/05/2012 para uso
                                    -- processadores monociclo apenas
     begin
       if ce_n='0' and we_n='0' then
          if CONV_INTEGER(low_address)>=0 and CONV_INTEGER(low_address)<=MEMORY_SIZE-3 then
               if bw='1' then
                   RAM(CONV_INTEGER(low_address+3)) <= data(31 downto 24);
                   RAM(CONV_INTEGER(low_address+2)) <= data(23 downto 16);
                   RAM(CONV_INTEGER(low_address+1)) <= data(15 downto  8);
               end if;
               RAM(CONV_INTEGER(low_address  )) <= data( 7 downto  0); 
          end if;
         end if;   
    end process;   
    
   -- leitura da mem�ria
   process(ce_n, oe_n, low_address)
     begin
       if ce_n='0' and oe_n='0' and
          CONV_INTEGER(low_address)>=0 and CONV_INTEGER(low_address)<=MEMORY_SIZE-3 then
            data(31 downto 24) <= RAM(CONV_INTEGER(low_address+3));
            data(23 downto 16) <= RAM(CONV_INTEGER(low_address+2));
            data(15 downto  8) <= RAM(CONV_INTEGER(low_address+1));
            data( 7 downto  0) <= RAM(CONV_INTEGER(low_address  ));
        else
            data(31 downto 24) <= (others=>'Z');
            data(23 downto 16) <= (others=>'Z');
            data(15 downto  8) <= (others=>'Z');
            data( 7 downto  0) <= (others=>'Z');
        end if;
   end process;   

end RAM_mem;

--=======================================================================
--                      Memória cache
--=======================================================================

library ieee;
use IEEE.std_logic_1164.all;
use IEEE.std_logic_unsigned.all;  
use ieee.numeric_std.all;

entity Cache_mem is
    port( 
        rstCPU: std_logic;
        counter: in std_logic_vector(2 downto 0);
        ck, rst: in std_logic;
        ce_in, we_in, oe_in, bw_in: in std_logic; 
        halt_in: in std_logic;
        address_in: in std_logic_vector(31 downto 0);
        ce_out, we_out, oe_out, bw_out: out std_logic;
        halt_out: out std_logic; 
        address_out: out std_logic_vector(31 downto 0);
        data_CPU: inout std_logic_vector(31 downto 0);
        data_RAM: inout std_logic_vector(31 downto 0)
    );
end Cache_mem;
architecture Cache_mem of Cache_mem is

    -- definições da cache 
    type bloco_t is array (0 to 7) of std_logic_vector(31 downto 0); -- bloco com 8 palavras
    type cache_line is record
        tag: std_logic_vector(24 downto 0); -- tag com os 25 bits que sobraram
        bloco: bloco_t;
        bv: std_logic; -- bit de validade 
    end record;
    type cache_memory is array (0 to 3) of cache_line;

    signal line_position: integer;
    type type_state is (starting_mp, idle, write_mp, read_mp);
    signal halt_reg: std_logic; -- halt_reg = (fio que simula e controla o halt que vem da RAM e passa para o processador nos casos necessários)
    signal EA: type_state; -- estado atual

    signal r_data_RAM, r_data_CPU: std_logic_vector(31 downto 0) := (others => 'Z' );
    signal s_data_CPU: std_logic_vector(31 downto 0) := (others => 'Z' );
    signal cache: cache_memory; -- memória cache

    signal address_reg: std_logic_vector(31 downto 0);
    signal counter_data: std_logic_vector(2 downto 0);

begin

    -- controle da maquina de estados
    process(ck, rst)
    begin
        if rst = '1' then
            EA <= starting_mp;
        elsif falling_edge(ck) then
            case EA is
                when starting_mp => -- estado de inicialização da memória
                    if rstCPU = '0' then
                        EA <= idle;
                    end if;
                when idle =>
                    if ce_in = '0' and oe_in = '0' and 
                    (cache(line_position).tag = address_in(31 downto 7) nand cache(line_position).bv = '1') then -- caso de hit
                        EA <= read_mp;
                    elsif ce_in = '0' and we_in = '0' then -- caso de write through (qualquer escrita)
                        EA <= write_mp;
                    else -- caso de miss
                        EA <= idle;        
                    end if;

                when read_mp =>
                    if counter_data = "111" and counter = "111" then -- quando todos os endereços são passados para a memória
                        EA <= idle;
                    end if;
                    
                when write_mp => -- estado de write through
                    if counter = "111" then
                        EA <= idle;
                    end if;

                when others =>
                    EA <= idle;

            end case;
        end if;
    end process;
    
    process(ck, rst)
    begin
        if rst = '1' then
            -- inicialização da cache
            r_data_RAM <= (others => 'Z');
            r_data_CPU <= (others => 'Z');
            cache(0).bv <= '0'; -- zera todos bits de validade
            cache(0).tag <= (others => 'Z');
            cache(0).bloco(0) <= (others => 'Z');
            cache(0).bloco(1) <= (others => 'Z');
            cache(0).bloco(2) <= (others => 'Z');
            cache(0).bloco(3) <= (others => 'Z');
            cache(0).bloco(4) <= (others => 'Z');
            cache(0).bloco(5) <= (others => 'Z');
            cache(0).bloco(6) <= (others => 'Z');
            cache(0).bloco(7) <= (others => 'Z');
            cache(1).bv <= '0'; 
            cache(1).tag <= (others => 'Z');
            cache(1).bloco(0) <= (others => 'Z');
            cache(1).bloco(1) <= (others => 'Z');
            cache(1).bloco(2) <= (others => 'Z');
            cache(1).bloco(3) <= (others => 'Z');
            cache(1).bloco(4) <= (others => 'Z');
            cache(1).bloco(5) <= (others => 'Z');
            cache(1).bloco(6) <= (others => 'Z');
            cache(1).bloco(7) <= (others => 'Z');
            cache(2).bv <= '0'; 
            cache(2).tag <= (others => 'Z');
            cache(2).bloco(0) <= (others => 'Z');
            cache(2).bloco(1) <= (others => 'Z');
            cache(2).bloco(2) <= (others => 'Z');
            cache(2).bloco(3) <= (others => 'Z');
            cache(2).bloco(4) <= (others => 'Z');
            cache(2).bloco(5) <= (others => 'Z');
            cache(2).bloco(6) <= (others => 'Z');
            cache(2).bloco(7) <= (others => 'Z');
            cache(3).bv <= '0';
            cache(3).tag <= (others => 'Z');
            cache(3).bloco(0) <= (others => 'Z');
            cache(3).bloco(1) <= (others => 'Z');
            cache(3).bloco(2) <= (others => 'Z');
            cache(3).bloco(3) <= (others => 'Z');
            cache(3).bloco(4) <= (others => 'Z');
            cache(3).bloco(5) <= (others => 'Z');
            cache(3).bloco(6) <= (others => 'Z');
            cache(3).bloco(7) <= (others => 'Z');
            -- inicialização do resto dos sinais
            address_reg <= (others => 'Z');
            halt_reg <= '0';
            counter_data <= (others => '0');
        elsif falling_edge(ck) then

            if EA = idle then -- estado inicial esperando alguma ordem do processador

                if (ce_in = '0' and we_in = '0') or (ce_in = '0' and oe_in = '0') then
                    if cache(line_position).tag = address_in(31 downto 7) and cache(line_position).bv = '1' then
                        if oe_in = '0' then
                            r_data_CPU <= cache(line_position).bloco(to_integer(unsigned(address_in(4 downto 2)))); -- hit de leitura
                        elsif we_in = '0' then
                            cache(line_position).bloco(to_integer(unsigned(address_in(4 downto 2)))) <= data_CPU;
                        end if;
                    else 
                        if oe_in = '0' then -- miss de leitura
                            halt_reg <= '1';
                            address_reg <= address_in - to_integer(unsigned(address_in(4 downto 2)));
                        end if;
                    end if;
                    if we_in = '0' then 
                        halt_reg <= '1'; -- Manda o processador esperar, porque a cache está ocupada esperando a RAM
                    end if;
                else 
                    r_data_RAM  <= (others => 'Z');
                    r_data_CPU  <= (others => 'Z');
                    address_reg <= (others => 'Z');
                end if;

            elsif EA = read_mp then   -- caso de ler da memória RAM por conta do miss

                if counter_data = "111" then -- caso final
                    if counter = "111" then -- aguarda a RAM terminar
                        halt_reg <= '0';
                        cache(line_position).bv <= '1';
                        cache(line_position).tag <= address_in(31 downto 7);
                        address_reg <= (others => 'Z');
                        counter_data <= (others => '0');
                        r_data_CPU <= cache(line_position).bloco(to_integer(unsigned(address_in(4 downto 2))));
                    end if ; 

                elsif counter = "111" then -- qualquer outro caso
                    cache(line_position).bloco(to_integer(unsigned(counter_data))) <= data_RAM;
                    counter_data <= counter_data + '1';
                    address_reg <= address_reg + "100";
                    
                end if;

            elsif EA = write_mp then -- estado de write through para a RAM
                if counter = "111" then -- caso a memória RAM não esteja ocupada -- fazendo write through
                    address_reg <= (others => 'Z');
                    halt_reg <= '0';
                else                   -- caso a memória RAM esteja ocupada -- fazendo write through
                    r_data_RAM <= data_CPU;
                    address_reg <= address_in;
                end if;
            end if;
        end if;
    end process;
    
    process(ce_in, oe_in, we_in, data_CPU)
    begin -- process que recebe os dados para inicialização da memória
        if EA = starting_mp then
            s_data_CPU <= data_CPU;
        else
            s_data_CPU <= (others => 'Z');
        end if;
    end process;

    -- address.linha
    line_position <= to_integer(unsigned(address_in(6 downto 5))); -- posição da linha no address

    -- funcionamento do halt da cache:
    -- cache manda o processador parar quando ela precisa fazer uma ação que envolve a memória RAM e a memória RAM está ocupada
    -- Situações em que o halt ativa:
    -- * Memória RAM ocupada e cache precisa fazer write through
    -- * Memória RAM ocupada e cache da miss para leitura

    halt_out <= halt_reg; -- Só faz o delay ser aplicado no processador quando a cache da miss na leitura
                          -- ou quando tenta fazer write through e a MP ainda está com o halt ativo

    ce_out <= ce_in when (EA = starting_mp) or (EA = read_mp and halt_reg = '1') or (EA = write_mp) else '1';
    we_out <= we_in when (EA = starting_mp) or (EA = write_mp) else '1';
    oe_out <= oe_in when (EA = starting_mp) or EA = read_mp else '1';
    bw_out <= bw_in when (EA = starting_mp) or (EA = write_mp) else '1';

    address_out <= address_in when (EA = starting_mp) else address_reg;

    data_RAM <= s_data_CPU when (EA = starting_mp) else r_data_RAM;
    data_CPU <= r_data_CPU;
  
end Cache_mem;

-------------------------------------------------------------------------
--  Testebench para simular a CPU do processador
-------------------------------------------------------------------------
library ieee;
use IEEE.std_logic_1164.all;
use IEEE.std_logic_unsigned.all;          
use STD.TEXTIO.all;
use work.aux_functions.all;

entity CPU_tb is
end CPU_tb;

architecture cpu_tb of cpu_tb is

    signal halt: std_logic;
    signal ce_out, we_out, oe_out, bw_out, halt_out: std_logic;
    signal address_out: std_logic_vector(31 downto 0);
    signal data_RAM: std_logic_vector(31 downto 0);
    signal counter: std_logic_vector(2 downto 0);

    signal Dadress, Ddata, Iadress, Idata,
           i_cpu_address, d_cpu_address, data_cpu, tb_add, tb_data : wires32 := (others => '0' );
    
    signal Dce_n, Dwe_n, Doe_n, Ice_n, Iwe_n, Ioe_n, ck, rst, rstCPU, hold,
           go_i, go_d, ce, rw, bw: std_logic;
    
    file ARQ : TEXT open READ_MODE is "../Dumps/overflow.txt";
 
begin

    Cache:     entity work.Cache_mem
               port map (rstCPU=>rstCPU, counter=>counter, ck=>ck, rst=>rst, ce_in=>Dce_n, we_in=>Dwe_n, oe_in=>Doe_n, bw_in=>bw, halt_in=>halt, address_in=>Dadress,
                         ce_out=>ce_out, we_out=>we_out, oe_out=>oe_out, bw_out=>bw_out, halt_out=>halt_out, 
                         address_out=>address_out, data_CPU=>Ddata, data_RAM=>data_RAM);
    
    Delay:     entity work.Delay
               port map (ck=>ck, rst=>rst, ce_n=>ce_out, halt=>halt, counter=>counter);         

    Data_mem:  entity work.RAM_mem 
               generic map( START_ADDRESS => x"10010000" )
               port map (ce_n=>ce_out, we_n=>we_out, oe_n=>oe_out, bw=>bw_out, address=>address_out, data=>data_RAM);
                                            
    Instr_mem: entity work.RAM_mem 
               generic map( START_ADDRESS => x"00400000" )
               port map (ce_n=>Ice_n, we_n=>Iwe_n, oe_n=>Ioe_n, bw=>'1', address=>Iadress, data=>Idata);
    
    hold <= '0';

    -- sinais para adaptar a mem�ria de dados ao processador ---------------------------------------------
    Dce_n <= '0' when (ce='1' and rstCPU/='1') or go_d='1' else '1'; -- Bug corrected here in 16/05/2012
    Doe_n <= '0' when (ce='1' and rw='1')             else '1';       
    Dwe_n <= '0' when (ce='1' and rw='0') or go_d='1' else '1';    

    Dadress <= tb_add  when rstCPU='1' else d_cpu_address;
    Ddata   <= tb_data when rstCPU='1' else data_cpu when (ce='1' and rw='0') else (others=>'Z'); 
    
    data_cpu <= Ddata when (ce='1' and rw='1') else (others=>'Z');
    
    -- sinais para adaptar a mem�ria de instru��es ao processador ---------------------------------------------
    Ice_n <= '0';                                 
    Ioe_n <= '1' when rstCPU='1' else '0';           -- impede leitura enquanto est� escrevendo                             
    Iwe_n <= '0' when go_i='1'   else '1';           -- escrita durante a leitura do arquivo 
    
    Iadress <= tb_add  when rstCPU='1' else i_cpu_address;
    Idata   <= tb_data when rstCPU='1' else (others => 'Z'); 
  
    cpu: entity work.MIPS_S  port map(
              clock=>ck, reset=>rstCPU,	hold=>hold, halt=>halt_out,
              i_address => i_cpu_address,
              instruction => Idata,
              ce=>ce,  rw=>rw,  bw=>bw,
              d_address => d_cpu_address,
              data => data_cpu
        ); 

    rst <='1', '0' after 15 ns;       -- gera o sinal de reset global 

    process                          -- gera o clock global 
        begin
        ck <= '1', '0' after 10 ns;
        wait for 20 ns;
    end process;

    
    ----------------------------------------------------------------------------
    -- Este processo carrega a mem�ria de instru��es e a mem�ria de dados
    -- durante o per�odo que o reset fica ativo
    --
    --
    --   O PROCESSO ABAIXO � UM PARSER PARA LER C�DIGO GERADO PELO MARS NO
    --   SEGUINTE FORMATO:
    --
    --      Text Segment
    --      0x00400000        0x3c011001  lui $1, 4097 [d2]               ; 16: la    $t0, d2
    --      0x00400004        0x34280004  ori $8, $1, 4 [d2]
    --      0x00400008        0x8d080000  lw $8, 0($8)                    ; 17: lw    $t0,0($t0)
    --      .....
    --      0x00400048        0x0810000f  j 0x0040003c [loop]             ; 30: j     loop
    --      0x0040004c        0x01284821  addu $9, $9, $8                 ; 32: addu $t1, $t1, $t0
    --      0x00400050        0x08100014  j 0x00400050 [x]                ; 34: j     x
    --      Data Segment
    --      0x10010000        0x0000faaa  0x00000083  0x00000000  0x00000000
    --
    ----------------------------------------------------------------------------
    process
        variable ARQ_LINE : LINE;
        variable line_arq : string(1 to TAM_LINHA);
        variable code     : boolean;
        variable i, address_flag : integer;
    begin  
        go_i <= '0';
        go_d <= '0';
        rstCPU <= '1';           -- segura o processador durante a leitura do arquivo
        code:=true;              -- valor default de code � true (leitura de instru��es)
                                 
        wait until rst = '1';
        
        while NOT (endfile(ARQ)) loop    -- INCIO DA LEITURA DO ARQUIVO CONTENDO INSTRU��ES E DADOS -----
            readFileLine(ARQ, line_arq);            
            if line_arq(1 to 12)="Text Segment" then 
                   code:=true;                     -- instru��es 
            elsif line_arq(1 to 12)="Data Segment" then
                   code:=false;                    -- dados
            else 
               i := 1;                  -- LEITURA DE LINHA - analisar o la�o abaixo para entender 
               address_flag := 0;       -- para INSTRU��ES  um par (end,inst)
                                        -- para DADOS aceita (end dado 0 dado 1 dado 2 ....)
               loop                                     
                  if line_arq(i) = '0' and line_arq(i+1) = 'x' then -- encontrou indica�� de n�mero hexa: '0x'
                         i := i + 2;
                         if address_flag=0 then
                               for w in 0 to 7 loop
                                   tb_add( (31-w*4) downto (32-(w+1)*4))  <= CONV_VECTOR(line_arq,i+w);
                               end loop;    
                               i := i + 8; 
                               address_flag := 1;
                         else
                               for w in 0 to 7 loop
                                   tb_data( (31-w*4) downto (32-(w+1)*4))  <= CONV_VECTOR(line_arq,i+w);
                               end loop;    
                               i := i + 8;
                               
                               wait for 0.1 ns;
                               
                               if code=true then go_i <= '1';    
                               -- O sinal go_i habilita escrita na mem�ria de instru��es
                                            else go_d <= '1';    
                               -- O sinal go_d habilita escrita na mem�ria de dados
                               end if; 
                               
                               wait for 0.1 ns;
                               
                               tb_add <= tb_add + 4; -- OK, consigo ler mais de um dado por linha!
                               go_i <= '0';
                               go_d <= '0'; 
                               
                               address_flag := 2;    -- sinaliza que j� leu o conte�do do endere�o;

                         end if;
                  end if;
                  i := i + 1;
                  
                  -- sai da linha quando chegou no seu final OU j� leu par (endereo, instru��o) 
                  --    no caso de instru��es
                  exit when i=TAM_LINHA or (code=true and address_flag=2);
               end loop;
            end if;
            
        end loop;       -- FINAL DA LEITURA DO ARQUIVO CONTENDO INSTRU��ES E DADOS -----
        
        rstCPU <= '0' after 2 ns;   -- libera o processador para executar o programa
        wait for 4 ns;              -- espera um pouco antes de come�ar a esperar pelo rst de novo
        wait until rst = '1';       -- Se isto acontecer come�a de novo!!
        
    end process;
    
end cpu_tb;
