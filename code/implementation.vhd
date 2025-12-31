library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
--shift_register rimasto dalle vecchie implementazioni del codice che ho voluto tenere (non obbligatorio si può fare senza)
--è quello classico che si trova anche sulle slide date in supporto
entity shift_register_7celle is
    port (
        in1    : in std_logic_vector(7 downto 0);
        clk, reset, en : in std_logic;
        out1, out2, out3, out4, out5, out6, out7 : out std_logic_vector(7 downto 0)
    );
end shift_register_7celle;

architecture Behavioral of shift_register_7celle is
    signal t1, t2, t3, t4, t5, t6, t7 : std_logic_vector(7 downto 0);
begin
    process(clk, reset)
    begin
        if reset = '1' then
            t1 <= (others => '0');
            t2 <= (others => '0');
            t3 <= (others => '0');
            t4 <= (others => '0');
            t5 <= (others => '0');
            t6 <= (others => '0');
            t7 <= (others => '0');
        elsif rising_edge(clk) then
            if en = '1' then
                t7 <= t6;
                t6 <= t5;
                t5 <= t4;
                t4 <= t3;
                t3 <= t2;
                t2 <= t1;
                t1 <= in1;
            end if;
        end if;
    end process;
    out1 <= t1; out2 <= t2; out3 <= t3; out4 <= t4;
    out5 <= t5; out6 <= t6; out7 <= t7;
end Behavioral;

---inizio implementazione del modulo---
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
--interfaccia della specifica 
entity project_reti_logiche is
    port (
        i_clk       : in std_logic;
        i_rst       : in std_logic;
        i_start     : in std_logic;
        i_add       : in std_logic_vector(15 downto 0);
        o_done      : out std_logic;
        o_mem_addr  : out std_logic_vector(15 downto 0);
        i_mem_data  : in std_logic_vector(7 downto 0);
        o_mem_data  : out std_logic_vector(7 downto 0);
        o_mem_we    : out std_logic;
        o_mem_en    : out std_logic
    );
end project_reti_logiche;

architecture Behavioral of project_reti_logiche is
-- dichiarazioni de shift-register
    component shift_register_7celle
        port (
            in1    : in std_logic_vector(7 downto 0);
            clk    : in std_logic;
            reset  : in std_logic;
            en     : in std_logic;
            out1, out2, out3, out4, out5, out6, out7 : out std_logic_vector(7 downto 0)
        );
    end component;
    
    -- sono presenti molti segnali di wait separati , questo per una questione di robustezza , sicuramente ne bastano meno
    type state_type is (
        RESET,
        IDLE,
        SETUP_REQUEST,
        SETUP_WAIT_DATA,
        SETUP,
        LOAD_REQUEST,
        LOAD_WAIT,
        LOAD,
        SHIFT_WAIT,
        START_FILTER,
        FILTER_WAIT,
        NORMALIZ,
        SATUR_WAIT,
        SATUR,
        WRITE_WAIT,
        WRITE_REQUEST,
        DONE
    );
    -- sengali per fsa
    signal current_state, next_state : state_type;
    signal cnt_setup : integer range 0 to 17 := 0;
    --segnali da specifica di supporto
    signal K1, K2, S : std_logic_vector(7 downto 0) := (others => '0');
    signal filter_type : std_logic := '0';
    signal c1, c2, c3, c4, c5, c6, c7, c8, c9, c10, c11, c12, c13, c14 : std_logic_vector(7 downto 0) := (others => '0');
    signal K : integer := 0;
    --segnali di fun funzionamento del filtro
    signal cnt_data : integer range 0 to 2147483647 := 0;
    signal mem_en : std_logic := '0';
    signal mem_we : std_logic := '0';
    signal reg_addr : std_logic_vector(15 downto 0) := (others => '0');
    signal reg_data_out : std_logic_vector(7 downto 0) := (others => '0');
    signal done_flag : std_logic := '0';
    signal shiftInput : std_logic_vector(7 downto 0) := (others => '0');
    signal shift_en   : std_logic := '0';
    signal w0, w1, w2, w3, w4, w5, w6 : std_logic_vector(7 downto 0);
    signal acc : integer := 0;
    signal norm : integer := 0;
    signal result_byte : std_logic_vector(7 downto 0) := (others => '0');

