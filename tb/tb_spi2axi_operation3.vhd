-------------------------------------------------------------------------------
--
--  SPI to AXI4-Lite Bridge, test controller entity declaration 
--
--  Description:  
--    Normal operation3 testcase
--
--  Author(s):
--    Guy Eschemann, guy@airhdl.com
--
-------------------------------------------------------------------------------
--
-- Copyright (c) 2022 Guy Eschemann
-- 
-- Licensed under the Apache License, Version 2.0 (the "License");
-- you may not use this file except in compliance with the License.
-- You may obtain a copy of the License at
-- 
--     http://www.apache.org/licenses/LICENSE-2.0
-- 
-- Unless required by applicable law or agreed to in writing, software
-- distributed under the License is distributed on an "AS IS" BASIS,
-- WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
-- See the License for the specific language governing permissions and
-- limitations under the License.
--
-------------------------------------------------------------------------------

architecture operation3 of tb_spi2axi_testctrl is

    -------------------------------------------------------------------------------
    -- Constants
    -------------------------------------------------------------------------------

    constant SPI_PACKET_LENGTH_BYTES : natural := 11;

    -------------------------------------------------------------------------------
    -- Aliases
    -------------------------------------------------------------------------------

    alias TxBurstFifo : ScoreboardIdType is SpiRec.BurstFifo;
    alias RxBurstFifo : ScoreboardIdType is SpiRec.BurstFifo;

begin

    ------------------------------------------------------------
    -- ControlProc
    --   Set up AlertLog and wait for end of test
    ------------------------------------------------------------
    ControlProc : process

        -- Write an AXI4 register over SPI
        procedure spi_write(addr : std_logic_vector(31 downto 0); data : std_logic_vector(31 downto 0); status : out std_logic_vector(7 downto 0)) is
            variable rx_bytes    : slv_vector(0 to SPI_PACKET_LENGTH_BYTES - 1)(7 downto 0);
            variable num_bytes   : integer;
        begin
            Log("SPI Write: addr = 0x" & to_hxstring(addr) & ", data = 0x" & to_hxstring(data), DEBUG);
            SendBurstVector(SpiRec, (X"00", Addr(31 downto 24), Addr(23 downto 16), Addr(15 downto 8), Addr(7 downto 0),
                              Data(31 downto 24), Data(23 downto 16), Data(15 downto 8), Data(7 downto 0), X"00", X"00") ) ; 
            GetBurst(SpiRec, num_bytes) ; 
            AlertIfNotEqual(num_bytes, SPI_PACKET_LENGTH_BYTES, "bytes received");
            PopBurstVector(RxBurstFifo, rx_bytes) ; 
            status := rx_bytes(10);
        end procedure;

        -- Read an AXI4 register over SPI
        procedure spi_read(addr : std_logic_vector(31 downto 0); data : out std_logic_vector(31 downto 0); status : out std_logic_vector(7 downto 0)) is
            variable rx_bytes    : slv_vector(0 to SPI_PACKET_LENGTH_BYTES - 1)(7 downto 0);
            variable num_bytes   : integer;
        begin
            Log("SPI Write: addr = 0x" & to_hxstring(addr) & ", data = 0x" & to_hxstring(data), DEBUG);
            SendBurstVector(SpiRec, (X"01", Addr(31 downto 24), Addr(23 downto 16), Addr(15 downto 8), Addr(7 downto 0),
                              X"00", X"00", X"00", X"00", X"00", X"00") ) ; 
            GetBurst(SpiRec, num_bytes) ; 
            AlertIfNotEqual(num_bytes, SPI_PACKET_LENGTH_BYTES, "bytes received");
            PopBurstVector(RxBurstFifo, rx_bytes) ; 
            data(31 downto 24) := rx_bytes(6) ;
            data(23 downto 16) := rx_bytes(7) ;
            data(15 downto 8)  := rx_bytes(8) ;
            data(7 downto 0)   := rx_bytes(9) ;
            status             := rx_bytes(10) ;
        end procedure;

        variable addr    : std_logic_vector(31 downto 0);
        variable wdata   : std_logic_vector(31 downto 0);
        variable rdata   : std_logic_vector(31 downto 0);
        variable mem_reg : std_logic_vector(31 downto 0);
        variable status  : std_logic_vector(7 downto 0);


    begin
        -- Initialization of test
        SetAlertLogName("tb_spi2axi_operation3");
        SetLogEnable(INFO, TRUE);
        SetLogEnable(DEBUG, FALSE);
        SetLogEnable(PASSED, FALSE);
        -- SetLogEnable(FindAlertLogID("Axi4LiteMemory"), INFO, FALSE, TRUE);

        -- Wait for testbench initialization 
        wait for 0 ns;

        -- Wait for Design Reset
        wait until nReset = '1';
        ClearAlerts;

        SetCPHA(SpiRec, SPI_CPHA);
        SetCPOL(SpiRec, SPI_CPOL);

        -- This was added to delay write address and write data ready
        SetAxi4Options(Axi4MemRec, WRITE_ADDRESS_READY_DELAY_CYCLES, 7) ;
        SetAxi4Options(Axi4MemRec, WRITE_ADDRESS_READY_BEFORE_VALID, FALSE) ;
        SetAxi4Options(Axi4MemRec, WRITE_DATA_READY_DELAY_CYCLES, 7) ;
        SetAxi4Options(Axi4MemRec, WRITE_DATA_READY_BEFORE_VALID, FALSE) ;

        wait for 1 us;

        Log("Testing normal SPI write");
        addr  := x"76543210";
        wdata := x"12345678";
        spi_write(addr, wdata, status);
        AffirmIfEqual(status(2), '0', "timeout");
        AffirmIfEqual(status(1 downto 0), "00", "write response");

        Read(Axi4MemRec, std_logic_vector(addr), mem_reg);
        AffirmIfEqual(mem_reg, wdata, "memory data word");

        Log("Testing SPI write with SLVERR response");
        addr  := x"76543210";
        wdata := x"12345678";
        SetAxi4Options(Axi4MemRec, BRESP, 2); -- SLVERR
        spi_write(addr, wdata, status);
        AffirmIfEqual(status(2), '0', "Timeout");
        AffirmIfEqual(status(1 downto 0), "10", "Write response");
        SetAxi4Options(Axi4MemRec, BRESP, 0);

        Log("Testing SPI write timeout");
