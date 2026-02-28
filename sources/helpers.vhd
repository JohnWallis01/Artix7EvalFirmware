----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 31.01.2026 11:43:51
-- Design Name: 
-- Module Name: helpers - Behavioral
-- Project Name: 
-- Target Devices: 
-- Tool Versions: 
-- Description: 
-- 
-- Dependencies: 
-- 
-- Revision:
-- Revision 0.01 - File Created
-- Additional Comments:
-- 
----------------------------------------------------------------------------------


library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
--use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx leaf cells in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity AXI_Stream_Transmitter is
    generic (
        DATA_WIDTH : integer := 32
    );
    Port (
            packet_size : in STD_LOGIC_VECTOR (DATA_WIDTH - 1 downto 0);
            enable : in STD_LOGIC;
            rst: in STD_LOGIC;
           data_in : in STD_LOGIC_VECTOR (DATA_WIDTH - 1 downto 0);
           m_axis_tdata : out STD_LOGIC_VECTOR (DATA_WIDTH - 1 downto 0);
           m_axis_aclk : in STD_LOGIC;
           m_axis_tlast : out STD_LOGIC;
           m_axis_tready : in STD_LOGIC;
           m_axis_tvalid : out STD_LOGIC);
end AXI_Stream_Transmitter;

architecture Behavioral of AXI_Stream_Transmitter is

        signal counter : integer := 0;
begin
    m_axis_tvalid <= '1' when enable = '1' else '0';
    m_axis_tdata <= data_in;
    process(m_axis_aclk, rst)
    begin
        if rst = '0' then
            counter <= 0;
            m_axis_tlast <= '0';
        elsif rising_edge(m_axis_aclk) then
            if enable = '1' then
                if m_axis_tready = '1' then
                    if counter = to_integer(unsigned(packet_size)) - 1 then
                        counter <= 0;
                        m_axis_tlast <= '1';
                    else
                        counter <= counter + 1;
                        m_axis_tlast <= '0';
                    end if;
                end if;
            end if;
        end if;
    end process;



end Behavioral;

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity AXI_Stream_Receiver is
    generic (
        DATA_WIDTH : integer := 32
    );
    Port (
           s_axis_tdata : in STD_LOGIC_VECTOR (DATA_WIDTH - 1 downto 0);
           s_axis_tvalid : in STD_LOGIC;
           s_axis_tready : out STD_LOGIC;
           data_out : out STD_LOGIC_VECTOR (DATA_WIDTH - 1 downto 0));
end AXI_Stream_Receiver;

architecture AXI_Stream_Reciver_Behavioral of AXI_Stream_Receiver is
begin
    s_axis_tready <= '1';
    data_out <= s_axis_tdata;

end AXI_Stream_Reciver_Behavioral;


library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity BUS_CONVERTER is
    generic (
        input_width : integer := 24;
        output_width : integer := 32;
        input_division_ratio : integer := 4;
        output_multiplication_ratio : integer := 3 
    );
    Port (
            data_in : in STD_LOGIC_VECTOR (input_width - 1 downto 0);
            data_out : out STD_LOGIC_VECTOR (output_width - 1 downto 0);
            clock_in : in STD_LOGIC;
            clock_out : in STD_LOGIC;
            sync_lock : out STD_LOGIC;
            rst : in STD_LOGIC;
            enable : in STD_LOGIC
            );
end BUS_CONVERTER;

architecture BUS_CONVERTER_Behavioral of BUS_CONVERTER is
    signal input_buffer : STD_LOGIC_VECTOR (input_division_ratio * input_width - 1 downto 0);
    signal output_buffer : STD_LOGIC_VECTOR (output_multiplication_ratio * output_width - 1 downto 0);
    signal lock_signal : STD_LOGIC := '0';
    signal input_counter : integer := 0;
    signal output_counter : integer := 0;

    begin
    process(clock_in, rst)
    begin
        if rst = '0' then
            input_buffer <= (others => '0');
            output_buffer <= (others => '0');
            input_counter <= 0;
            lock_signal <= '0';
        elsif rising_edge(clock_in) then
            ---begin filling the input buffer
            if enable = '1' then
                input_buffer <= input_buffer((input_division_ratio-1) * input_width - 1 downto 0) & data_in; -- shift the buffer and add new data
                input_counter <= input_counter + 1;
                if input_counter = input_division_ratio-1 then
                    lock_signal <= '1';
                    input_counter <= 0;
                    output_buffer <= input_buffer; -- transfer input buffer to output buffer
                end if;
            end if;
        end if;
    end process;

    process(clock_out, rst)
    begin
        if rst = '0' then
            output_counter <= 0;
        elsif rising_edge(clock_out) then
            if lock_signal = '1' then
                data_out <= output_buffer((output_multiplication_ratio - output_counter ) * output_width - 1 downto (output_multiplication_ratio - output_counter) * output_width - output_width); -- output the appropriate segment of the output buffer
                output_counter <= output_counter + 1;
                if output_counter = output_multiplication_ratio-1 then
                    output_counter <= 0;
                end if;
            end if;
        end if;
    end process;

    sync_lock <= lock_signal;
