library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity AXIS_RAMP_GENERATOR is
    generic (
        DATA_WIDTH : integer := 32
    );
    port (
        clk     : in  std_logic;
        rst     : in  std_logic;
        enable  : in  std_logic;
        packet_size: in std_logic_vector(DATA_WIDTH-1 downto 0);
        axis_tdata : out std_logic_vector(DATA_WIDTH-1 downto 0);
        axis_tvalid : out std_logic;
        axis_tready : in  std_logic;
        axis_tlast : out std_logic
    );
end AXIS_RAMP_GENERATOR;
architecture Behavioral of AXIS_RAMP_GENERATOR is
    signal data_counter : std_logic_vector(DATA_WIDTH-1 downto 0) := (others => '0');
    signal packet_counter : std_logic_vector(DATA_WIDTH-1 downto 0) := (others => '0');
begin
    process(clk, rst)
    begin
        if rst = '0' then
            data_counter <= (others => '0');
            packet_counter <= (others => '0');
            axis_tvalid <= '0';
            axis_tlast <= '0';
        elsif rising_edge(clk) then
            if enable = '1' then
                axis_tdata <= data_counter;
                axis_tvalid <= '1';
                if packet_counter = std_logic_vector(to_unsigned(to_integer(unsigned(PACKET_SIZE)) - 1, DATA_WIDTH)) then
                    axis_tlast <= '1';
                else
                    axis_tlast <= '0';
                end if;
                data_counter <= std_logic_vector(unsigned(data_counter) + 1);
                if axis_tready = '1' then
                    if packet_counter = std_logic_vector(to_unsigned(to_integer(unsigned(PACKET_SIZE)) - 1, DATA_WIDTH)) then
                        packet_counter <= (others => '0');
                    else
                        packet_counter <= std_logic_vector(unsigned(packet_counter) + 1);
                    end if;
                end if;
            elsif enable = '0' then
                axis_tvalid <= '0';
                end if;
        end if;
    end process;
    
    -- axis_data <= data_counter;

end Behavioral;

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use ieee.numeric_std.ALL;

entity simple_ramp_generator is
    generic (
        DATA_WIDTH : integer := 32
    );
    port (
        clk     : in  std_logic;
        rst     : in  std_logic;
        enable  : in  std_logic;
        data_out : out std_logic_vector(DATA_WIDTH-1 downto 0)
    );
end simple_ramp_generator;


architecture Behavioral of simple_ramp_generator is
    signal data_counter : std_logic_vector(DATA_WIDTH-1 downto 0) := (others => '0');
begin
    process(clk, rst)
    begin
        if rst = '0' then
            data_counter <= (others => '0');
        elsif rising_edge(clk) then
            if enable = '1' then
                data_counter <= std_logic_vector(unsigned(data_counter) + 1);
            end if;
        end if;
    end process;
    
    data_out <= data_counter;

end Behavioral;