begin
--mappo i vari segnali
    o_mem_addr <= reg_addr;
    o_mem_data <= reg_data_out;
    o_mem_en   <= mem_en;
    o_mem_we   <= mem_we;
    o_done     <= done_flag;

    shift_register_inst : shift_register_7celle
    port map (
        in1   => shiftInput,
        clk   => i_clk,
        reset => i_rst,        
        en    => shift_en,
        out1  => w0,
        out2  => w1,
        out3  => w2,
        out4  => w3,
        out5  => w4,
        out6  => w5,
        out7  => w6
    );
    
    --process per macchina a stati
    process(current_state, i_start, cnt_setup, cnt_data, K, i_rst)
    begin
        if i_rst = '1' then
            next_state <= RESET;
        else
            case current_state is
            
                when RESET =>
                    next_state <= IDLE;

                when IDLE =>
                    if i_start = '1' then
                        next_state <= SETUP_REQUEST;
                    else
                        next_state <= IDLE;
                    end if;

                when SETUP_REQUEST =>
                    next_state <= SETUP_WAIT_DATA;

                when SETUP_WAIT_DATA =>
                    next_state <= SETUP;

                when SETUP =>
                    if cnt_setup = 17 then
                        next_state <= LOAD_REQUEST;
                    else
                        next_state <= SETUP_REQUEST;
                    end if;

                when LOAD_REQUEST =>
                    next_state <= LOAD_WAIT;

                when LOAD_WAIT =>
                    next_state <= LOAD;

                when LOAD =>
                    if cnt_data = K + 6 then
                        next_state <= DONE;
                    else
                        next_state <= SHIFT_WAIT;
                    end if;

                when SHIFT_WAIT =>
                    next_state <= START_FILTER;

                when START_FILTER =>
                    next_state <= FILTER_WAIT;

                when FILTER_WAIT =>
                    next_state <= NORMALIZ;

                when NORMALIZ =>
                    next_state <= SATUR_WAIT;
                    
                when SATUR_WAIT =>
                     next_state <= SATUR;
                     
                when SATUR =>
                    next_state <= WRITE_WAIT;
                    
                when WRITE_WAIT =>
                    next_state <= WRITE_REQUEST;

                when WRITE_REQUEST =>
                    next_state <= LOAD_REQUEST;

                when DONE =>
                    if i_start = '0' then
                        next_state <= IDLE;
                    else
                        next_state <= DONE;
                    end if;
            end case;
        end if;
    end process;
   
    -- process sincrono per il funzionamento del tutto (ho dei doppi che si potrebbero ottimizzare , ma li mantengo per robustezza)
    process(i_clk)
    --supporto per i calcoli
    variable temp_norm : integer;
    variable shifted   : integer;
    variable temp : integer;
    begin
        if rising_edge(i_clk) then
            if i_rst = '1' then
                current_state <= RESET;
                cnt_setup <= 0;
                cnt_data  <= 0;
                mem_en <= '0';
                mem_we <= '0';
                done_flag <= '0';
                reg_addr <= (others => '0');
                reg_data_out <= (others => '0');
                K1 <= (others => '0');
                K2 <= (others => '0');
                S  <= (others => '0');
                filter_type <= '0';
                c1 <= (others => '0'); c2 <= (others => '0'); c3 <= (others => '0');
                c4 <= (others => '0'); c5 <= (others => '0'); c6 <= (others => '0');
                c7 <= (others => '0'); c8 <= (others => '0'); c9 <= (others => '0');
                c10 <= (others => '0'); c11 <= (others => '0'); c12 <= (others => '0');
                c13 <= (others => '0'); c14 <= (others => '0');
                K <= 0;
                shift_en <= '0';
                shiftInput <= (others => '0');
                acc <= 0;
                norm <= 0;
                result_byte <= (others => '0');
            else
                current_state <= next_state;

                case current_state is
                    when RESET =>
                        cnt_setup <= 0;
                        cnt_data  <= 0;
                        mem_en <= '0';
                        mem_we <= '0';
                        done_flag <= '0';
                        shift_en <= '0';

                    when IDLE =>
                        mem_en <= '0';
                        mem_we <= '0';
                        done_flag <= '0';
                        cnt_setup <= 0;
                        cnt_data  <= 0;
                        shift_en <= '0';

                    when SETUP_REQUEST =>
                        mem_en <= '1';
                        mem_we <= '0';
                        reg_addr <= std_logic_vector(unsigned(i_add) + to_unsigned(cnt_setup, 16));
                        shift_en <= '0';

                    when SETUP_WAIT_DATA =>
                        shift_en <= '0';

                    when SETUP =>
                        case cnt_setup is
                            when 0  => K1 <= i_mem_data;
                            when 1  => K2 <= i_mem_data;
                            when 2  => S  <= i_mem_data;
                            when 3  => c1 <= i_mem_data;
                            when 4  => c2 <= i_mem_data;
                            when 5  => c3 <= i_mem_data;
                            when 6  => c4 <= i_mem_data;
                            when 7  => c5 <= i_mem_data;
                            when 8  => c6 <= i_mem_data;
                            when 9  => c7 <= i_mem_data;
                            when 10 => c8 <= i_mem_data;
                            when 11 => c9 <= i_mem_data;
                            when 12 => c10 <= i_mem_data;
                            when 13 => c11 <= i_mem_data;
                            when 14 => c12 <= i_mem_data;
                            when 15 => c13 <= i_mem_data;
                            when 16 => c14 <= i_mem_data;
                            when others => null;
                        end case;
                        cnt_setup <= cnt_setup + 1;
                        if cnt_setup = 2 then
                           
                            K <= to_integer(unsigned(K1 & K2));
                        end if;
                        if cnt_setup = 3 then
                              filter_type <= S(0); 
                        end if;
                        
                    when LOAD_REQUEST =>
                        mem_en <= '1';
                        mem_we <= '0';
                        reg_addr <= std_logic_vector(unsigned(i_add) + 17 + to_unsigned(cnt_data, 16));
                        shift_en <= '0';

                    when LOAD_WAIT =>
                        shift_en <= '0';
                        mem_en <= '1';
                        mem_we <= '0';

                    when LOAD =>
                         if cnt_data < K then
                         shiftInput <= i_mem_data;
                         else
                         shiftInput <= (others => '0'); 
                         end if;
                         shift_en <= '1';

                    when SHIFT_WAIT =>
                          shift_en <= '0';
                          acc <= 0;  
                          norm <= 0;

                    when START_FILTER =>
                        if filter_type = '0' then
                            acc <=  to_integer(signed(w6)) * 0 +
                                    to_integer(signed(w5)) * to_integer(signed(c2)) +
                                    to_integer(signed(w4)) * to_integer(signed(c3)) +
                                    to_integer(signed(w3)) * to_integer(signed(c4)) +
                                    to_integer(signed(w2)) * to_integer(signed(c5)) +
                                    to_integer(signed(w1)) * to_integer(signed(c6)) +
                                    to_integer(signed(w0)) * 0 ;
                        else
                            acc <=  to_integer(signed(w6)) * to_integer(signed(c8)) +
                                    to_integer(signed(w5)) * to_integer(signed(c9)) +
                                    to_integer(signed(w4)) * to_integer(signed(c10)) +
                                    to_integer(signed(w3)) * to_integer(signed(c11)) +
                                    to_integer(signed(w2)) * to_integer(signed(c12)) +
                                    to_integer(signed(w1)) * to_integer(signed(c13)) +
                                    to_integer(signed(w0)) * to_integer(signed(c14));
                        end if;

                    when FILTER_WAIT =>

                    when NORMALIZ =>
                         temp_norm := 0;

                         if filter_type = '0' then
                          shifted := to_integer(shift_right(to_signed(acc, 24), 4));
                          temp_norm := temp_norm + shifted;
                         
                          if shifted < 0 then temp_norm := temp_norm + 1; end if;
                          
                          shifted := to_integer(shift_right(to_signed(acc, 24), 6));
                          temp_norm := temp_norm + shifted;
                         
                          if shifted < 0 then temp_norm := temp_norm + 1; end if;
                          
                          shifted := to_integer(shift_right(to_signed(acc, 24), 8));
                          temp_norm := temp_norm + shifted;
                         
                          if shifted < 0 then temp_norm := temp_norm + 1; end if;

                         shifted := to_integer(shift_right(to_signed(acc, 24), 10));
                         temp_norm := temp_norm + shifted;
                         
                         if shifted < 0 then temp_norm := temp_norm + 1; end if;

                      else
                        shifted := to_integer(shift_right(to_signed(acc, 24), 6));
                        temp_norm := temp_norm + shifted;
                        
                        if shifted < 0 then temp_norm := temp_norm + 1; end if;

                        shifted := to_integer(shift_right(to_signed(acc, 24), 10));
                        temp_norm := temp_norm + shifted;
                        
                        if shifted < 0 then temp_norm := temp_norm + 1; end if;
                      
                      end if;
                      
                     norm <= temp_norm;

                   when SATUR_WAIT =>

                   when SATUR =>
                    if norm > 127 then
                       temp := 127;
                    elsif norm < -128 then
                       temp := -128;
                    else
                       temp := norm;
                    end if;
                   
                    result_byte <= std_logic_vector(to_signed(temp, 8));
     
                   when WRITE_WAIT =>
                         mem_en <= '0';
                         mem_we <= '0';  
                         reg_data_out <= result_byte;
                           
                   when WRITE_REQUEST =>
                      if cnt_data >= 3 and cnt_data < K + 3 then
                                mem_en <= '1';
                                mem_we <= '1';
                                reg_addr <= std_logic_vector(unsigned(i_add)+ to_unsigned(17 + K, 16)+ to_unsigned(cnt_data - 3, 16));
                                reg_data_out <= result_byte;
                            end if;
                          cnt_data <= cnt_data + 1;
                          
                    when DONE =>
                        done_flag <= '1';
                        shift_en <= '0';
                            if i_start = '0' then
                             cnt_setup <= 0;
                             cnt_data  <= 0;
                             acc         <= 0;
                             norm        <= 0;
                             result_byte <= (others => '0');
                             shiftInput  <= (others => '0');
                             K1 <= (others => '0');
                             K2 <= (others => '0');
                             S  <= (others => '0');
                             filter_type <= '0';
                             c1 <= (others => '0');
                             c2 <= (others => '0'); 
                             c3 <= (others => '0');
                             c4 <= (others => '0'); 
                             c5 <= (others => '0'); 
                             c6 <= (others => '0');
                             c7 <= (others => '0'); 
                             c8 <= (others => '0'); 
                             c9 <= (others => '0');
                             c10 <= (others => '0'); 
                             c11 <= (others => '0'); 
                             c12 <= (others => '0');
                             c13 <= (others => '0'); 
                             c14 <= (others => '0');
                             K <= 0;
                           end if;

                end case;
            end if;
        end if;
    end process;
    
end Behavioral;