end BUS_CONVERTER_Behavioral;


library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity And_Gate is
    Port ( A : in STD_LOGIC;
           B : in STD_LOGIC;
           Y : out STD_LOGIC);
end And_Gate;

architecture Behavioral of And_Gate is
begin
    Y <= A and B;
end Behavioral;

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity DDR_Polarity_Corrector_B is
    Port(
        ADC_B_UNCORRECTED: in std_logic_vector(11 downto 0);
        ADC_B_CORRECTED: out std_logic_vector(11 downto 0)
    );
end DDR_Polarity_Corrector_B;

architecture Behavioral of DDR_Polarity_Corrector_B is
begin
    --Hard coded correction for schematic wiring to simplify routing

    --swapped pairs

    ADC_B_CORRECTED(0) <= ADC_B_UNCORRECTED(0);
    ADC_B_CORRECTED(1) <=  ADC_B_UNCORRECTED(6);

    ADC_B_CORRECTED(2) <= not ADC_B_UNCORRECTED(1);
    ADC_B_CORRECTED(3) <= not ADC_B_UNCORRECTED(7);

    ADC_B_CORRECTED(4) <= not ADC_B_UNCORRECTED(2);
    ADC_B_CORRECTED(5) <= not ADC_B_UNCORRECTED(8);

    ADC_B_CORRECTED(6) <= not ADC_B_UNCORRECTED(3);
    ADC_B_CORRECTED(7) <= not ADC_B_UNCORRECTED(9);

    ADC_B_CORRECTED(8) <= not ADC_B_UNCORRECTED(4);
    ADC_B_CORRECTED(9) <= not ADC_B_UNCORRECTED(10);

    ADC_B_CORRECTED(10) <= not ADC_B_UNCORRECTED(5);
    ADC_B_CORRECTED(11) <= not ADC_B_UNCORRECTED(11);

end Behavioral;

library ieee;
use ieee.std_logic_1164.all;

entity DDR_Polarity_Corrector_A is
    Port(
        ADC_A_UNCORRECTED: in std_logic_vector(11 downto 0);
        ADC_A_CORRECTED: out std_logic_vector(11 downto 0)
    );
end DDR_Polarity_Corrector_A;

architecture Behavioral of DDR_Polarity_Corrector_A is
begin
    --Hard coded correction for schematic wiring to simplify routing
    --swapped pairs
    --none
    ADC_A_CORRECTED(0) <= ADC_A_UNCORRECTED(0); --no correction needed for channel A only interleave the pins
    ADC_A_CORRECTED(1) <= ADC_A_UNCORRECTED(6);

    ADC_A_CORRECTED(2) <= ADC_A_UNCORRECTED(1);
    ADC_A_CORRECTED(3) <= ADC_A_UNCORRECTED(7);

    ADC_A_CORRECTED(4) <= ADC_A_UNCORRECTED(2);
    ADC_A_CORRECTED(5) <= ADC_A_UNCORRECTED(8);

    ADC_A_CORRECTED(6) <= ADC_A_UNCORRECTED(3);
    ADC_A_CORRECTED(7) <= ADC_A_UNCORRECTED(9);

    ADC_A_CORRECTED(8) <= ADC_A_UNCORRECTED(4);
    ADC_A_CORRECTED(9) <= ADC_A_UNCORRECTED(10);

    ADC_A_CORRECTED(10) <= ADC_A_UNCORRECTED(5);
    ADC_A_CORRECTED(11) <= ADC_A_UNCORRECTED(11);

end Behavioral;