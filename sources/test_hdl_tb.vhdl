library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity test_hdl_tb is
end test_hdl_tb;

architecture Behavioral of test_hdl_tb is
    constant DATA_WIDTH : integer := 32;
    constant PACKET_SIZE : integer := 64;

    signal clk     : std_logic := '0';
    signal rst     : std_logic := '0';
    signal enable  : std_logic := '0';
    signal axis_data : std_logic_vector(DATA_WIDTH-1 downto 0);
    signal axis_tvalid : std_logic;
    signal axis_tready : std_logic := '1'; -- Always ready to receive data
    signal axis_tlast : std_logic;

    component AXIS_RAMP_GENERATOR
        generic (
            DATA_WIDTH : integer := 32;
            PACKET_SIZE : integer := 64
        );
        port (
            clk     : in  std_logic;
            rst     : in  std_logic;
            enable  : in  std_logic;
            axis_data : out std_logic_vector(DATA_WIDTH-1 downto 0);
            axis_tvalid : out std_logic;
            axis_tready : in  std_logic;
            axis_tlast : out std_logic
        );
    end component;

begin
    uut: AXIS_RAMP_GENERATOR
        generic map (
            DATA_WIDTH => DATA_WIDTH,
            PACKET_SIZE => PACKET_SIZE
        )
        port map (
            clk => clk,
            rst => rst,
            enable => enable,
            axis_data => axis_data,
            axis_tvalid => axis_tvalid,
            axis_tready => axis_tready,
            axis_tlast => axis_tlast
        );

    -- Clock generation
    clk_process : process
    begin
        while true loop
            clk <= '0';
            wait for 10 ns;
            clk <= '1';
            wait for 10 ns;
        end loop;
    end process;

    -- Stimulus process
    stimulus_process : process
    begin
        -- Reset the system
        rst <= '1';
        wait for 20 ns;
        rst <= '0';
        wait for 20 ns;

        -- Enable the generator
        enable <= '1';
        -- wait for 2000 ns; -- Run the generator for a while

        -- Disable the generator
        -- enable <= '0';
        -- wait for 100 ns;

        -- End of simulation
        wait;
    end process;

end Behavioral;

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
use ieee.math_real.ALL;

entity bus_converter_tb is
end bus_converter_tb;


architecture Behavioral of bus_converter_tb is
    constant input_width : integer := 24;
    constant output_width : integer := 32;
    constant input_division_ratio : integer := 4;
    constant output_multiplication_ratio : integer := 3;

    signal data_in : std_logic_vector(input_width - 1 downto 0) := (others => '0');
    signal clock_in : std_logic := '0';
    signal clock_out : std_logic := '0';
    signal sync_lock : std_logic;
    signal rst : std_logic := '0';

    signal interposing_data : std_logic_vector(output_width - 1 downto 0);
    signal m_axis_tdata : std_logic_vector(output_width - 1 downto 0);
    signal m_axis_tlast : std_logic;
    signal axis_enable : std_logic := '1';
    signal m_axis_tvalid : std_logic;
    component BUS_CONVERTER
        generic (
            input_width : integer := 24;
            output_width : integer := 32;
            input_division_ratio : integer := 4;
            output_multiplication_ratio : integer := 3 
        );
        port (
            data_in : in std_logic_vector(input_width - 1 downto 0);
            data_out : out std_logic_vector(output_width - 1 downto 0);
            clock_in : in std_logic;
            clock_out : in std_logic;
            sync_lock : out std_logic;
            rst : in std_logic
        );
    end component;

    component AXI_Stream_Transmitter
        generic (
            DATA_WIDTH : integer := 32
        );
        port (
            packet_size : in std_logic_vector(DATA_WIDTH - 1 downto 0);
            enable : in std_logic;
            rst: in std_logic;
            data_in : in std_logic_vector(DATA_WIDTH - 1 downto 0);
            m_axis_tdata : out std_logic_vector(DATA_WIDTH - 1 downto 0);
            m_axis_tclock : in std_logic;
            m_axis_tlast : out std_logic;
            m_axis_tready : in std_logic;
            m_axis_tvalid : out std_logic
        );
    end component;

    component simple_ramp_generator
        generic (
            DATA_WIDTH : integer := 32
        );
        port (
        clk     : in  std_logic;
        rst     : in  std_logic;
        enable  : in  std_logic;
        data_out : out std_logic_vector(DATA_WIDTH-1 downto 0)
        );
    end component;

begin

    input_stimulus: simple_ramp_generator
        generic map (
            DATA_WIDTH => input_width
        )
        port map (
            clk => clock_in,
            rst => rst,
            enable => axis_enable,
            data_out => data_in
        );

    input_device: BUS_CONVERTER

        generic map (
            input_width => input_width,
            output_width => output_width,
            input_division_ratio => input_division_ratio,
            output_multiplication_ratio => output_multiplication_ratio
        )
        port map (
            data_in => data_in,
            data_out => interposing_data,
            clock_in => clock_in,
            clock_out => clock_out,
            sync_lock => sync_lock,
            rst => rst
        );

     axis_transmitter: AXI_Stream_Transmitter
        generic map (
            DATA_WIDTH => output_width
        )
        port map (
            packet_size => std_logic_vector(to_unsigned(64, output_width)),
            enable => axis_enable,
            rst => rst,
            data_in => interposing_data,
            m_axis_tdata => m_axis_tdata,
            m_axis_tclock => clock_out,
            m_axis_tlast => m_axis_tlast,
            m_axis_tready => '1',
            m_axis_tvalid => m_axis_tvalid
        );

    -- Clock generation for input and output
    clock_in_process : process
    begin

        ---generate 64 MHz clock for input
        while true loop
            clock_in <= '0';
            wait for 7.8125 ns; -- 1/64 MHz = 15.625 ns period, so half period is 7.8125 ns
            clock_in <= '1';
            wait for 7.8125 ns;
        end loop;
    end process;

    clock_out_process : process
    begin
        ---generate 48 MHz clock for output
        while true loop
            clock_out <= '0';
            wait for 10.4167 ns; -- 1/48 MHz = 20.8333 ns period, so half period is 10.4167 ns
            clock_out <= '1';
            wait for 10.4167 ns;
        end loop;
    end process;

    -- Stimulus process
    stimulus_process : process
    begin
        -- Reset the system
        rst <= '0';
        wait for 20 ns;
        rst <= '1';
        -- wait for 20 ns;
    end process;

end Behavioral;