--        s_axi_awvalid_mask <= force '0';
        addr               := x"76543210";
        wdata              := x"12345678";
        spi_write(addr, wdata, status);
        AffirmIfEqual('1', status(2), "timeout");
--        s_axi_awvalid_mask <= release;

        Log("Testing normal SPI read");
        addr  := x"12345678";
        wdata := x"12345678";
        Write(Axi4MemRec, std_logic_vector(addr), wdata);
        spi_read(addr, rdata, status);
        AffirmIfEqual(rdata, wdata, "read data");
        AffirmIfEqual('0', status(2), "timeout");
        AffirmIfEqual("00", status(1 downto 0), "read response");

        Log("Testing SPI read with DECERR response");
        addr  := x"12345678";
        wdata := x"12345678";
        SetAxi4Options(Axi4MemRec, RRESP, 3); -- DECERR
        spi_read(addr, rdata, status);
        AffirmIfEqual(rdata, wdata, "read data");
        AffirmIfEqual('0', status(2), "timeout");
        AffirmIfEqual("11", status(1 downto 0), "read response");
        SetAxi4Options(Axi4MemRec, RRESP, 0);

        Log("Testing SPI read timeout");
--        s_axi_arvalid_mask <= force '0';
        spi_read(addr, rdata, status);
        AffirmIfEqual('1', status(2), "timeout");
--        s_axi_arvalid_mask <= release;

        wait for 1 us;

        EndOfTestReports;
        std.env.stop;
        wait;
    end process ControlProc;

end architecture operation3;

configuration tb_spi2axi_operation3 of tb_spi2axi is
    for TestHarness
        for testctrl_inst : tb_spi2axi_testctrl
            use entity work.tb_spi2axi_testctrl(operation3);
        end for;
    end for;
end tb_spi2axi_operation3;
